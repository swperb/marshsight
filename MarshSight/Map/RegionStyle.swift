import Foundation
import CoreLocation

/// Builds a MapLibre style JSON for a region: an open USGS basemap plus the
/// region's vector overlays inlined as GeoJSON. USGS National Map tiles are
/// public domain and cacheable, unlike Apple or Google tiles, which is what
/// makes a truly offline FOSS basemap possible.
/// The available open USGS National Map basemaps. All public domain, no key.
enum Basemap: String, CaseIterable, Identifiable {
    case hybrid, imagery, topo, relief
    var id: String { rawValue }

    var label: String {
        switch self {
        case .hybrid: return "Satellite + Topo"
        case .imagery: return "Satellite"
        case .topo: return "Topo"
        case .relief: return "Terrain"
        }
    }
    var icon: String {
        switch self {
        case .hybrid: return "map.fill"
        case .imagery: return "globe.americas.fill"
        case .topo: return "map"
        case .relief: return "mountain.2.fill"
        }
    }
    /// USGS National Map tiled service for this basemap (ArcGIS z/y/x order).
    var tileURL: String {
        let service: String
        switch self {
        case .hybrid: service = "USGSImageryTopo"
        case .imagery: service = "USGSImageryOnly"
        case .topo: service = "USGSTopo"
        case .relief: service = "USGSShadedReliefOnly"
        }
        return "https://basemap.nationalmap.gov/arcgis/rest/services/\(service)/MapServer/tile/{z}/{y}/{x}"
    }
}

enum RegionStyle {

    /// Write a style file for the region and return its URL.
    static func fileURL(region: LoadedRegion?, contributions: [MarkerFeature], basemap: Basemap) -> URL {
        let style = build(region: region, contributions: contributions, basemap: basemap)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("style_\(region?.id ?? "empty")_\(basemap.rawValue).json")
        if let data = try? JSONSerialization.data(withJSONObject: style) {
            try? data.write(to: url, options: .atomic)
        }
        return url
    }

    /// A minimal style with only the basemap raster, used to define what tiles
    /// an offline download should fetch. Overlays are local vector data and do
    /// not need caching.
    static func basemapStyleURL(_ basemap: Basemap) -> URL {
        let style: [String: Any] = [
            "version": 8,
            "sources": ["usgs": ["type": "raster", "tiles": [basemap.tileURL], "tileSize": 256, "maxzoom": 16]],
            "layers": [["id": "usgs", "type": "raster", "source": "usgs"]],
        ]
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("basemap_\(basemap.rawValue).json")
        if let data = try? JSONSerialization.data(withJSONObject: style) {
            try? data.write(to: url, options: .atomic)
        }
        return url
    }

    private static func build(region: LoadedRegion?, contributions: [MarkerFeature], basemap: Basemap) -> [String: Any] {
        let lands = region?.publicLands ?? []
        let landFC = featureCollection(lands.flatMap { land in
            land.rings.map { polygon($0, props: ["access": land.access.rawValue]) }
        })
        let parcelFC = featureCollection((region?.parcels ?? []).flatMap { p in p.rings.map { polygon($0) } })
        let lakeFC = featureCollection((region?.lakes ?? []).map { polygon($0) })
        let riverFC = featureCollection((region?.riverLines ?? []).map { lineString($0) })
        let points = (region?.gaugeMarkers ?? []) + contributions
        let pointFC = featureCollection(points.map {
            point($0.coordinate, props: ["color": hex($0.kind)])
        })

        let accessColor: [Any] = ["match", ["get", "access"],
                                  "OA", "#34C759", "RA", "#30B0C7", "XA", "#FF3B30", "#9CA3AF"]

        return [
            "version": 8,
            "sources": [
                "usgs": ["type": "raster", "tiles": [basemap.tileURL], "tileSize": 256, "maxzoom": 16],
                "lands": geojsonSource(landFC),
                "parcels": geojsonSource(parcelFC),
                "lakes": geojsonSource(lakeFC),
                "rivers": geojsonSource(riverFC),
                "points": geojsonSource(pointFC),
                "track": geojsonSource(featureCollection([])),
                "nav": geojsonSource(featureCollection([])),
                "dest": geojsonSource(featureCollection([])),
            ],
            "layers": [
                ["id": "bg", "type": "background", "paint": ["background-color": "#0a0f0d"]],
                ["id": "usgs", "type": "raster", "source": "usgs"],
                ["id": "lakes-fill", "type": "fill", "source": "lakes",
                 "paint": ["fill-color": "#3B82F6", "fill-opacity": 0.3]],
                ["id": "lakes-line", "type": "line", "source": "lakes",
                 "paint": ["line-color": "#3B82F6", "line-width": 1]],
                ["id": "lands-fill", "type": "fill", "source": "lands",
                 "paint": ["fill-color": accessColor, "fill-opacity": 0.22]],
                ["id": "lands-line", "type": "line", "source": "lands",
                 "paint": ["line-color": accessColor, "line-width": 1.5]],
                ["id": "parcels-line", "type": "line", "source": "parcels",
                 "paint": ["line-color": "#F59E0B", "line-opacity": 0.55, "line-width": 0.7]],
                ["id": "rivers-line", "type": "line", "source": "rivers",
                 "paint": ["line-color": "#3B82F6", "line-opacity": 0.7, "line-width": 2]],
                ["id": "track-line", "type": "line", "source": "track",
                 "paint": ["line-color": "#FFD60A", "line-width": 2.5]],
                ["id": "points", "type": "circle", "source": "points",
                 "paint": ["circle-radius": 5, "circle-color": ["get", "color"],
                           "circle-stroke-color": "#FFFFFF", "circle-stroke-width": 1.5]],
                ["id": "nav-line", "type": "line", "source": "nav",
                 "layout": ["line-cap": "round", "line-join": "round"],
                 "paint": ["line-color": "#0A84FF", "line-width": 5, "line-opacity": 0.95]],
                ["id": "dest", "type": "circle", "source": "dest",
                 "paint": ["circle-radius": 8, "circle-color": "#0A84FF",
                           "circle-stroke-color": "#FFFFFF", "circle-stroke-width": 3]],
            ],
        ]
    }

    /// Trackline from the user to the destination (the blue "go there" line).
    static func navGeoJSON(from: CLLocationCoordinate2D?, to: CLLocationCoordinate2D?) -> [String: Any] {
        guard let from, let to else { return featureCollection([]) }
        return featureCollection([lineString([from, to])])
    }

    /// The destination point marker.
    static func destGeoJSON(_ to: CLLocationCoordinate2D?) -> [String: Any] {
        guard let to else { return featureCollection([]) }
        return featureCollection([point(to)])
    }

    /// GeoJSON for the breadcrumb track, applied to the "track" source at runtime.
    static func trackGeoJSON(_ track: [CLLocationCoordinate2D]) -> [String: Any] {
        featureCollection(track.count > 1 ? [lineString(track)] : [])
    }

    /// GeoJSON for gauge + contribution points, applied to the "points" source
    /// at runtime so new reports appear without rebuilding the whole style.
    static func pointsGeoJSON(_ features: [MarkerFeature]) -> [String: Any] {
        featureCollection(features.map { point($0.coordinate, props: ["color": hex($0.kind)]) })
    }

    // MARK: - GeoJSON builders

    private static func geojsonSource(_ fc: [String: Any]) -> [String: Any] {
        ["type": "geojson", "data": fc]
    }
    private static func featureCollection(_ features: [[String: Any]]) -> [String: Any] {
        ["type": "FeatureCollection", "features": features]
    }
    private static func polygon(_ ring: [CLLocationCoordinate2D], props: [String: Any] = [:]) -> [String: Any] {
        ["type": "Feature", "properties": props,
         "geometry": ["type": "Polygon", "coordinates": [ring.map { [$0.longitude, $0.latitude] }]]]
    }
    private static func lineString(_ line: [CLLocationCoordinate2D], props: [String: Any] = [:]) -> [String: Any] {
        ["type": "Feature", "properties": props,
         "geometry": ["type": "LineString", "coordinates": line.map { [$0.longitude, $0.latitude] }]]
    }
    private static func point(_ c: CLLocationCoordinate2D, props: [String: Any] = [:]) -> [String: Any] {
        ["type": "Feature", "properties": props,
         "geometry": ["type": "Point", "coordinates": [c.longitude, c.latitude]]]
    }

    private static func hex(_ kind: MarkerFeature.Kind) -> String {
        switch kind {
        case .waypoint: return "#22D3EE"
        case .channelMarker: return "#22C55E"
        case .hazard: return "#FF3B30"
        case .launch: return "#FFD60A"
        case .access: return "#FF9500"
        case .blind: return "#AF52DE"
        case .gauge: return "#30B0C7"
        }
    }
}
