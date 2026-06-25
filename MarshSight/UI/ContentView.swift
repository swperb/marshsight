import SwiftUI
import CoreLocation

struct ContentView: View {

    @StateObject private var location = LocationProvider()
    @StateObject private var engine = NavigationEngine(route: NavRoute(name: "", features: []))
    @StateObject private var regions = RegionStore()
    @StateObject private var contributions = ContributionStore()
    @State private var showMap = true
    @State private var showReport = false
    @State private var showRegionPicker = false
    @AppStorage("acceptedSafetyDisclaimer") private var acceptedSafety = false

    // Computed once per fix in onChange, not on every body re-evaluation.
    @State private var nearestGauge: WaterGauge?
    @State private var currentLand: PublicLand?
    @State private var currentParcel: Parcel?

    /// Route plus the active region's gauges plus user contributions.
    private var allFeatures: [MarkerFeature] {
        engine.route.features + (regions.active?.gaugeMarkers ?? []) + contributions.markers
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if !acceptedSafety {
                SafetyDisclaimerView { acceptedSafety = true }
            } else if !isAuthorized {
                permissionPrompt
            } else if regions.active == nil {
                // No region chosen yet: pick/download one before doing any work.
                RegionPickerView(store: regions,
                                 currentLocation: location.fix?.coordinate,
                                 allowDismiss: false)
            } else {
                arExperience
            }
        }
        .statusBarHidden(true)
        .onAppear { location.start() }
        .onChange(of: location.fix) { _, newFix in
            guard let f = newFix else { return }
            engine.update(with: f)
            updateContext(at: f.coordinate)
        }
        .onChange(of: regions.active) { _, _ in
            if let c = location.fix?.coordinate { updateContext(at: c) }
        }
    }

    /// Recompute the cached "where am I" context against the active region's
    /// static data. Runs once per coordinate change, not per body redraw.
    private func updateContext(at c: CLLocationCoordinate2D) {
        nearestGauge = regions.nearestGauge(to: c)
        currentLand = regions.currentLand(at: c)
        currentParcel = regions.active?.currentParcel(at: c)
    }

    private var isAuthorized: Bool {
        location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
    }

    private var arExperience: some View {
        ZStack(alignment: .topTrailing) {
            ARNavView(features: allFeatures,
                      fix: location.fix,
                      publicLands: regions.active?.publicLands ?? [],
                      regionToken: regions.active?.id ?? "")
                .ignoresSafeArea()

            HUDOverlay(guidance: engine.guidance,
                       fix: location.fix,
                       heading: location.heading,
                       nearestGauge: nearestGauge,
                       currentLand: currentLand,
                       currentParcel: currentParcel,
                       regionName: regions.active?.name)

            mapAndControls
        }
        .sheet(isPresented: $showReport) {
            ReportSheet(coordinate: location.fix?.coordinate) { kind, name, note, visibility in
                if let c = location.fix?.coordinate {
                    contributions.add(kind: kind, name: name, note: note, at: c, visibility: visibility)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerView(store: regions, currentLocation: location.fix?.coordinate)
        }
    }

    private var mapAndControls: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showMap {
                MiniMapView(region: regions.active,
                            track: location.track,
                            contributionMarkers: contributions.markers)
                    .equatable()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.5), lineWidth: 1))
                    .onTapGesture { showMap.toggle() }
            } else {
                controlButton(icon: "map.fill") { showMap.toggle() }
            }

            controlButton(icon: "square.stack.3d.up") { showRegionPicker = true }
            controlButton(icon: "plus.circle.fill") { showReport = true }
        }
        .padding(12)
        .padding(.top, 40)
    }

    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.5), in: Circle())
                .foregroundStyle(.white)
        }
    }

    private var permissionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.cyan)
            Text("MarshSight needs your location")
                .font(.title2.weight(.semibold))
            Text("We use GPS, heading, and the camera to place boundaries, water, and hazards into the real world around you.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button("Enable Location") { location.start() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }
}
