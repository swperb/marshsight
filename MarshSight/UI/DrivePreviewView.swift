import SwiftUI
import MapKit
import CoreLocation

/// An in-app preview of the drive to a destination: the road route on a map with
/// distance and time, then a button to hand off to Apple Maps for full
/// turn-by-turn. We don't reinvent driving navigation; we just let you see the
/// trip before you commit to it.
struct DrivePreviewView: View {
    let destination: NavDestination
    let origin: CLLocationCoordinate2D?

    @Environment(\.dismiss) private var dismiss
    @State private var route: MKRoute?
    @State private var loading = true
    @State private var failed = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                RoutePreviewMap(origin: origin, destination: destination.coordinate, route: route)
                    .ignoresSafeArea(edges: .bottom)
                summaryCard
            }
            .navigationTitle(destination.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .task { await loadRoute() }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            if loading {
                HStack(spacing: 8) { ProgressView(); Text("Finding the drive...") }
                    .font(.subheadline).foregroundStyle(.secondary)
            } else if let route {
                HStack(spacing: 24) {
                    stat(eta(route.expectedTravelTime), "drive")
                    stat(Fmt.distance(route.distance), "by road")
                }
            } else if failed {
                Text("Couldn't load the route. You can still open Apple Maps.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Button {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
                item.name = destination.name
                item.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
            } label: {
                Label("Open in Apple Maps", systemImage: "car.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(16)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.title2.weight(.bold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func eta(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins < 60 { return "\(mins) min" }
        return "\(mins / 60) hr \(mins % 60) min"
    }

    private func loadRoute() async {
        guard let origin else { failed = true; loading = false; return }
        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        req.transportType = .automobile
        do {
            let resp = try await MKDirections(request: req).calculate()
            route = resp.routes.first
        } catch {
            failed = true
        }
        loading = false
    }
}

/// MKMapView showing the drive route line, with start/end pins, framed to fit.
private struct RoutePreviewMap: UIViewRepresentable {
    let origin: CLLocationCoordinate2D?
    let destination: CLLocationCoordinate2D
    let route: MKRoute?

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        let dest = MKPointAnnotation()
        dest.coordinate = destination
        map.addAnnotation(dest)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        if let route {
            map.addOverlay(route.polyline)
            map.setVisibleMapRect(route.polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 180, right: 40),
                                  animated: false)
        } else if let origin {
            let rect = MKMapRect(origin: MKMapPoint(origin), size: .init(width: 1, height: 1))
                .union(MKMapRect(origin: MKMapPoint(destination), size: .init(width: 1, height: 1)))
            map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 60, left: 40, bottom: 180, right: 40),
                                  animated: false)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let r = MKPolylineRenderer(overlay: overlay)
            r.strokeColor = UIColor.systemCyan
            r.lineWidth = 5
            return r
        }
    }
}
