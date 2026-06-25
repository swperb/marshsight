import Foundation
import CoreLocation

/// Fetches river and stream geometry from the USGS National Hydrography Dataset
/// (NHD) ArcGIS REST service. This is the public-domain river network that draws
/// the actual watercourse a duck hunter floats. Layer 6 is NHDFlowline.
enum NHDService {

    enum ServiceError: Error { case badResponse }

    /// River, stream, and creek polylines intersecting a box around `center`.
    /// NHDFlowline (layer 6) includes every watercourse from big rivers down to
    /// small creeks. We page through results (NHD caps at 2000 per request) so a
    /// region captures the whole network, not just the first handful.
    static func riverLines(center: CLLocationCoordinate2D,
                           radiusKm: Double = 12,
                           maxLines: Int = 4000) async throws -> [[CLLocationCoordinate2D]] {
        let envelope = box(center: center, radiusKm: radiusKm)
        let base = "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/6/query"

        var all: [[CLLocationCoordinate2D]] = []
        var offset = 0
        let page = 2000
        while all.count < maxLines {
            var comps = URLComponents(string: base)!
            comps.queryItems = [
                .init(name: "where", value: "1=1"),
                .init(name: "geometry", value: envelope),
                .init(name: "geometryType", value: "esriGeometryEnvelope"),
                .init(name: "inSR", value: "4326"),
                .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
                .init(name: "outFields", value: ""),
                .init(name: "returnGeometry", value: "true"),
                .init(name: "resultRecordCount", value: String(page)),
                .init(name: "resultOffset", value: String(offset)),
                .init(name: "f", value: "json")
            ]
            guard let url = comps.url else { break }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let decoded = try? JSONDecoder().decode(ESRIPolylineResponse.self, from: data)
            else { break }

            // ArcGIS returns Web Mercator (wkid 102100/3857); reproject to WGS84.
            all.append(contentsOf: decoded.features.flatMap { feature in
                feature.geometry.paths.map { path in
                    path.compactMap { pair -> CLLocationCoordinate2D? in
                        guard pair.count == 2 else { return nil }
                        return WebMercator.toWGS84(x: pair[0], y: pair[1])
                    }
                }
            })
            if decoded.features.count < page { break }   // last page
            offset += page
        }
        return all
    }

    /// Lake, reservoir, and pond shorelines from NHD waterbodies (layer 12), as
    /// polygon rings in WGS84. The waterbody layer includes small ponds, not just
    /// big lakes, so paging captures all of them across the region.
    static func lakes(center: CLLocationCoordinate2D,
                      radiusKm: Double = 12,
                      maxLakes: Int = 1500) async throws -> [[CLLocationCoordinate2D]] {
        let envelope = box(center: center, radiusKm: radiusKm)
        let base = "https://hydro.nationalmap.gov/arcgis/rest/services/nhd/MapServer/12/query"

        var all: [[CLLocationCoordinate2D]] = []
        var offset = 0
        let page = 2000
        while all.count < maxLakes {
            var comps = URLComponents(string: base)!
            comps.queryItems = [
                .init(name: "where", value: "1=1"),
                .init(name: "geometry", value: envelope),
                .init(name: "geometryType", value: "esriGeometryEnvelope"),
                .init(name: "inSR", value: "4326"),
                .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
                .init(name: "outFields", value: ""),
                .init(name: "returnGeometry", value: "true"),
                .init(name: "resultRecordCount", value: String(page)),
                .init(name: "resultOffset", value: String(offset)),
                .init(name: "f", value: "geojson")
            ]
            guard let url = comps.url else { break }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let fc = try? JSONDecoder().decode(WaterbodyFC.self, from: data)
            else { break }
            all.append(contentsOf: fc.features.compactMap { $0.geometry?.rings() }.flatMap { $0 })
            if fc.features.count < page { break }
            offset += page
        }
        return all
    }

    /// A WGS84 envelope "minLon,minLat,maxLon,maxLat" around a center point.
    private static func box(center: CLLocationCoordinate2D, radiusKm: Double) -> String {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        return String(format: "%.5f,%.5f,%.5f,%.5f",
                      center.longitude - dLon, center.latitude - dLat,
                      center.longitude + dLon, center.latitude + dLat)
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
