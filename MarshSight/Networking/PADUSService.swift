import Foundation
import CoreLocation

/// Fetches public-land boundaries from PAD-US (USGS Protected Areas Database)
/// via its public ArcGIS FeatureServer. This is the unified inventory of
/// federal, state, and local public land, including state Wildlife Management
/// Areas. Returned as GeoJSON in WGS84, so no reprojection is needed.
enum PADUSService {

    enum ServiceError: Error { case badResponse }

    private static let endpoint =
        "https://services.arcgis.com/v01gqwM5QqNysAAi/arcgis/rest/services/Manager_Name/FeatureServer/0/query"

    /// Public-land units intersecting a box around `center`.
    static func publicLands(center: CLLocationCoordinate2D,
                            radiusKm: Double = 15,
                            maxUnits: Int = 40) async throws -> [PublicLand] {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let envelope = String(format: "%.5f,%.5f,%.5f,%.5f",
                              center.longitude - dLon, center.latitude - dLat,
                              center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: endpoint)!
        comps.queryItems = [
            .init(name: "where", value: "1=1"),
            .init(name: "geometry", value: envelope),
            .init(name: "geometryType", value: "esriGeometryEnvelope"),
            .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "outFields", value: "OBJECTID,Unit_Nm,Mang_Name,Pub_Access"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxUnits)),
            .init(name: "f", value: "geojson")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let fc = try JSONDecoder().decode(GeoJSONFC.self, from: data)
        return fc.features.compactMap { feature in
            guard let geom = feature.geometry else { return nil }
            let rings = geom.rings()
            guard !rings.isEmpty else { return nil }
            return PublicLand(
                id: feature.properties.OBJECTID ?? rings.count,
                name: feature.properties.Unit_Nm ?? "Public Land",
                managerCode: feature.properties.Mang_Name ?? "",
                access: PublicAccess(code: feature.properties.Pub_Access),
                rings: rings
            )
        }
    }
}

// MARK: - GeoJSON decoding (Polygon and MultiPolygon)

private struct GeoJSONFC: Decodable { let features: [Feature] }

private struct Feature: Decodable {
    let properties: Props
    let geometry: Geometry?
}

private struct Props: Decodable {
    let OBJECTID: Int?
    let Unit_Nm: String?
    let Mang_Name: String?
    let Pub_Access: String?
}

/// GeoJSON geometry that may be Polygon ([ [ [lon,lat] ] ]) or MultiPolygon
/// ([ [ [ [lon,lat] ] ] ]). We flatten to a list of rings either way.
private struct Geometry: Decodable {
    let type: String
    let coordinates: Coordinates

    func rings() -> [[CLLocationCoordinate2D]] {
        switch type {
        case "Polygon":
            return coordinates.polygon.map(ringFrom)
        case "MultiPolygon":
            return coordinates.multiPolygon.flatMap { $0.map(ringFrom) }
        default:
            return []
        }
    }

    private func ringFrom(_ ring: [[Double]]) -> [CLLocationCoordinate2D] {
        ring.compactMap { pair in
            pair.count == 2 ? CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0]) : nil
        }
    }
}

/// Decodes either Polygon or MultiPolygon coordinate nesting.
private struct Coordinates: Decodable {
    var polygon: [[[Double]]] = []
    var multiPolygon: [[[[Double]]]] = []

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let multi = try? container.decode([[[[Double]]]].self) {
            multiPolygon = multi
        } else if let poly = try? container.decode([[[Double]]].self) {
            polygon = poly
        }
    }
}
