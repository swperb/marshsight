import Foundation
import CoreLocation
import Combine

/// A downloaded, simplified, offline-ready region (e.g. "Lay Lake"). All layers
/// are loaded once and rendered from memory. There is no per-fix fetching.
struct LoadedRegion: Equatable {
    let id: String
    let name: String
    let savedAt: Date
    let center: CLLocationCoordinate2D
    let gauges: [WaterGauge]
    let riverLines: [[CLLocationCoordinate2D]]
    let lakes: [[CLLocationCoordinate2D]]
    let publicLands: [PublicLand]
    let parcels: [Parcel]
    let trails: [[CLLocationCoordinate2D]]
    let huntingUnits: [HuntingUnit]

    var gaugeMarkers: [MarkerFeature] { gauges.map { $0.asMarkerFeature() } }

    /// The regulatory hunting unit the user is standing in, if any.
    func currentUnit(at c: CLLocationCoordinate2D) -> HuntingUnit? {
        huntingUnits.first { $0.contains(c) }
    }

    /// The private parcel the user is standing on, if any (owner lookup).
    func currentParcel(at c: CLLocationCoordinate2D) -> Parcel? {
        parcels.first { $0.contains(c) }
    }

    // Cheap identity-based equality so SwiftUI can skip re-rendering the map and
    // AR when only the live GPS fix changed.
    static func == (lhs: LoadedRegion, rhs: LoadedRegion) -> Bool {
        lhs.id == rhs.id && lhs.savedAt == rhs.savedAt
    }

    func nearestGauge(to c: CLLocationCoordinate2D) -> WaterGauge? {
        gauges.min { GeoMath.distance($0.coordinate, c) < GeoMath.distance($1.coordinate, c) }
    }
    func currentLand(at c: CLLocationCoordinate2D) -> PublicLand? {
        publicLands.first { $0.contains(c) }
    }
}

struct RegionSummary: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var centerLat: Double
    var centerLon: Double
    var savedAt: Date
}

/// Manages downloadable, offline regions: download one for a place, persist it,
/// switch between saved regions. Replaces the old "fetch everything around live
/// GPS continuously" model that caused the lag.
@MainActor
final class RegionStore: ObservableObject {

    @Published private(set) var active: LoadedRegion?
    @Published private(set) var saved: [RegionSummary] = []
    @Published private(set) var isWorking = false
    @Published private(set) var status: String?

    // Simplification tolerances (meters).
    private let lakeTol = 8.0, riverTol = 6.0, landTol = 10.0, parcelTol = 4.0

    private let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private var indexURL: URL { dir.appendingPathComponent("regions_index.json") }
    private func packURL(_ id: String) -> URL { dir.appendingPathComponent("region_\(id).json") }

    init() {
        loadIndex()
        if let lastID = UserDefaults.standard.string(forKey: "activeRegionID") {
            activate(lastID)
        }
    }

    /// Download every layer for a bounded region, simplify, persist, activate.
    /// An empty `name` is resolved to the nearby place name (e.g. "Pelham").
    func download(name: String, center: CLLocationCoordinate2D, radiusKm: Double = 20) async {
        isWorking = true
        defer { isWorking = false }

        let placemark = await reversePlacemark(center)
        let resolvedName = name.isEmpty
            ? (placemark?.locality ?? placemark?.subAdministrativeArea ?? placemark?.administrativeArea ?? "My Area")
            : name
        status = "Downloading \(resolvedName)..."

        async let g = try? await USGSWaterService.nearbyGauges(center: center, radiusKm: max(radiusKm, 40))
        async let r = try? await NHDService.riverLines(center: center, radiusKm: radiusKm, maxLines: 4000)
        async let l = try? await NHDService.lakes(center: center, radiusKm: radiusKm, maxLakes: 1500)
        async let p = try? await PADUSService.publicLands(center: center, radiusKm: radiusKm, maxUnits: 80)
        async let t = try? await TrailsService.trails(center: center, radiusKm: radiusKm)

        let gauges = await g ?? []
        let rivers = await r ?? []
        let lakes = await l ?? []
        let lands = await p ?? []
        let trails = await t ?? []

        // Per-state layers: parcels and regulatory hunting units, fetched from
        // whichever state we are in (if it publishes free data).
        let stateCode = StateParcelService.stateCode(from: placemark?.administrativeArea)

        var parcels: [Parcel] = []
        if let stateCode, StateParcelService.hasCoverage(stateCode: stateCode) {
            status = "Downloading parcels..."
            parcels = (try? await StateParcelService.parcels(stateCode: stateCode, center: center)) ?? []
        }

        var huntingUnits: [HuntingUnit] = []
        if let stateCode, HuntingUnitsService.hasCoverage(stateCode: stateCode) {
            status = "Downloading hunting units..."
            huntingUnits = (try? await HuntingUnitsService.units(stateCode: stateCode, center: center,
                                                                 radiusKm: max(radiusKm, 40))) ?? []
        }

        status = "Optimizing map..."
        let refLat = center.latitude
        let simpRivers = GeometrySimplify.simplify(lines: rivers, toleranceMeters: riverTol, refLat: refLat)
        let simpLakes = GeometrySimplify.simplify(lines: lakes, toleranceMeters: lakeTol, refLat: refLat)
        let simpTrails = GeometrySimplify.simplify(lines: trails, toleranceMeters: riverTol, refLat: refLat)
        let simpLands = lands.map { GeometrySimplify.simplify(land: $0, toleranceMeters: landTol, refLat: refLat) }
        let simpParcels = parcels.map { p in
            Parcel(id: p.id, owner: p.owner,
                   rings: p.rings.map { GeometrySimplify.simplify($0, toleranceMeters: parcelTol, refLat: refLat) })
        }
        let simpUnits = huntingUnits.map { u in
            HuntingUnit(id: u.id, name: u.name,
                        rings: u.rings.map { GeometrySimplify.simplify($0, toleranceMeters: landTol, refLat: refLat) })
        }

        let pack = RegionPack(
            id: UUID().uuidString, name: resolvedName, savedAt: Date(),
            centerLat: center.latitude, centerLon: center.longitude,
            gauges: gauges,
            riverLines: RegionPack.encode(lines: simpRivers),
            lakes: RegionPack.encode(lines: simpLakes),
            lands: RegionPack.encode(lands: simpLands),
            parcels: RegionPack.encode(parcels: simpParcels),
            trails: RegionPack.encode(lines: simpTrails),
            huntingUnits: RegionPack.encode(units: simpUnits)
        )

        persist(pack)
        active = loaded(from: pack)
        UserDefaults.standard.set(pack.id, forKey: "activeRegionID")
        status = nil
    }

    func activate(_ id: String) {
        guard let data = try? Data(contentsOf: packURL(id)),
              let pack = try? JSONDecoder().decode(RegionPack.self, from: data) else { return }
        active = loaded(from: pack)
        UserDefaults.standard.set(id, forKey: "activeRegionID")
    }

    func delete(_ id: String) {
        try? FileManager.default.removeItem(at: packURL(id))
        saved.removeAll { $0.id == id }
        writeIndex()
        if active?.id == id { active = nil }
    }

    func nearestGauge(to c: CLLocationCoordinate2D) -> WaterGauge? { active?.nearestGauge(to: c) }
    func currentLand(at c: CLLocationCoordinate2D) -> PublicLand? { active?.currentLand(at: c) }

    // MARK: - Persistence

    private func loaded(from pack: RegionPack) -> LoadedRegion {
        LoadedRegion(
            id: pack.id, name: pack.name, savedAt: pack.savedAt,
            center: CLLocationCoordinate2D(latitude: pack.centerLat, longitude: pack.centerLon),
            gauges: pack.gauges,
            riverLines: RegionPack.decode(lines: pack.riverLines),
            lakes: RegionPack.decode(lines: pack.lakes),
            publicLands: RegionPack.decode(lands: pack.lands),
            parcels: RegionPack.decode(parcels: pack.parcels),
            trails: RegionPack.decode(lines: pack.trails),
            huntingUnits: RegionPack.decode(units: pack.huntingUnits)
        )
    }

    /// Reverse geocode a coordinate to a placemark (for naming + state lookup).
    private func reversePlacemark(_ c: CLLocationCoordinate2D) async -> CLPlacemark? {
        let loc = CLLocation(latitude: c.latitude, longitude: c.longitude)
        return try? await CLGeocoder().reverseGeocodeLocation(loc).first
    }

    private func persist(_ pack: RegionPack) {
        if let data = try? JSONEncoder().encode(pack) {
            try? data.write(to: packURL(pack.id), options: .atomic)
        }
        saved.removeAll { $0.id == pack.id }
        saved.insert(RegionSummary(id: pack.id, name: pack.name,
                                   centerLat: pack.centerLat, centerLon: pack.centerLon,
                                   savedAt: pack.savedAt), at: 0)
        writeIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let list = try? JSONDecoder().decode([RegionSummary].self, from: data) else { return }
        saved = list.sorted { $0.savedAt > $1.savedAt }
    }

    private func writeIndex() {
        if let data = try? JSONEncoder().encode(saved) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
