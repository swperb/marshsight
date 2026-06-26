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
        var whereClause: String = "1=1"  // server-side filter
    }

    /// National overlays that apply in every state, fetched by location rather
    /// than by state code. FWS publishes hunt-unit boundaries for the whole
    /// National Wildlife Refuge System; we keep only the huntable units.
    static let nationalSources: [Source] = [
        Source(
            url: "https://services.arcgis.com/QVENGdaPbd4LUkLV/arcgis/rest/services/FWS_NWRS_HQ_PublicHuntUnits_view/FeatureServer/0/query",
            nameField: "Organization_Name", kind: "Refuge Hunt Unit", whereClause: "Huntable='Yes'")
    ]

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
            nameField: "Area_Name", kind: "Conservation Area"),
        // TN: TWRA hunting-allowed lands (WMAs and refuges).
        "TN": Source(
            url: "https://services3.arcgis.com/PWXNAH2YKmZY7lBq/arcgis/rest/services/Hunting_Allowed/FeatureServer/0/query",
            nameField: "NAME", kind: "Hunting Land"),
        // GA: Georgia DNR Wildlife Resources Division WMA boundaries (layer 14).
        "GA": Source(
            url: "https://services6.arcgis.com/9QlSLDqa0P1cHLhu/arcgis/rest/services/WRD_WMA_Public/FeatureServer/14/query",
            nameField: "PropName", kind: "WMA"),
        // FL: FWC official Wildlife Management Areas.
        "FL": Source(
            url: "https://gis.myfwc.com/mapping/rest/services/Open_Data/Wildlife_Management_Areas_Florida/MapServer/1/query",
            nameField: "NAME", kind: "WMA"),
        // TX: TPWD Wildlife Management Areas for public distribution.
        "TX": Source(
            url: "https://services1.arcgis.com/1mtXwieMId59thmg/arcgis/rest/services/WMA_Boundaries_4PublicDistribution/FeatureServer/0/query",
            nameField: "LoName", kind: "WMA"),
        // OK: ODWC public WMA boundaries.
        "OK": Source(
            url: "https://services1.arcgis.com/jRf8jjFwxedITdFe/arcgis/rest/services/Public_WMA_Boundaries/FeatureServer/1/query",
            nameField: "WMANAME", kind: "WMA"),
        // KS: Kansas Dept of Wildlife, Parks & Tourism protected areas (wildlife areas).
        "KS": Source(
            url: "https://services1.arcgis.com/q2CglofYX6ACNEeu/arcgis/rest/services/protected_areas/FeatureServer/0/query",
            nameField: "Unit_Name", kind: "Public Land"),
        // NE: Nebraska Game & Parks deer management units.
        "NE": Source(
            url: "https://services5.arcgis.com/IOshH1zLrIieqrNk/arcgis/rest/services/AOSC_Deer_Units/FeatureServer/0/query",
            nameField: "UnitName", kind: "Deer Unit"),
        // IA: Iowa DNR Wildlife Management Areas.
        "IA": Source(
            url: "https://services.arcgis.com/8lRhdTsQyJpO52F1/arcgis/rest/services/Wildlife_Management_Area_IA_View/FeatureServer/0/query",
            nameField: "NAME", kind: "WMA"),
        // IN: Indiana DNR managed lands (fish & wildlife areas, public access sites).
        "IN": Source(
            url: "https://gisdata.in.gov/server/rest/services/Hosted/ManagedLands_DNR_Open/FeatureServer/0/query",
            nameField: "unitname", kind: "DNR Property"),
        // KY: KDFWR public hunting areas.
        "KY": Source(
            url: "https://services3.arcgis.com/ghsX9CKghMvyYjBU/arcgis/rest/services/Ky_KDFWR_PublicHuntingAreas_WM_gdb/FeatureServer/0/query",
            nameField: "AREANAME", kind: "Public Hunting Area"),
        // NY: NYS DEC Wildlife Management Areas (layer 17).
        "NY": Source(
            url: "https://services6.arcgis.com/DZHaqZm9cxOD4CWM/arcgis/rest/services/Wildlife_Management_Areas/FeatureServer/17/query",
            nameField: "WMA", kind: "WMA"),
        // CO: Colorado Parks & Wildlife game management units (numbered).
        "CO": Source(
            url: "https://services5.arcgis.com/enGOFVOIYC8OyheQ/arcgis/rest/services/Game_Management_Units_(GMUs)_CPW/FeatureServer/0/query",
            nameField: "GMUID", kind: "Game Management Unit"),
        // MT: Montana FWP deer/elk/lion hunting districts (numbered).
        "MT": Source(
            url: "https://services3.arcgis.com/Cdxz8r11hT0MGzg1/arcgis/rest/services/ADMBND_HD_DEERELKLION/FeatureServer/0/query",
            nameField: "NAME", kind: "Hunting District"),
        // WY: Wyoming Game & Fish elk hunt areas (numbered).
        "WY": Source(
            url: "https://services6.arcgis.com/cWzdqIyxbijuhPLw/arcgis/rest/services/ElkHuntAreas/FeatureServer/0/query",
            nameField: "HUNTAREA", kind: "Elk Hunt Area"),
        // ID: Idaho Fish & Game game management units.
        "ID": Source(
            url: "https://services.arcgis.com/FjJI5xHF2dUPVrgK/arcgis/rest/services/GameManagementUnits/FeatureServer/0/query",
            nameField: "NAME", kind: "Game Management Unit"),
        // UT: Utah DWR big game hunt boundaries.
        "UT": Source(
            url: "https://services.arcgis.com/ZzrwjTRez6FJiOq4/arcgis/rest/services/Utah_Big_Game_Hunt_Boundaries_2025/FeatureServer/0/query",
            nameField: "Boundary_Name", kind: "Hunt Boundary"),
        // NV: Nevada Dept of Wildlife game management units.
        "NV": Source(
            url: "https://services.arcgis.com/RyxlXSfFi87rAosq/arcgis/rest/services/NDOWGameMgmtUnits/FeatureServer/0/query",
            nameField: "HUNTUNIT", kind: "Game Management Unit"),
        // AZ: Arizona Game & Fish hunt units.
        "AZ": Source(
            url: "https://services8.arcgis.com/KyZIQDOsXnGaTxj2/arcgis/rest/services/AZ_Game_and_Fish_Hunt_Units/FeatureServer/0/query",
            nameField: "GMU", kind: "Game Management Unit"),
        // NM: New Mexico Dept of Game & Fish game management units.
        "NM": Source(
            url: "https://services2.arcgis.com/CjbW1bVhK4dB3WOa/arcgis/rest/services/NMDGF_Game_Management_Units_I_E__v2_WFL1/FeatureServer/0/query",
            nameField: "GMU", kind: "Game Management Unit"),
        // WA: WDFW game management units (self-hosted).
        "WA": Source(
            url: "https://geodataservices.wdfw.wa.gov/arcgis/rest/services/MapServices/SharedReferenceLayers/MapServer/0/query",
            nameField: "GMU_Name", kind: "Game Management Unit"),
        // OR: Oregon Dept of Fish & Wildlife wildlife management units (self-hosted).
        "OR": Source(
            url: "https://nrimp.dfw.state.or.us/arcgis/rest/services/ODFW_Admin/WildlifeManagementUnits/FeatureServer/0/query",
            nameField: "UNIT_NAME", kind: "Wildlife Management Unit"),
        // CA: CDFW deer hunt zones.
        "CA": Source(
            url: "https://services2.arcgis.com/Uq9r85Potqm3MfRV/arcgis/rest/services/biosds342_fpu/FeatureServer/0/query",
            nameField: "Zone_Nam", kind: "Deer Hunt Zone"),
        // PA: PA Game Commission state game lands (numbered).
        "PA": Source(
            url: "https://pgcmaps.pa.gov/arcgis/rest/services/PGC/NEW_PUBLIC/MapServer/18/query",
            nameField: "NAME", kind: "State Game Lands"),
        // WV: WV DNR Wildlife Management Areas (layer 14).
        "WV": Source(
            url: "https://services9.arcgis.com/SQbkdxLkuQJuLGtx/arcgis/rest/services/West_Virginia_Wildlife_Management_Areas/FeatureServer/14/query",
            nameField: "Name", kind: "WMA"),
        // VA: VA Dept of Wildlife Resources WMA boundaries (self-hosted).
        "VA": Source(
            url: "https://services.dwr.virginia.gov/arcgis/rest/services/HUB_Layers/DWR_WMA_Boundaries/FeatureServer/0/query",
            nameField: "WMA_NAME", kind: "WMA"),
        // NC: NC Wildlife Resources Commission game lands (layer 21).
        "NC": Source(
            url: "https://services1.arcgis.com/YfqBAUM5nWR3yhGP/arcgis/rest/services/gamelands_general/FeatureServer/21/query",
            nameField: "GML_HAB", kind: "Game Land"),
        // SC: SCDNR public lands (WMAs and other public properties).
        "SC": Source(
            url: "https://services.arcgis.com/acgZYxoN5Oj8pDLa/arcgis/rest/services/DEV_-_SCDNR_Public_Lands_Viewer/FeatureServer/3/query",
            nameField: "PropertyName", kind: "Public Land"),
        // MD: MD DNR protected lands, filtered to named WMAs.
        "MD": Source(
            url: "https://mdgeodata.md.gov/imap/rest/services/Environment/MD_ProtectedLands/FeatureServer/0/query",
            nameField: "DNRName", kind: "WMA", whereClause: "DNRName LIKE '%WMA%'"),
        // ND: ND Game & Fish Wildlife Management Areas.
        "ND": Source(
            url: "https://services1.arcgis.com/GOcSXpzwBHyk2nog/arcgis/rest/services/NDGISHUB_Wildlife_Management_Areas/FeatureServer/0/query",
            nameField: "Unit_Name", kind: "WMA"),
        // MN: MN DNR publicly accessible Wildlife Management Areas (self-hosted).
        "MN": Source(
            url: "https://enterprise.gisdata.mn.gov/aghost/rest/services/us_mn_state_dnr/bdry_dnr_wildlife_mgmt_areas_pub/FeatureServer/0/query",
            nameField: "unit_name", kind: "WMA"),
        // WI: WI DNR managed properties (wildlife and fishery areas, self-hosted).
        "WI": Source(
            url: "https://dnrmaps.wi.gov/arcgis/rest/services/LF_DML/LF_AGOL_STAGING_WTM_Ext/MapServer/0/query",
            nameField: "PROP_NAME", kind: "DNR Property"),
        // MI: MI DNR managed lands, filtered to state game areas.
        "MI": Source(
            url: "https://services3.arcgis.com/Jdnp1TjADvSDxMAX/arcgis/rest/services/DNRLOTSParcelsOPENDATA/FeatureServer/2/query",
            nameField: "ProjectName", kind: "State Game Area", whereClause: "ProjectUseType='Wildlife Game Areas'"),
        // OH: ODNR Division of Wildlife lands, filtered to wildlife areas.
        "OH": Source(
            url: "https://gis.ohiodnr.gov/arcgis/rest/services/DOW_Services/HuntingRegulations_AGOL_3/MapServer/18/query",
            nameField: "LANDS_NAME", kind: "Wildlife Area", whereClause: "PROP_TYPE='WA'"),
        // ME: Maine Dept of Inland Fisheries & Wildlife WMAs.
        "ME": Source(
            url: "https://services1.arcgis.com/RbMX0mRVOFNTdLzd/arcgis/rest/services/MaineDIFW_WildlifeManagementAreas/FeatureServer/0/query",
            nameField: "PARCEL_NAME", kind: "WMA"),
        // NH: NH Fish & Game lands via UNH GRANIT, filtered to F&G ownership.
        "NH": Source(
            url: "https://nhgeodata.unh.edu/hosting/rest/services/Hosted/EC_Conservation/FeatureServer/6/query",
            nameField: "name", kind: "WMA", whereClause: "ppagency=32000"),
        // VT: Vermont Fish & Wildlife WMAs.
        "VT": Source(
            url: "https://anrmaps.vermont.gov/arcgis/rest/services/map_services/MAP_ANR_ANRATLASFISHWILDLIFE_WM_NOCACHE/MapServer/20/query",
            nameField: "NAME", kind: "WMA"),
        // MA: MassWildlife lands, filtered to Wildlife Management Areas.
        "MA": Source(
            url: "https://services1.arcgis.com/7iJyYTjCtKsZS1LR/arcgis/rest/services/MassWildlifeLands/FeatureServer/0/query",
            nameField: "SITE_NAME", kind: "WMA", whereClause: "F_TYPE='WMA'"),
        // CT: CT DEEP property, filtered to wildlife areas.
        "CT": Source(
            url: "https://services1.arcgis.com/FjPcSmEFuDYlIdKC/arcgis/rest/services/Connecticut_DEEP_Property/FeatureServer/0/query",
            nameField: "PROPERTY", kind: "Wildlife Area", whereClause: "AV_LEGEND='Wildlife Area'"),
        // RI: RI DEM conservation lands, filtered to management areas.
        "RI": Source(
            url: "https://services2.arcgis.com/S8zZg9pg23JUEexQ/arcgis/rest/services/ENV_Conservation_Lands_State_spf/FeatureServer/0/query",
            nameField: "NAME", kind: "Management Area", whereClause: "PrimUse='Management Area'"),
        // NJ: NJ DEP Fish & Wildlife WMA boundaries.
        "NJ": Source(
            url: "https://services1.arcgis.com/QWdNfRs7lkPq4g4Q/arcgis/rest/services/Wildlife_Management_Area_WMA_Restrictions_in_New_Jersey/FeatureServer/41/query",
            nameField: "WMA", kind: "WMA"),
        // AK: Alaska Dept of Fish & Game game management subunits.
        "AK": Source(
            url: "https://services.arcgis.com/VdkVOAHovLuozJG4/arcgis/rest/services/Subunits_shp/FeatureServer/0/query",
            nameField: "SubLabel", kind: "Game Management Subunit"),
        // HI: Hawaii DLNR DOFAW mammal hunting units, excluding blank names.
        "HI": Source(
            url: "https://services.arcgis.com/HQ0xoN0EzDPBOEci/arcgis/rest/services/HuntingSection2019_mammal/FeatureServer/0/query",
            nameField: "Unit_Name", kind: "Hunting Unit", whereClause: "Unit_Name IS NOT NULL AND Unit_Name<>' '")
    ]

    static func hasCoverage(stateCode: String) -> Bool { registry[stateCode.uppercased()] != nil }

    /// State hunting units for the region's state, plus any national overlays
    /// (e.g. federal refuge hunt units) that apply everywhere.
    static func units(stateCode: String,
                      center: CLLocationCoordinate2D,
                      radiusKm: Double = 40,
                      maxUnits: Int = 50) async throws -> [HuntingUnit] {
        var out: [HuntingUnit] = []
        if let src = registry[stateCode.uppercased()] {
            out += (try? await fetch(src: src, center: center, radiusKm: radiusKm, maxUnits: maxUnits)) ?? []
        }
        for src in nationalSources {
            out += (try? await fetch(src: src, center: center, radiusKm: radiusKm, maxUnits: maxUnits)) ?? []
        }
        return out
    }

    private static func fetch(src: Source,
                              center: CLLocationCoordinate2D,
                              radiusKm: Double,
                              maxUnits: Int) async throws -> [HuntingUnit] {
        let m = GeoMath.metersPerDegree(atLatitude: center.latitude)
        let dLat = (radiusKm * 1000) / m.latM
        let dLon = (radiusKm * 1000) / m.lonM
        let envelope = String(format: "%.5f,%.5f,%.5f,%.5f",
                              center.longitude - dLon, center.latitude - dLat,
                              center.longitude + dLon, center.latitude + dLat)

        var comps = URLComponents(string: src.url)!
        comps.queryItems = [
            .init(name: "where", value: src.whereClause),
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

        // Dynamic name field per source, so parse loosely rather than via Codable.
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = root["features"] as? [[String: Any]] else { return [] }

        return features.compactMap { feature in
            let props = feature["properties"] as? [String: Any] ?? [:]
            let name = displayName(props[src.nameField], kind: src.kind)
            let id = (props["OBJECTID"] as? Int) ?? name.hashValue
            guard let geom = feature["geometry"] as? [String: Any],
                  let type = geom["type"] as? String else { return nil }
            let rings = ringsFrom(type: type, coords: geom["coordinates"])
            guard !rings.isEmpty else { return nil }
            return HuntingUnit(id: id, name: name, rings: rings)
        }
    }

    /// Build a human label from a name attribute that may be a string, an
    /// integer (e.g. a unit number like 15), or missing. Bare numbers and short
    /// codes get the kind prefixed so "15" reads as "Game Management Unit 15".
    private static func displayName(_ raw: Any?, kind: String) -> String {
        let value: String
        if let s = raw as? String { value = s.trimmingCharacters(in: .whitespaces) }
        else if let i = raw as? Int { value = String(i) }
        else if let d = raw as? Double { value = String(Int(d)) }
        else { value = "" }
        if value.isEmpty { return kind }
        let bare = value.allSatisfy { $0.isNumber || $0 == "-" } || value.count <= 3
        return bare ? "\(kind) \(value)" : value
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
