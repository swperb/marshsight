import SwiftUI
import CoreLocation

struct ContentView: View {

    @StateObject private var location = LocationProvider()
    @StateObject private var engine = NavigationEngine(route: NavRoute(name: "", features: []))
    @StateObject private var regions = RegionStore()
    @StateObject private var contributions = ContributionStore()
    @StateObject private var weather = WeatherStore()
    @StateObject private var tides = TideStore()
    @StateObject private var recorder = TrackRecorder()
    @StateObject private var offline = OfflineManager()
    @StateObject private var logbook = LogbookStore()
    @StateObject private var premium = PremiumStore()

    @State private var showReport = false
    @State private var reportKind: Contribution.Kind = .hazard
    @State private var showRegionPicker = false
    @State private var showDestinationSearch = false
    @State private var showAR = false
    @AppStorage("acceptedSafetyDisclaimer") private var acceptedSafety = false
    @AppStorage("basemap") private var basemap: Basemap = .satellite
    @AppStorage("parkedLat") private var parkedLat = 0.0
    @AppStorage("parkedLon") private var parkedLon = 0.0
    @AppStorage("hasParked") private var hasParked = false

    // Cached "where am I" context, recomputed once per coordinate change.
    @State private var nearestGauge: WaterGauge?
    @State private var currentLand: PublicLand?
    @State private var currentParcel: Parcel?
    @State private var currentUnit: HuntingUnit?

    var body: some View {
        Group {
            if !acceptedSafety {
                OnboardingView(location: location) { acceptedSafety = true }
            } else if !isAuthorized {
                permissionPrompt
            } else if regions.active == nil {
                if location.fix != nil {
                    loadingArea
                } else {
                    RegionPickerView(store: regions,
                                     offline: offline,
                                     currentLocation: location.fix?.coordinate,
                                     basemap: basemap,
                                     allowDismiss: false)
                }
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
            Task { await regions.autoLoadIfNeeded(around: f.coordinate) }
            Task { await weather.refreshIfStale(at: f.coordinate) }
            Task { await tides.refreshIfStale(at: f.coordinate) }
            Task { await contributions.fetchNearby(f.coordinate) }
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
                    engine: engine,
                    basemap: $basemap,
                    nearestGauge: nearestGauge,
                    currentLand: currentLand,
                    currentParcel: currentParcel,
                    currentUnit: currentUnit,
                    weather: weather.weather,
                    tides: tides,
                    logbook: logbook,
                    premium: premium,
                    onEnterAR: { showAR = true },
                    onReport: { reportKind = .hazard; showReport = true },
                    onTagOwner: { reportKind = .owner; showReport = true },
                    onSwitchRegion: { showRegionPicker = true },
                    onSearch: { showDestinationSearch = true },
                    onNavigateTo: startNavigation,
                    onMarkTruck: markTruck,
                    onReturnToTruck: returnToTruck,
                    onRetrace: retraceSteps,
                    hasParked: hasParked,
                    canReturn: canReturn,
                    canRetrace: canRetrace)
            .sheet(isPresented: $showReport) {
                ReportSheet(coordinate: location.fix?.coordinate, initialKind: reportKind) { kind, name, note, visibility in
                    if let c = location.fix?.coordinate {
                        contributions.add(kind: kind, name: name, note: note, at: c, visibility: visibility)
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showRegionPicker) {
                RegionPickerView(store: regions,
                                 offline: offline,
                                 currentLocation: location.fix?.coordinate,
                                 basemap: basemap)
            }
            .sheet(isPresented: $showDestinationSearch) {
                DestinationSearchView(
                    center: location.fix?.coordinate ?? regions.active?.center,
                    contributions: contributions,
                    extraSpots: regions.active?.gaugeMarkers ?? [],
                    onSelect: startNavigation)
            }
    }

    private var isAuthorized: Bool {
        location.authorization == .authorizedWhenInUse || location.authorization == .authorizedAlways
    }

    /// Plan a water-aware route (or a straight line on land) and start navigating.
    private func startNavigation(to dest: NavDestination) {
        let start = location.fix?.coordinate ?? regions.active?.center ?? dest.coordinate
        let path = WaterRouter.route(from: start, to: dest.coordinate, lakes: regions.active?.lakes ?? [])
            ?? [dest.coordinate]
        engine.navigate(to: dest, path: path)
    }

    // MARK: - Return to truck / retrace

    private var parkedCoordinate: CLLocationCoordinate2D? {
        hasParked ? CLLocationCoordinate2D(latitude: parkedLat, longitude: parkedLon) : nil
    }

    /// Save the current position as where the truck or boat is parked.
    private func markTruck() {
        guard let c = location.fix?.coordinate else { return }
        parkedLat = c.latitude
        parkedLon = c.longitude
        hasParked = true
    }

    /// Navigate back to the marked truck, or to where this session started if
    /// nothing was marked. Water-aware, like any other destination.
    private func returnToTruck() {
        let coord = parkedCoordinate ?? location.track.first
        guard let coord else { return }
        startNavigation(to: NavDestination(name: "Truck", latitude: coord.latitude, longitude: coord.longitude))
    }

    /// Retrace the breadcrumb: follow the path walked this session in reverse,
    /// back to where it started. Good for getting out the way you came in.
    private func retraceSteps() {
        let crumbs = location.track
        guard crumbs.count > 1, let start = crumbs.first else { return }
        engine.navigate(to: NavDestination(name: "Start", latitude: start.latitude, longitude: start.longitude),
                        path: Array(crumbs.reversed()))
    }

    private var canRetrace: Bool { location.track.count > 1 }
    private var canReturn: Bool { hasParked || canRetrace }

    private func updateContext(at c: CLLocationCoordinate2D) {
        nearestGauge = regions.nearestGauge(to: c)
        currentLand = regions.currentLand(at: c)
        currentParcel = regions.active?.currentParcel(at: c)
        currentUnit = regions.active?.currentUnit(at: c)
    }

    private var loadingArea: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.4).tint(.cyan)
            Text(regions.status ?? "Loading the area around you...")
                .font(.headline).foregroundStyle(.white)
            Text("Public land, hunting units, water, and trails near you.")
                .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
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
