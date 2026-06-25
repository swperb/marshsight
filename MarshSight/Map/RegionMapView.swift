import SwiftUI
import MapKit

/// The region map, used full-screen on the home screen and as a small inset in
/// AR. It is `Equatable` on the region identity and breadcrumb length, so
/// SwiftUI skips re-rendering it on every GPS fix; it only redraws when the
/// region changes or the track grows. Geometry is simplified at download time,
/// so overlays are light.
struct RegionMapView: View, Equatable {

    let region: LoadedRegion?
    let track: [CLLocationCoordinate2D]
    var contributionMarkers: [MarkerFeature] = []
    var interactive: Bool = true

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    static func == (lhs: RegionMapView, rhs: RegionMapView) -> Bool {
        lhs.region == rhs.region
            && lhs.track.count == rhs.track.count
            && lhs.contributionMarkers.count == rhs.contributionMarkers.count
            && lhs.interactive == rhs.interactive
    }

    var body: some View {
        Map(position: $camera, interactionModes: interactive ? .all : []) {
            if let region {
                ForEach(region.parcels) { parcel in
                    ForEach(Array(parcel.rings.enumerated()), id: \.offset) { _, ring in
                        if ring.count > 2 {
                            MapPolygon(coordinates: ring)
                                .foregroundStyle(.clear)
                                .stroke(.orange.opacity(0.55), lineWidth: 0.7)
                        }
                    }
                }
                ForEach(Array(region.lakes.enumerated()), id: \.offset) { _, ring in
                    if ring.count > 2 {
                        MapPolygon(coordinates: ring)
                            .foregroundStyle(.blue.opacity(0.35))
                            .stroke(.blue, lineWidth: 1)
                    }
                }
                ForEach(region.publicLands) { land in
                    ForEach(Array(land.rings.enumerated()), id: \.offset) { _, ring in
                        if ring.count > 2 {
                            MapPolygon(coordinates: ring)
                                .foregroundStyle(land.access.color.opacity(0.22))
                                .stroke(land.access.color, lineWidth: 1.5)
                        }
                    }
                }
                ForEach(Array(region.riverLines.enumerated()), id: \.offset) { _, line in
                    if line.count > 1 {
                        MapPolyline(coordinates: line).stroke(.blue.opacity(0.7), lineWidth: 2)
                    }
                }
            }

            if track.count > 1 {
                MapPolyline(coordinates: track).stroke(.yellow.opacity(0.9), lineWidth: 2)
            }

            ForEach((region?.gaugeMarkers ?? []) + contributionMarkers) { feature in
                Annotation(feature.name, coordinate: feature.coordinate) {
                    Image(systemName: feature.kind.symbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(feature.kind.tint, in: Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                }
            }

            UserAnnotation()
        }
        .mapStyle(.imagery(elevation: .flat))
    }
}
