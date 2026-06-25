import Foundation
import CoreLocation

/// Fetches river and stream geometry from the USGS National Hydrography Dataset
/// (NHD) ArcGIS REST service. This is the public-domain river network that draws
/// the actual watercourse a duck hunter floats. Layer 6 is NHDFlowline.
enum NHDService {

    enum ServiceError: Error { case badResponse }

    /// River/stream polylines intersecting a box around `center`. Each result is
    /// an ordered list of WGS84 coordinates ready to draw as a MapPolyline.
    static func riverLines(center: CLLocationCoordinate2D,
                           radiusKm: Double = 12,
                           maxLines: Int = 60) async throws -> [[CLLocationCoordinate2D]] {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let envelope = String(format: "%.5f,%.5f,%.5f,%.5f",
                              center.longitude - dLon, center.latitude - dLat,
                              center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/6/query")!
        comps.queryItems = [
            .init(name: "where", value: "1=1"),
            .init(name: "geometry", value: envelope),
            .init(name: "geometryType", value: "esriGeometryEnvelope"),
            .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "outFields", value: "gnis_name"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxLines)),
            .init(name: "f", value: "json")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(ESRIPolylineResponse.self, from: data)
        // ArcGIS returns Web Mercator (wkid 102100/3857); reproject to WGS84.
        return decoded.features.flatMap { feature in
            feature.geometry.paths.map { path in
                path.compactMap { pair -> CLLocationCoordinate2D? in
                    guard pair.count == 2 else { return nil }
                    return WebMercator.toWGS84(x: pair[0], y: pair[1])
                }
            }
        }
    }

    /// Lake and reservoir shorelines from NHD waterbodies (layer 12), as polygon
    /// rings in WGS84. This is the water surface a fisherman works. Requested as
    /// GeoJSON so no reprojection is needed.
    static func lakes(center: CLLocationCoordinate2D,
                      radiusKm: Double = 12,
                      maxLakes: Int = 30) async throws -> [[CLLocationCoordinate2D]] {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let envelope = String(format: "%.5f,%.5f,%.5f,%.5f",
                              center.longitude - dLon, center.latitude - dLat,
                              center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/12/query")!
        comps.queryItems = [
            .init(name: "where", value: "1=1"),
            .init(name: "geometry", value: envelope),
            .init(name: "geometryType", value: "esriGeometryEnvelope"),
            .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "outFields", value: "gnis_name"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxLakes)),
            .init(name: "f", value: "geojson")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let fc = try JSONDecoder().decode(WaterbodyFC.self, from: data)
        return fc.features.compactMap { $0.geometry?.rings() }.flatMap { $0 }
    }
}

// MARK: - GeoJSON waterbody (Polygon / MultiPolygon) decoding

private struct WaterbodyFC: Decodable { let features: [WBFeature] }
private struct WBFeature: Decodable { let geometry: WBGeometry? }

private struct WBGeometry: Decodable {
    let type: String
    let coordinates: WBCoordinates

    func rings() -> [[CLLocationCoordinate2D]] {
        switch type {
        case "Polygon": return coordinates.polygon.map(ring)
        case "MultiPolygon": return coordinates.multiPolygon.flatMap { $0.map(ring) }
        default: return []
        }
    }
    private func ring(_ r: [[Double]]) -> [CLLocationCoordinate2D] {
        r.compactMap { $0.count == 2 ? CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) : nil }
    }
}

private struct WBCoordinates: Decodable {
    var polygon: [[[Double]]] = []
    var multiPolygon: [[[[Double]]]] = []
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let multi = try? c.decode([[[[Double]]]].self) { multiPolygon = multi }
        else if let poly = try? c.decode([[[Double]]].self) { polygon = poly }
    }
}

/// Web Mercator (EPSG:3857) to WGS84 lat/lon.
enum WebMercator {
    private static let originShift = 20_037_508.342789244

    static func toWGS84(x: Double, y: Double) -> CLLocationCoordinate2D {
        let lon = (x / originShift) * 180.0
        var lat = (y / originShift) * 180.0
        lat = 180.0 / .pi * (2 * atan(exp(lat * .pi / 180.0)) - .pi / 2)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - ESRI JSON polyline shape

private struct ESRIPolylineResponse: Decodable {
    let features: [Feature]
    struct Feature: Decodable { let geometry: Geometry }
    struct Geometry: Decodable { let paths: [[[Double]]] }
}
