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

    /// Verified state sources, all free/public, no key.
    /// AR: Arkansas Game & Fish Commission deer zones (services.arcgis.com/5bMc8SlGDYGINZr5).
    /// AL: Alabama Wildlife Management Areas. Alabama publishes no open deer-zone
    ///     polygons and its official DCNR server is unreachable, so this is a
    ///     hosted copy of the public-record WMA boundaries.
    /// MS: MDWFP official deer zones (DELTA ZONE, SOUTH ZONE, ...) from the
    ///     Mississippi Wildlife agency's own ArcGIS server.
    /// LA: LDWF official Wildlife Management Areas and Refuges.
    /// MO: Missouri Department of Conservation lands (conservation areas), via
    ///     the state spatial data service (MSDIS, University of Missouri).
    static let registry: [String: Source] = [
        "AR": Source(
            url: "https://services.arcgis.com/5bMc8SlGDYGINZr5/arcgis/rest/services/deerZones/FeatureServer/0/query",
            nameField: "fname", kind: "Deer Zone"),
        "AL": Source(
            url: "https://services7.arcgis.com/iEMmryaM5E3wkdnU/arcgis/rest/services/Alabama_Wildlife_Management_Areas/FeatureServer/0/query",
            nameField: "Name", kind: "WMA"),
        "MS": Source(
            url: "https://arcgis.mdwfp.com/arcgis/rest/services/Public/Public_WMA_Data/MapServer/7/query",
            nameField: "Name", kind: "Deer Zone"),
        "LA": Source(
            url: "https://services1.arcgis.com/6euNCaGPCgCzgAVF/arcgis/rest/services/LDWF_WMA_Refuge/FeatureServer/0/query",
            nameField: "NAME", kind: "WMA"),
        "MO": Source(
            url: "https://services2.arcgis.com/kNS2ppBA4rwAQQZy/arcgis/rest/services/MO_Missouri_Department_of_Conservation_Lands/FeatureServer/0/query",
            nameField: "Area_Name", kind: "Conservation Area")
    ]

    static func hasCoverage(stateCode: String) -> Bool { registry[stateCode.uppercased()] != nil }

    static func units(stateCode: String,
                      center: CLLocationCoordinate2D,
                      radiusKm: Double = 40,
                      maxUnits: Int = 50) async throws -> [HuntingUnit] {
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
            .init(name: "outFields", value: "*"),
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
