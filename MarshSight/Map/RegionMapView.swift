import SwiftUI
import MapLibre
import CoreLocation

/// The region map, rendered with MapLibre GL Native over a public-domain USGS
/// basemap (free, cacheable, and the path to true offline maps). Used full-screen
/// on the home screen and as a small inset in AR. Equatable so SwiftUI skips it
/// on every GPS fix; the basemap style is rebuilt only when the region changes,
/// while the track and points are updated at runtime without a reload.
/// Which overlay groups are drawn on the map. Toggled from the home screen's
/// layers menu so a hunter can declutter a dense area.
struct LayerVisibility: Equatable {
    var land = true
    var units = true
    var parcels = true
    var water = true
    var trails = true
    var slope = false   // 3DEP slope overlay, online-only, off by default
    var scent = false   // downwind scent cone, off by default
}

struct RegionMapView: UIViewRepresentable, Equatable {

    let region: LoadedRegion?
    let track: [CLLocationCoordinate2D]
    var contributionMarkers: [MarkerFeature] = []
    var interactive: Bool = true
    var basemap: Basemap = .hybrid
    var navPath: [CLLocationCoordinate2D] = []
    var layers: LayerVisibility = .init()
    var windFromDegrees: Double? = nil
    var windSpeedMph: Double? = nil
    /// Bump to recenter the map on the user (the home screen's locate button).
    var recenterTick: Int = 0

    static func == (lhs: RegionMapView, rhs: RegionMapView) -> Bool {
        lhs.region == rhs.region
            && lhs.track.count == rhs.track.count
            && lhs.contributionMarkers.count == rhs.contributionMarkers.count
            && lhs.interactive == rhs.interactive
            && lhs.basemap == rhs.basemap
            && lhs.navPath.count == rhs.navPath.count
            && lhs.navPath.last?.latitude == rhs.navPath.last?.latitude
            && lhs.navPath.last?.longitude == rhs.navPath.last?.longitude
            && lhs.layers == rhs.layers
            && lhs.windFromDegrees == rhs.windFromDegrees
            && lhs.windSpeedMph == rhs.windSpeedMph
            && lhs.recenterTick == rhs.recenterTick
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MLNMapView {
        let map = MLNMapView(frame: .zero)
        map.delegate = context.coordinator
        map.styleURL = RegionStyle.fileURL(region: region, contributions: contributionMarkers, basemap: basemap)
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.allowsScrolling = interactive
        map.allowsZooming = interactive
        map.allowsRotating = interactive
        map.allowsTilting = interactive
        if let c = region?.center {
            map.setCenter(c, zoomLevel: 13, animated: false)
        }
        context.coordinator.map = map
        context.coordinator.lastToken = styleToken
        return map
    }

    /// Style is rebuilt when either the region or the basemap changes.
    private var styleToken: String { "\(region?.id ?? "empty")|\(basemap.rawValue)" }

    func updateUIView(_ uiView: MLNMapView, context: Context) {
        let coord = context.coordinator
        coord.region = region
        coord.track = track
        coord.contributionMarkers = contributionMarkers
        coord.navPath = navPath
        coord.layers = layers
        coord.windFromDegrees = windFromDegrees
        coord.windSpeedMph = windSpeedMph

        if styleToken != coord.lastToken {
            coord.lastToken = styleToken
            coord.styleLoaded = false
            uiView.styleURL = RegionStyle.fileURL(region: region, contributions: contributionMarkers, basemap: basemap)
        } else {
            coord.applyDynamicSources()
            coord.applyLayerVisibility()
        }

        if recenterTick != coord.lastRecenter {
            coord.lastRecenter = recenterTick
            uiView.userTrackingMode = .follow
        }
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        weak var map: MLNMapView?
        var lastToken = ""
        var lastRecenter = 0
        var styleLoaded = false
        var region: LoadedRegion?
        var track: [CLLocationCoordinate2D] = []
        var contributionMarkers: [MarkerFeature] = []
        var navPath: [CLLocationCoordinate2D] = []
        var layers = LayerVisibility()
        var windFromDegrees: Double?
        var windSpeedMph: Double?

        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            styleLoaded = true
            applyDynamicSources()
            applyLayerVisibility()
        }

        /// Show or hide each overlay group by setting style-layer visibility.
        func applyLayerVisibility() {
            guard styleLoaded, let style = map?.style else { return }
            func set(_ id: String, _ visible: Bool) { style.layer(withIdentifier: id)?.isVisible = visible }
            set("lands-fill", layers.land); set("lands-line", layers.land)
            set("units-line", layers.units)
            set("parcels-line", layers.parcels)
            set("lakes-fill", layers.water); set("lakes-line", layers.water); set("rivers-line", layers.water)
            set("trails-line", layers.trails)
            set("slope-raster", layers.slope)
            set("scent-fill", layers.scent)
            updateScentCone(map?.userLocation?.coordinate)
        }

        /// Keep the trackline glued to the live user position as it updates.
        func mapView(_ mapView: MLNMapView, didUpdate userLocation: MLNUserLocation?) {
            updateNavLine(userLocation?.coordinate)
            updateScentCone(userLocation?.coordinate)
        }

        /// Update the track, points, destination, and nav line in place.
        func applyDynamicSources() {
            guard styleLoaded, let style = map?.style else { return }
            setShape(style, "track", RegionStyle.trackGeoJSON(track))
            let points = (region?.gaugeMarkers ?? []) + contributionMarkers
            setShape(style, "points", RegionStyle.pointsGeoJSON(points))
            setShape(style, "dest", RegionStyle.destGeoJSON(navPath.last))
            updateNavLine(map?.userLocation?.coordinate)
            updateScentCone(map?.userLocation?.coordinate)
        }

        private func updateNavLine(_ user: CLLocationCoordinate2D?) {
            guard styleLoaded, let style = map?.style else { return }
            let line = (user != nil && !navPath.isEmpty) ? [user!] + navPath : []
            setShape(style, "nav", RegionStyle.navLineGeoJSON(line))
        }

        /// Recompute the downwind scent cone from the live position and wind.
        func updateScentCone(_ user: CLLocationCoordinate2D?) {
            guard styleLoaded, let style = map?.style else { return }
            let geo = layers.scent
                ? RegionStyle.scentConeGeoJSON(center: user, windFromDegrees: windFromDegrees, windSpeedMph: windSpeedMph)
                : RegionStyle.scentConeGeoJSON(center: nil, windFromDegrees: nil, windSpeedMph: nil)
            setShape(style, "scent", geo)
        }

        private func setShape(_ style: MLNStyle, _ id: String, _ geojson: [String: Any]) {
            guard let src = style.source(withIdentifier: id) as? MLNShapeSource,
                  let data = try? JSONSerialization.data(withJSONObject: geojson),
                  let shape = try? MLNShape(data: data, encoding: String.Encoding.utf8.rawValue)
            else { return }
            src.shape = shape
        }
    }
}
