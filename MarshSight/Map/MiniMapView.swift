import SwiftUI
import MapKit

/// A 2D mini-map of the active offline region. It is `Equatable` on the region
/// identity and breadcrumb length, so SwiftUI skips re-rendering it on every GPS
/// fix; it only redraws when the region changes or the track grows. Geometry is
/// already simplified at download time, so overlays are light.
struct MiniMapView: View, Equatable {

    let region: LoadedRegion?
    let track: [CLLocationCoordinate2D]
    var contributionMarkers: [MarkerFeature] = []

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    static func == (lhs: MiniMapView, rhs: MiniMapView) -> Bool {
        lhs.region == rhs.region
            && lhs.track.count == rhs.track.count
            && lhs.contributionMarkers.count == rhs.contributionMarkers.count
    }

    var body: some View {
        Map(position: $camera) {
            if let region {
                // Private parcel outlines (thin, no fill) under the other layers.
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
