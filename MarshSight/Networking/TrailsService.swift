import Foundation
import CoreLocation

/// Fetches National Forest System trails from the USFS public ArcGIS service.
/// Public-domain federal data, returned as GeoJSON in WGS84. Relevant for
/// hunters and anglers moving through national forest land.
enum TrailsService {

    enum ServiceError: Error { case badResponse }

    private static let endpoint =
        "https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_TrailNFSPublish_01/MapServer/0/query"

    static func trails(center: CLLocationCoordinate2D,
                       radiusKm: Double = 15,
                       maxTrails: Int = 200) async throws -> [[CLLocationCoordinate2D]] {
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
            .init(name: "outFields", value: "TRAIL_NAME"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxTrails)),
            .init(name: "f", value: "geojson")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let fc = try JSONDecoder().decode(LineFC.self, from: data)
        return fc.features.compactMap { $0.geometry?.lines() }.flatMap { $0 }
    }
}

// MARK: - GeoJSON line decoding (LineString / MultiLineString)

private struct LineFC: Decodable { let features: [LineFeature] }
private struct LineFeature: Decodable { let geometry: LineGeometry? }

private struct LineGeometry: Decodable {
    let type: String
    let coordinates: LineCoords
    func lines() -> [[CLLocationCoordinate2D]] {
        switch type {
        case "LineString": return [line(coordinates.line)]
        case "MultiLineString": return coordinates.multiLine.map(line)
        default: return []
        }
    }
    private func line(_ l: [[Double]]) -> [CLLocationCoordinate2D] {
        l.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) : nil }
    }
}

private struct LineCoords: Decodable {
    var line: [[Double]] = []
    var multiLine: [[[Double]]] = []
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let multi = try? c.decode([[[Double]]].self) { multiLine = multi }
        else if let single = try? c.decode([[Double]].self) { line = single }
    }
}
