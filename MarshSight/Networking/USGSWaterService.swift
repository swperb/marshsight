import Foundation
import CoreLocation

/// A live water gauge reading. For flooded-timber duck hunting the river stage
/// is the single most important number: it decides whether the woods are
/// huntable. Data comes from the USGS Water Services NWIS API (public, no key).
struct WaterGauge: Identifiable, Equatable, Codable {
    var id: String          // USGS site code, e.g. "07074850"
    var name: String        // e.g. "Black River at Elgin Ferry, AR"
    var latitude: Double
    var longitude: Double
    var stageFeet: Double?      // parameter 00065, gage height
    var dischargeCFS: Double?   // parameter 00060, discharge
    var observedAt: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Render this gauge as a map/AR marker. The live stage rides in the depth
    /// slot so the existing marker label shows it.
    func asMarkerFeature() -> MarkerFeature {
        MarkerFeature(
            kind: .gauge,
            name: stageFeet != nil ? "\(name)" : name,
            latitude: latitude,
            longitude: longitude,
            depthFeet: stageFeet
        )
    }
}

enum USGSWaterService {

    /// USGS sentinel value for "no data" in NWIS responses.
    private static let noData = -999_999.0

    enum ServiceError: Error { case badResponse }

    /// Fetch active gauges within `radiusKm` of a center point, with their
    /// latest stage (00065) and discharge (00060).
    static func nearbyGauges(center: CLLocationCoordinate2D,
                             radiusKm: Double = 40) async throws -> [WaterGauge] {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        // USGS bBox is west,south,east,north and is capped at ~7 degrees per side.
        let west = center.longitude - dLon
        let south = center.latitude - dLat
        let east = center.longitude + dLon
        let north = center.latitude + dLat

        var comps = URLComponents(string: "https://waterservices.usgs.gov/nwis/iv/")!
        comps.queryItems = [
            .init(name: "format", value: "json"),
            .init(name: "bBox", value: String(format: "%.4f,%.4f,%.4f,%.4f", west, south, east, north)),
            .init(name: "parameterCd", value: "00065,00060"),
            .init(name: "siteStatus", value: "active")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(WaterML.self, from: data)
        return merge(decoded.value.timeSeries)
    }

    /// Each site appears once per parameter, so fold stage and discharge for the
    /// same site code into a single WaterGauge.
    private static func merge(_ series: [WaterML.TimeSeries]) -> [WaterGauge] {
        var bySite: [String: WaterGauge] = [:]

        for ts in series {
            guard let site = ts.sourceInfo.siteCode.first?.value else { continue }
            let geo = ts.sourceInfo.geoLocation.geogLocation
            let param = ts.variable.variableCode.first?.value
            let point = ts.values.first?.value.first
            let raw = point.flatMap { Double($0.value) }
            let value = (raw == noData) ? nil : raw
            let observed = point.flatMap { ISO8601DateFormatter().date(from: $0.dateTime) }

            var gauge = bySite[site] ?? WaterGauge(
                id: site, name: ts.sourceInfo.siteName,
                latitude: geo.latitude, longitude: geo.longitude
            )
            switch param {
            case "00065": gauge.stageFeet = value
            case "00060": gauge.dischargeCFS = value
            default: break
            }
            if let observed, gauge.observedAt == nil { gauge.observedAt = observed }
            bySite[site] = gauge
        }

        // Only surface gauges that have at least one usable reading.
        return bySite.values
            .filter { $0.stageFeet != nil || $0.dischargeCFS != nil }
            .sorted { $0.name < $1.name }
    }
}

// MARK: - Minimal WaterML JSON shape (only the fields we use)

private struct WaterML: Decodable {
    let value: Value
    struct Value: Decodable { let timeSeries: [TimeSeries] }

    struct TimeSeries: Decodable {
        let sourceInfo: SourceInfo
        let variable: Variable
        let values: [Values]
    }
    struct SourceInfo: Decodable {
        let siteName: String
        let siteCode: [SiteCode]
        let geoLocation: GeoLocation
    }
    struct SiteCode: Decodable { let value: String }
    struct GeoLocation: Decodable { let geogLocation: GeogLocation }
    struct GeogLocation: Decodable { let latitude: Double; let longitude: Double }
    struct Variable: Decodable { let variableCode: [VariableCode]; let unit: Unit }
    struct VariableCode: Decodable { let value: String }
    struct Unit: Decodable { let unitCode: String }
    struct Values: Decodable { let value: [Point] }
    struct Point: Decodable { let value: String; let dateTime: String }
}
