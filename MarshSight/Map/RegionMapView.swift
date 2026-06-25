import SwiftUI
import MapLibre
import CoreLocation

/// The region map, rendered with MapLibre GL Native over a public-domain USGS
/// basemap (free, cacheable, and the path to true offline maps). Used full-screen
/// on the home screen and as a small inset in AR. Equatable so SwiftUI skips it
/// on every GPS fix; the basemap style is rebuilt only when the region changes,
/// while the track and points are updated at runtime without a reload.
struct RegionMapView: UIViewRepresentable, Equatable {

    let region: LoadedRegion?
    let track: [CLLocationCoordinate2D]
    var contributionMarkers: [MarkerFeature] = []
    var interactive: Bool = true
    var basemap: Basemap = .hybrid
    /// Bump to recenter the map on the user (the home screen's locate button).
    var recenterTick: Int = 0

    static func == (lhs: RegionMapView, rhs: RegionMapView) -> Bool {
        lhs.region == rhs.region
            && lhs.track.count == rhs.track.count
            && lhs.contributionMarkers.count == rhs.contributionMarkers.count
            && lhs.interactive == rhs.interactive
            && lhs.basemap == rhs.basemap
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

        if styleToken != coord.lastToken {
            coord.lastToken = styleToken
            coord.styleLoaded = false
            uiView.styleURL = RegionStyle.fileURL(region: region, contributions: contributionMarkers, basemap: basemap)
        } else {
            coord.applyDynamicSources()
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

        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            styleLoaded = true
            applyDynamicSources()
        }

        /// Update the track and points sources in place (no style reload).
        func applyDynamicSources() {
            guard styleLoaded, let style = map?.style else { return }
            setShape(style, "track", RegionStyle.trackGeoJSON(track))
            let points = (region?.gaugeMarkers ?? []) + contributionMarkers
            setShape(style, "points", RegionStyle.pointsGeoJSON(points))
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
