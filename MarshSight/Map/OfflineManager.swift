import Foundation
import CoreLocation
import MapLibre
import Combine

/// Downloads the basemap tiles for a region so the map works with no signal,
/// using MapLibre's native offline storage. The vector layers are already on
/// device in the region pack; this fills in the imagery/topo tiles, which is
/// what makes the map fully usable in a no-bars duck hole or backcountry hunt.
@MainActor
final class OfflineManager: ObservableObject {

    @Published private(set) var isDownloading = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var status: String?

    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(progressChanged(_:)),
            name: NSNotification.Name.MLNOfflinePackProgressChanged, object: nil)
    }

    func download(region: LoadedRegion, basemap: Basemap, radiusKm: Double = 18) {
        guard !isDownloading else { return }
        let styleURL = RegionStyle.fileURL(region: region, contributions: [], basemap: basemap)
        let m = GeoMath.metersPerDegree(atLatitude: region.center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let sw = CLLocationCoordinate2D(latitude: region.center.latitude - dLat,
                                        longitude: region.center.longitude - dLon)
        let ne = CLLocationCoordinate2D(latitude: region.center.latitude + dLat,
                                        longitude: region.center.longitude + dLon)
        let bounds = MLNCoordinateBounds(sw: sw, ne: ne)
        let mlnRegion = MLNTilePyramidOfflineRegion(
            styleURL: styleURL, bounds: bounds, fromZoomLevel: 8, toZoomLevel: 14)

        let context = "\(region.name)|\(basemap.rawValue)".data(using: .utf8) ?? Data()
        isDownloading = true
        progress = 0
        status = "Downloading map tiles..."

        MLNOfflineStorage.shared.addPack(for: mlnRegion, withContext: context) { pack, _ in
            pack?.resume()
        }
    }

    @objc private func progressChanged(_ note: Notification) {
        guard let pack = note.object as? MLNOfflinePack else { return }
        let p = pack.progress
        let expected = max(1, p.countOfResourcesExpected)
        progress = Double(p.countOfResourcesCompleted) / Double(expected)

        switch pack.state {
        case .complete:
            isDownloading = false
            status = "Saved for offline use"
        case .inactive:
            isDownloading = false
            status = nil
        default:
            isDownloading = true
        }
    }
}
