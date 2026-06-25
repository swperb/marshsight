import Foundation
import CoreLocation
import MapLibre
import Combine

/// One downloaded offline map: a region's basemap tiles cached on the device.
struct OfflineMap: Identifiable {
    var id: String              // "regionName|basemap"
    var regionName: String
    var basemap: Basemap
    var megabytes: Double
    var isComplete: Bool
    var progress: Double
    fileprivate var pack: MLNOfflinePack
}

/// Manages offline basemap downloads via MapLibre's native offline storage.
///
/// Model: a Region is an area whose data (land, water, parcels) you saved. An
/// offline map is that region's basemap TILES saved so the map renders with no
/// signal. Re-downloading refreshes the tiles (the basemap updates over time).
/// Each (region, basemap) pair is one offline map; deleting it frees the space.
@MainActor
final class OfflineManager: ObservableObject {

    @Published private(set) var maps: [OfflineMap] = []
    @Published private(set) var downloadingID: String?

    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(progressChanged(_:)),
            name: NSNotification.Name.MLNOfflinePackProgressChanged, object: nil)
        reload()
    }

    /// Total size of all offline maps, in MB.
    var totalMegabytes: Double { maps.reduce(0) { $0 + $1.megabytes } }

    func reload() {
        maps = (MLNOfflineStorage.shared.packs ?? []).compactMap(info)
    }

    /// Is there a completed offline map for this region (any basemap)?
    func offlineMap(forRegion name: String, basemap: Basemap) -> OfflineMap? {
        maps.first { $0.regionName == name && $0.basemap == basemap }
    }

    func download(regionName: String, center: CLLocationCoordinate2D,
                  basemap: Basemap, radiusKm: Double = 18) {
        let id = "\(regionName)|\(basemap.rawValue)"
        downloadingID = id

        // If a pack already exists for this region+basemap, just resume it.
        if let existing = maps.first(where: { $0.id == id }) {
            existing.pack.resume()
            return
        }

        let styleURL = RegionStyle.basemapStyleURL(basemap)
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let bounds = MLNCoordinateBounds(
            sw: CLLocationCoordinate2D(latitude: center.latitude - dLat, longitude: center.longitude - dLon),
            ne: CLLocationCoordinate2D(latitude: center.latitude + dLat, longitude: center.longitude + dLon))
        let region = MLNTilePyramidOfflineRegion(
            styleURL: styleURL, bounds: bounds, fromZoomLevel: 8, toZoomLevel: 14)
        let context = id.data(using: .utf8) ?? Data()

        MLNOfflineStorage.shared.addPack(for: region, withContext: context) { pack, _ in
            pack?.resume()
        }
    }

    func delete(_ map: OfflineMap) {
        MLNOfflineStorage.shared.removePack(map.pack) { [weak self] _ in
            self?.reload()
        }
    }

    // MARK: - Internals

    private func info(_ pack: MLNOfflinePack) -> OfflineMap? {
        guard let id = String(data: pack.context, encoding: .utf8) else { return nil }
        let parts = id.split(separator: "|", maxSplits: 1).map(String.init)
        let name = parts.first ?? "Region"
        let basemap = Basemap(rawValue: parts.count > 1 ? parts[1] : "hybrid") ?? .hybrid
        let p = pack.progress
        let expected = max(1, p.countOfResourcesExpected)
        return OfflineMap(
            id: id, regionName: name, basemap: basemap,
            megabytes: Double(p.countOfBytesCompleted) / 1_000_000,
            isComplete: pack.state == .complete,
            progress: Double(p.countOfResourcesCompleted) / Double(expected),
            pack: pack)
    }

    @objc private func progressChanged(_ note: Notification) {
        guard let pack = note.object as? MLNOfflinePack else { return }
        if pack.state == .complete, let id = String(data: pack.context, encoding: .utf8), id == downloadingID {
            downloadingID = nil
        }
        reload()
    }
}
