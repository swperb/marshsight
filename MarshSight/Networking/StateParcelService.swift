import Foundation
import CoreLocation

/// A single private-property parcel: boundary plus owner/id when the state
/// publishes it. Sourced from free, public, no-auth statewide GIS services.
struct Parcel: Identifiable, Equatable {
    let id: String
    let owner: String?
    let rings: [[CLLocationCoordinate2D]]

    static func == (lhs: Parcel, rhs: Parcel) -> Bool { lhs.id == rhs.id }

    func contains(_ c: CLLocationCoordinate2D) -> Bool {
        rings.contains { GeoMath.pointInPolygon(c, ring: $0) }
    }
}

/// Fetches parcels from free statewide GIS services. There is no free national
/// parcel layer (that aggregation is the incumbent's real moat), so coverage is
/// per state. Adding a state is one line in `endpoints`. Everything here is
/// public-domain or open state data; no onX or licensed vendor data is used.
enum StateParcelService {

    enum ServiceError: Error { case badResponse }

    /// State two-letter code -> ArcGIS query endpoint (GeoJSON, no auth).
    static let endpoints: [String: String] = [
        "AR": "https://geostor.arkansas.gov/arcgis/rest/services/FEATURESERVICES/Planning_Cadastre/FeatureServer/6",
        "WA": "https://services.arcgis.com/jsIt88o09Q0r1j8h/arcgis/rest/services/Current_Parcels/FeatureServer/0",
        "NY": "https://gisservices.its.ny.gov/arcgis/rest/services/NYS_Tax_Parcels_Public/MapServer/1",
        "MT": "https://gisservicemt.gov/arcgis/rest/services/MSDI_Framework/Parcels/MapServer/0",
        "VT": "https://services1.arcgis.com/BkFxaEFNwHqX3tAw/arcgis/rest/services/FS_VCGI_OPENDATA_Cadastral_VTPARCELS_poly_standardized_parcels_SP_v1/FeatureServer/0",
    ]

    /// County-level endpoints for states with no free statewide layer, keyed
    /// "STATE/COUNTY" (uppercased, no "County" suffix). Many Alabama counties
    /// publish parcel *boundaries* free; owner names stay in the assessor's
    /// system (the part Regrid licenses). Boundaries alone still show the lines.
    static let countyEndpoints: [String: String] = [
        "AL/COOSA": "https://maps.capturecama.com/arcgis/rest/services/Coosa/Coosa03122026/MapServer/171",
    ]

    private static func countyKey(_ state: String, _ county: String) -> String {
        let c = county.uppercased()
            .replacingOccurrences(of: " COUNTY", with: "")
            .trimmingCharacters(in: .whitespaces)
        return "\(state.uppercased())/\(c)"
    }

    static func hasCoverage(stateCode: String, county: String? = nil) -> Bool {
        if endpoints[stateCode.uppercased()] != nil { return true }
        if let c = county, countyEndpoints[countyKey(stateCode, c)] != nil { return true }
        return false
    }

    /// Normalize a placemark's administrativeArea (which may be a full name or a
    /// code) to a two-letter state code.
    static func stateCode(from administrativeArea: String?) -> String? {
        guard let a = administrativeArea?.trimmingCharacters(in: .whitespaces), !a.isEmpty else { return nil }
        if a.count == 2 { return a.uppercased() }
        return stateNameToCode[a.lowercased()]
    }

    private static let stateNameToCode: [String: String] = [
        "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR", "california": "CA",
        "colorado": "CO", "connecticut": "CT", "delaware": "DE", "florida": "FL", "georgia": "GA",
        "hawaii": "HI", "idaho": "ID", "illinois": "IL", "indiana": "IN", "iowa": "IA",
        "kansas": "KS", "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
        "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS", "missouri": "MO",
        "montana": "MT", "nebraska": "NE", "nevada": "NV", "new hampshire": "NH", "new jersey": "NJ",
        "new mexico": "NM", "new york": "NY", "north carolina": "NC", "north dakota": "ND", "ohio": "OH",
        "oklahoma": "OK", "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
        "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT", "vermont": "VT",
        "virginia": "VA", "washington": "WA", "west virginia": "WV", "wisconsin": "WI", "wyoming": "WY",
    ]

    /// Owner/id are picked from common field names so we do not need per-state
    /// field config. Lowercased for matching.
    private static let ownerFields = ["ownername", "own_name", "owner1", "owner", "ownname", "ownername1", "taxpayer", "ownerparcel"]
    private static let idFields = ["parcelid", "parcel_id", "parcel_id_nr", "pin", "print_key", "gisid", "propertyid", "parcelnumb"]

    static func parcels(stateCode: String,
                        county: String? = nil,
                        center: CLLocationCoordinate2D,
                        radiusKm: Double = 6,
                        maxParcels: Int = 1000) async throws -> [Parcel] {
        let base = endpoints[stateCode.uppercased()]
            ?? county.flatMap { countyEndpoints[countyKey(stateCode, $0)] }
        guard let base else { return [] }
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let env = String(format: "%.5f,%.5f,%.5f,%.5f",
                         center.longitude - dLon, center.latitude - dLat,
                         center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: base + "/query")!
        comps.queryItems = [
            .init(name: "where", value: "1=1"),
            .init(name: "geometry", value: env),
            .init(name: "geometryType", value: "esriGeometryEnvelope"),
            .init(name: "inSR", value: "4326"),
            .init(name: "spatialRel", value: "esriSpatialRelIntersects"),
            .init(name: "outFields", value: "*"),
            .init(name: "returnGeometry", value: "true"),
            .init(name: "resultRecordCount", value: String(maxParcels)),
            .init(name: "f", value: "geojson")
        ]
        guard let url = comps.url else { throw ServiceError.badResponse }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let fc = try JSONDecoder().decode(ParcelFC.self, from: data)
        return fc.features.enumerated().compactMap { idx, f in
            guard let rings = f.geometry?.rings(), !rings.isEmpty else { return nil }
            let props = f.properties.mapKeysLowercased()
            let owner = ownerFields.compactMap { props[$0]?.stringValue }.first { !$0.isEmpty }
            let pid = idFields.compactMap { props[$0]?.stringValue }.first { !$0.isEmpty } ?? "p\(idx)"
            return Parcel(id: pid, owner: owner, rings: rings)
        }
    }
}

// MARK: - GeoJSON parcel decoding (Polygon / MultiPolygon + free-form properties)

private struct ParcelFC: Decodable { let features: [ParcelFeature] }

private struct ParcelFeature: Decodable {
    let properties: [String: JSONValue]
    let geometry: ParcelGeometry?
}

private extension Dictionary where Key == String, Value == JSONValue {
    func mapKeysLowercased() -> [String: JSONValue] {
        var out: [String: JSONValue] = [:]
        for (k, v) in self { out[k.lowercased()] = v }
        return out
    }
}

private struct ParcelGeometry: Decodable {
    let type: String
    let coordinates: ParcelCoords
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

private struct ParcelCoords: Decodable {
    var polygon: [[[Double]]] = []
    var multiPolygon: [[[[Double]]]] = []
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let multi = try? c.decode([[[[Double]]]].self) { multiPolygon = multi }
        else if let poly = try? c.decode([[[Double]]].self) { polygon = poly }
    }
}

/// Minimal JSON value so we can read arbitrary parcel attribute types as strings.
enum JSONValue: Decodable {
    case string(String), number(Double), bool(Bool), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let d = try? c.decode(Double.self) { self = .number(d) }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else { self = .null }
    }
    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .number(let d): return d == d.rounded() ? String(Int(d)) : String(d)
        case .bool(let b): return String(b)
        case .null: return nil
        }
    }
}
