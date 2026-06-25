import SwiftUI
import CoreLocation

/// The AR camera overlay, presented full-screen only when the user explicitly
/// chooses it from the map. The ARSession starts when this view appears and is
/// paused when it is dismissed, so the camera is never running on the home
/// screen. A clear Close button returns to the map.
struct ARExperienceView: View {
    @ObservedObject var location: LocationProvider
    @ObservedObject var regions: RegionStore
    @ObservedObject var engine: NavigationEngine
    @ObservedObject var contributions: ContributionStore

    let nearestGauge: WaterGauge?
    let currentLand: PublicLand?
    let currentParcel: Parcel?
    var onClose: () -> Void

    @State private var showReport = false
    @State private var showInset = false

    /// AR shows local features only: the final destination and your own reports.
    /// Intermediate route waypoints and far-away gauges stay off the camera.
    private var allFeatures: [MarkerFeature] {
        let dest = engine.destination.map {
            [MarkerFeature(kind: .waypoint, name: $0.name, latitude: $0.latitude, longitude: $0.longitude)]
        } ?? []
        return dest + contributions.markers
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ARNavView(features: allFeatures,
                      fix: location.fix,
                      publicLands: regions.active?.publicLands ?? [],
                      regionToken: regions.active?.id ?? "",
                      destination: engine.guidance.activeWaypoint?.coordinate)
                .ignoresSafeArea()

            HUDOverlay(guidance: engine.guidance,
                       fix: location.fix,
                       heading: location.heading,
                       nearestGauge: nearestGauge,
                       currentLand: currentLand,
                       currentParcel: currentParcel,
                       regionName: regions.active?.name)

            topControls

            if showInset {
                RegionMapView(region: regions.active,
                              track: location.track,
                              contributionMarkers: contributions.markers,
                              interactive: false,
                              navPath: engine.remainingPath)
                    .equatable()
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.5), lineWidth: 1))
                    .padding(.trailing, 14)
                    .padding(.top, 56)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .sheet(isPresented: $showReport) {
            ReportSheet(coordinate: location.fix?.coordinate) { kind, name, note, visibility in
                if let c = location.fix?.coordinate {
                    contributions.add(kind: kind, name: name, note: note, at: c, visibility: visibility)
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var topControls: some View {
        VStack {
            HStack {
                circleButton(icon: "xmark", action: onClose)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    circleButton(icon: "map.fill") { showInset.toggle() }
                    circleButton(icon: "plus") { showReport = true }
                }
            }
        }
        .padding(14)
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(.white)
        }
    }
}
