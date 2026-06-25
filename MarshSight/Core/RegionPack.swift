import Foundation
import CoreLocation

/// A Codable snapshot of every live layer for a region, persisted to disk so the
/// app keeps working with no signal (the norm in a flooded-timber duck hole or a
/// backcountry hunt). CLLocationCoordinate2D is not Codable, so geometry is
/// stored as flat [lat, lon] pairs and rehydrated on load.
struct RegionPack: Codable {
    var id: String = UUID().uuidString
    var name: String = ""
    var savedAt: Date
    var centerLat: Double
    var centerLon: Double
    var gauges: [WaterGauge]
    var riverLines: [[GeoPoint]]
    var lakes: [[GeoPoint]]
    var lands: [CodableLand]
    var parcels: [CodableParcel] = []

    struct GeoPoint: Codable {
        var lat: Double
        var lon: Double
        var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }
        init(_ c: CLLocationCoordinate2D) { lat = c.latitude; lon = c.longitude }
    }

    struct CodableLand: Codable {
        var id: Int
        var name: String
        var managerCode: String
        var access: String
        var rings: [[GeoPoint]]
    }

    struct CodableParcel: Codable {
        var id: String
        var owner: String?
        var rings: [[GeoPoint]]
    }

    // MARK: - Conversions

    static func encode(lines: [[CLLocationCoordinate2D]]) -> [[GeoPoint]] {
        lines.map { $0.map(GeoPoint.init) }
    }

    static func decode(lines: [[GeoPoint]]) -> [[CLLocationCoordinate2D]] {
        lines.map { $0.map(\.coordinate) }
    }

    static func encode(lands: [PublicLand]) -> [CodableLand] {
        lands.map { land in
            CodableLand(id: land.id, name: land.name, managerCode: land.managerCode,
                        access: land.access.rawValue,
                        rings: land.rings.map { $0.map(GeoPoint.init) })
        }
    }

    static func decode(lands: [CodableLand]) -> [PublicLand] {
        lands.map { c in
            PublicLand(id: c.id, name: c.name, managerCode: c.managerCode,
                       access: PublicAccess(code: c.access),
                       rings: c.rings.map { $0.map(\.coordinate) })
        }
    }

    static func encode(parcels: [Parcel]) -> [CodableParcel] {
        parcels.map { p in
            CodableParcel(id: p.id, owner: p.owner, rings: p.rings.map { $0.map(GeoPoint.init) })
        }
    }

    static func decode(parcels: [CodableParcel]) -> [Parcel] {
        parcels.map { c in
            Parcel(id: c.id, owner: c.owner, rings: c.rings.map { $0.map(\.coordinate) })
        }
    }
}
