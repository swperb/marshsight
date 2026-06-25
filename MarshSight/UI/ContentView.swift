import SwiftUI
import CoreLocation

struct ContentView: View {

    @StateObject private var location = LocationProvider()
    @StateObject private var engine = NavigationEngine(route: NavRoute(name: "", features: []))
    @StateObject private var regions = RegionStore()
    @StateObject private var contributions = ContributionStore()
    @StateObject private var weather = WeatherStore()
    @StateObject private var recorder = TrackRecorder()
    @StateObject private var offline = OfflineManager()

    @State private var showReport = false
    @State private var showRegionPicker = false
    @State private var showAR = false
    @AppStorage("acceptedSafetyDisclaimer") private var acceptedSafety = false

    // Cached "where am I" context, recomputed once per coordinate change.
    @State private var nearestGauge: WaterGauge?
    @State private var currentLand: PublicLand?
    @State private var currentParcel: Parcel?

    var body: some View {
        Group {
            if !acceptedSafety {
                SafetyDisclaimerView { acceptedSafety = true }
            } else if !isAuthorized {
                permissionPrompt
            } else if regions.active == nil {
                RegionPickerView(store: regions,
                                 currentLocation: location.fix?.coordinate,
                                 allowDismiss: false)
            } else if showAR {
                // Swap to AR entirely (don't keep the home map rendering behind it).
                ARExperienceView(location: location,
                                 regions: regions,
                                 engine: engine,
                                 contributions: contributions,
                                 nearestGauge: nearestGauge,
                                 currentLand: currentLand,
                                 currentParcel: currentParcel,
                                 onClose: { showAR = false })
            } else {
                home
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { location.start() }
        .onChange(of: location.fix) { _, newFix in
            guard let f = newFix else { return }
            engine.update(with: f)
            updateContext(at: f.coordinate)
            recorder.record(f)
            Task { await weather.refreshIfStale(at: f.coordinate) }
        }
        .onChange(of: regions.active) { _, _ in
            if let c = location.fix?.coordinate { updateContext(at: c) }
        }
    }

    private var home: some View {
        MapHomeView(regions: regions,
                    location: location,
                    contributions: contributions,
                    recorder: recorder,
                    offline: offline,
                    nearestGauge: nearestGauge,
                    currentLand: currentLand,
                    currentParcel: currentParcel,
                    weather: weather.weather,
                    onEnterAR: { showAR = true },
                    onReport: { showReport = true },
                    onSwitchRegion: { showRegionPicker = true })
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

    private var isAuthorized: Bool {
        location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
    }

    private func updateContext(at c: CLLocationCoordinate2D) {
        nearestGauge = regions.nearestGauge(to: c)
        currentLand = regions.currentLand(at: c)
        currentParcel = regions.active?.currentParcel(at: c)
    }

    private var permissionPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.cyan)
            Text("MarshSight needs your location")
                .font(.title2.weight(.semibold))
            Text("Your location places boundaries, water, and hazards on the map. The camera is only used later, when you choose to open AR.")
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
