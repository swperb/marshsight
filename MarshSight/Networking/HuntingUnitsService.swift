import Foundation
import CoreLocation

/// A regulatory hunting unit (a game-management zone), e.g. "Deer Zone 12".
/// These are the boundaries that govern seasons and bag limits, distinct from
/// the public-land tracts in PAD-US. Drawn as outlines so a hunter can see
/// which unit they are standing in.
struct HuntingUnit: Identifiable {
    let id: Int
    let name: String
    let rings: [[CLLocationCoordinate2D]]

    func contains(_ c: CLLocationCoordinate2D) -> Bool {
        rings.contains { GeoMath.pointInPolygon(c, ring: $0) }
    }
}

/// Fetches regulatory hunting units from official state wildlife-agency ArcGIS
/// services. Free, public, no key. State-keyed registry, extensible like the
/// parcel registry: add a state's verified endpoint and it lights up there.
enum HuntingUnitsService {

    enum ServiceError: Error { case badResponse }

    struct Source {
        let url: String        // ArcGIS layer .../query endpoint, returns GeoJSON
        let nameField: String  // attribute holding the unit name
        let kind: String       // short label, e.g. "Deer Zone"
    }

    /// Verified official sources. Arkansas Game & Fish Commission deer zones are
    /// public-domain state data (services.arcgis.com/5bMc8SlGDYGINZr5).
    static let registry: [String: Source] = [
        "AR": Source(
            url: "https://services.arcgis.com/5bMc8SlGDYGINZr5/arcgis/rest/services/deerZones/FeatureServer/0/query",
            nameField: "fname", kind: "Deer Zone")
    ]

    static func hasCoverage(stateCode: String) -> Bool { registry[stateCode.uppercased()] != nil }

    static func units(stateCode: String,
                      center: CLLocationCoordinate2D,
                      radiusKm: Double = 40,
                      maxUnits: Int = 12) async throws -> [HuntingUnit] {
        guard let src = registry[stateCode.uppercased()] else { return [] }

        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let envelope = String(format: "%.5f,%.5f,%.5f,%.5f",
                              center.longitude - dLon, center.latitude - dLat,
                              center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: src.url)!
        comps.queryItems = [
            .init(name: "where", value: "1=1"),
            .init(name: "geometry", value: envelope),
            .init(name: "geometryType", value: "esriGeometryEnvelope"),
            .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "outFields", value: "OBJECTID,\(src.nameField)"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxUnits)),
            .init(name: "f", value: "geojson")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        // Dynamic name field per state, so parse loosely rather than via Codable.
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = root["features"] as? [[String: Any]] else { return [] }

        return features.compactMap { feature in
            let props = feature["properties"] as? [String: Any] ?? [:]
            let name = (props[src.nameField] as? String) ?? src.kind
            let id = (props["OBJECTID"] as? Int) ?? name.hashValue
            guard let geom = feature["geometry"] as? [String: Any],
                  let type = geom["type"] as? String else { return nil }
            let rings = ringsFrom(type: type, coords: geom["coordinates"])
            guard !rings.isEmpty else { return nil }
            return HuntingUnit(id: id, name: name, rings: rings)
        }
    }

    private static func ringsFrom(type: String, coords: Any?) -> [[CLLocationCoordinate2D]] {
        func ring(_ r: [[Double]]) -> [CLLocationCoordinate2D] {
            r.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) : nil }
        }
        switch type {
        case "Polygon":
            guard let poly = coords as? [[[Double]]] else { return [] }
            return poly.map(ring)
        case "MultiPolygon":
            guard let multi = coords as? [[[[Double]]]] else { return [] }
            return multi.flatMap { $0.map(ring) }
        default:
            return []
        }
    }
}
