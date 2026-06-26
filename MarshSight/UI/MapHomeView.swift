import SwiftUI
import CoreLocation

/// The home screen: a full, interactive map of the active region. This is what
/// the app opens to. The camera and AR are never started here, which keeps the
/// app private and calm on launch; you enter AR deliberately with a clear button.
struct MapHomeView: View {
    @ObservedObject var regions: RegionStore
    @ObservedObject var location: LocationProvider
    @ObservedObject var contributions: ContributionStore
    @ObservedObject var recorder: TrackRecorder
    @ObservedObject var offline: OfflineManager
    @ObservedObject var engine: NavigationEngine
    @Binding var basemap: Basemap

    let nearestGauge: WaterGauge?
    let currentLand: PublicLand?
    let currentParcel: Parcel?
    let currentUnit: HuntingUnit?
    let weather: Weather?
    @ObservedObject var tides: TideStore
    @ObservedObject var logbook: LogbookStore

    var onEnterAR: () -> Void
    var onReport: () -> Void
    var onSwitchRegion: () -> Void
    var onSearch: () -> Void
    var onNavigateTo: (NavDestination) -> Void
    var onMarkTruck: () -> Void
    var onReturnToTruck: () -> Void
    var onRetrace: () -> Void
    var hasParked: Bool
    var canReturn: Bool
    var canRetrace: Bool

    @State private var recenterTick = 0
    @State private var showFeedback = false
    @State private var showLogbook = false
    @State private var showLegend = false
    @State private var selectedMarker: SelectedMarker?

    private var tideNote: String? {
        tides.next.map { "\($0.isHigh ? "High" : "Low") \(Self.tideTimeFmt.string(from: $0.time))" }
    }

    @AppStorage("layer.land") private var showLand = true
    @AppStorage("layer.units") private var showUnits = true
    @AppStorage("layer.parcels") private var showParcels = true
    @AppStorage("layer.water") private var showWater = true
    @AppStorage("layer.trails") private var showTrails = true
    @AppStorage("layer.slope") private var showSlope = false
    @AppStorage("layer.scent") private var showScent = false
    @AppStorage("layer.radar") private var showRadar = false

    private var layerVisibility: LayerVisibility {
        .init(land: showLand, units: showUnits, parcels: showParcels,
              water: showWater, trails: showTrails, slope: showSlope,
              scent: showScent, radar: showRadar)
    }

    var body: some View {
        ZStack {
            RegionMapView(region: regions.active,
                          track: location.track,
                          contributionMarkers: contributions.allMarkers,
                          interactive: true,
                          basemap: basemap,
                          navPath: engine.remainingPath,
                          layers: layerVisibility,
                          windFromDegrees: weather?.windFromDegrees,
                          windSpeedMph: weather?.windSpeedMph,
                          onSelectMarker: { selectedMarker = $0 },
                          recenterTick: recenterTick)
                .equatable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if weather != nil { weatherStrip }
                if let t = tides.next { tideStrip(t) }
                searchBar
                Spacer()
                if let m = selectedMarker { markerCard(m) }
                else if engine.isNavigating { navBanner } else { contextCard }
                enterARButton
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            sideButtons
        }
        .sheet(isPresented: $showFeedback) { FeedbackView() }
        .sheet(isPresented: $showLogbook) {
            LogbookView(store: logbook, coordinate: location.fix?.coordinate,
                        weather: weather, tideNote: tideNote)
        }
        .sheet(isPresented: $showLegend) { LegendView() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(action: onSwitchRegion) {
                pill {
                    Label(regions.active?.name ?? "Region", systemImage: "square.stack.3d.up.fill")
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            pill {
                Label(gpsText, systemImage: gpsSymbol).foregroundStyle(gpsColor)
            }
            Menu {
                Button { showLegend = true } label: { Label("Map Legend", systemImage: "list.bullet.rectangle") }
                Button { showLogbook = true } label: { Label("Logbook", systemImage: "book.closed") }
                Button { showFeedback = true } label: { Label("Help & Feedback", systemImage: "questionmark.bubble") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.55), in: Circle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Search + navigation

    private var searchBar: some View {
        Button(action: onSearch) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                Text("Where to?")
                Spacer()
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(.black.opacity(0.55), in: Capsule())
        }
        .padding(.top, 8)
    }

    @ViewBuilder private var navBanner: some View {
        if engine.arrived {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("You've arrived").font(.headline).foregroundStyle(.white)
                    Text(engine.destination?.name ?? "").font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                }
                Spacer()
                Button("Done") { engine.stopNavigating() }.buttonStyle(.borderedProminent).tint(.green)
            }
            .padding(14)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
            .padding(.bottom, 10)
        } else {
            HStack(spacing: 12) {
                Image(systemName: "location.north.fill")
                    .font(.title3.weight(.bold)).foregroundStyle(.cyan)
                    .rotationEffect(.degrees(relativeBearing))
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.destination?.name ?? "Destination")
                        .font(.headline).foregroundStyle(.white).lineLimit(1)
                    Label(navStats, systemImage: engine.route.waypoints.count > 1 ? "water.waves" : "arrow.up.forward")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.85)).monospacedDigit()
                }
                Spacer()
                Button { engine.stopNavigating() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(14)
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
            .padding(.bottom, 10)
        }
    }

    private var relativeBearing: Double {
        guard let target = engine.guidance.bearingToWaypoint else { return 0 }
        return NavigationEngine.relativeBearing(heading: location.heading, target: target)
    }

    private var navStats: String {
        guard let d = engine.guidance.distanceToWaypoint else { return "Arrived" }
        let mi = d / 1609.344
        let dist = mi < 0.2 ? String(format: "%.0f yd", mi * 1760) : String(format: "%.1f mi", mi)
        if let speed = location.fix?.speedMetersPerSecond, speed > 0.6 {
            let mins = Int((d / speed) / 60)
            return mins < 1 ? "\(dist)  ·  under 1 min" : "\(dist)  ·  \(mins) min"
        }
        return dist
    }

    // MARK: - Weather strip (wind is the headline for hunters)

    @ViewBuilder private var weatherStrip: some View {
        if let w = weather {
            let moon = MoonPhase.current()
            HStack(spacing: 0) {
                weatherMetric(icon: "thermometer.medium", text: String(format: "%.0f°F", w.temperatureF))
                divider
                HStack(spacing: 6) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.cyan)
                        // Rotate to show the direction the wind blows TOWARD.
                        .rotationEffect(.degrees(w.windFromDegrees + 180))
                    Text(String(format: "%.0f mph %@", w.windSpeedMph, w.windFromCardinal))
                        .font(.caption.weight(.semibold)).monospacedDigit()
                }
                divider
                weatherMetric(icon: "barometer", text: String(format: "%.2f", w.pressureInHg))
                divider
                weatherMetric(icon: moon.symbol, text: "\(Int(moon.illumination * 100))%")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.black.opacity(0.55), in: Capsule())
            .padding(.top, 8)
        }
    }

    private func weatherMetric(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.white.opacity(0.8))
            Text(text).font(.caption.weight(.semibold)).monospacedDigit()
        }
    }

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 16).padding(.horizontal, 10)
    }

    // MARK: - Context card (where am I, what is the water doing)

    private var contextCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AROUND YOU")
                .font(.caption2.weight(.bold)).foregroundStyle(.white.opacity(0.45))
                .tracking(0.5)
            if let land = currentLand {
                contextRow(color: land.access.color, icon: "leaf.fill",
                           title: land.name, sub: "\(land.access.label)  -  \(land.manager)")
            } else if let parcel = currentParcel {
                contextRow(color: .orange, icon: "house.lodge.fill",
                           title: "Private Land",
                           sub: parcel.owner.map { "Owner: \($0)" } ?? "Owner not listed")
            }
            if let unit = currentUnit {
                contextRow(color: .purple, icon: "scope",
                           title: unit.name, sub: "Hunting unit")
            }
            if let g = nearestGauge {
                contextRow(color: .teal, icon: "gauge.with.dots.needle.bottom.50percent",
                           title: g.name,
                           sub: "River gauge  ·  \(gaugeText(g))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 12)
        .opacity(currentLand == nil && currentParcel == nil && currentUnit == nil && nearestGauge == nil ? 0 : 1)
    }

    private func contextRow(color: Color, icon: String, title: String, sub: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.weight(.bold)).foregroundStyle(.white).lineLimit(1)
                Text(sub).font(.caption2).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
            }
            Spacer()
        }
    }

    // MARK: - Enter AR

    private var enterARButton: some View {
        Button(action: onEnterAR) {
            HStack(spacing: 10) {
                Image(systemName: "arkit").font(.title3.weight(.bold))
                Text(engine.isNavigating ? "Navigate in AR" : "Look Around in AR").font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.cyan.gradient, in: RoundedRectangle(cornerRadius: 18))
            .foregroundStyle(.black)
        }
    }

    // MARK: - Side buttons

    private var sideButtons: some View {
        VStack(spacing: 12) {
            basemapMenu
            layersMenu
            returnMenu
            offlineButton
            recordButton
            if recorder.hasTrack && !recorder.isRecording, let gpx = recorder.exportGPX() {
                ShareLink(item: gpx) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 46, height: 46)
                        .background(.black.opacity(0.55), in: Circle())
                        .foregroundStyle(.white)
                }
            }
            circleButton(icon: "plus", action: onReport)
            circleButton(icon: "location.fill.viewfinder") { recenterTick += 1 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 14)
    }

    private var offlineID: String { "\(regions.active?.name ?? "")|\(basemap.rawValue)" }
    private var offlineMap: OfflineMap? { offline.maps.first { $0.id == offlineID } }
    private var isDownloadingActive: Bool { offline.downloadingID == offlineID }

    private var offlineButton: some View {
        Button {
            if let r = regions.active, !isDownloadingActive {
                offline.download(regionName: r.name, center: r.center, basemap: basemap)
            }
        } label: {
            ZStack {
                Circle().fill(.black.opacity(0.55)).frame(width: 46, height: 46)
                if isDownloadingActive {
                    Circle().trim(from: 0, to: offlineMap?.progress ?? 0.02)
                        .stroke(.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 38, height: 38).rotationEffect(.degrees(-90))
                    Text("\(Int((offlineMap?.progress ?? 0) * 100))").font(.caption2.bold()).foregroundStyle(.white)
                } else {
                    Image(systemName: offlineMap?.isComplete == true ? "checkmark.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(offlineMap?.isComplete == true ? .green : .white)
                }
            }
        }
    }

    private var recordButton: some View {
        Button {
            if recorder.isRecording { recorder.stop() } else { recorder.start() }
        } label: {
            Image(systemName: recorder.isRecording ? "stop.fill" : "record.circle")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 46, height: 46)
                .background((recorder.isRecording ? Color.red : .black.opacity(0.55)), in: Circle())
                .foregroundStyle(.white)
        }
    }

    private var basemapMenu: some View {
        Menu {
            Picker("Basemap", selection: $basemap) {
                ForEach(Basemap.allCases) { b in
                    Label(b.label, systemImage: b.icon).tag(b)
                }
            }
        } label: {
            Image(systemName: basemap.icon)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(.white)
        }
    }

    private var layersMenu: some View {
        Menu {
            Toggle(isOn: $showLand) { Label("Public land", systemImage: "leaf.fill") }
            Toggle(isOn: $showUnits) { Label("Hunting units", systemImage: "scope") }
            Toggle(isOn: $showParcels) { Label("Property lines", systemImage: "square.dashed") }
            Toggle(isOn: $showWater) { Label("Water", systemImage: "drop.fill") }
            Toggle(isOn: $showTrails) { Label("Trails", systemImage: "figure.walk") }
            Toggle(isOn: $showSlope) { Label("Slope angle (online)", systemImage: "triangle.fill") }
            Toggle(isOn: $showScent) { Label("Scent cone (wind)", systemImage: "wind") }
            Toggle(isOn: $showRadar) { Label("Weather radar (online)", systemImage: "cloud.rain.fill") }
        } label: {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(.white)
        }
    }

    private var returnMenu: some View {
        Menu {
            Button(action: onReturnToTruck) {
                Label(hasParked ? "Back to truck" : "Back to start", systemImage: "arrow.uturn.backward")
            }.disabled(!canReturn)
            Button(action: onRetrace) {
                Label("Retrace my steps", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }.disabled(!canRetrace)
            Button(action: onMarkTruck) {
                Label("Mark truck here", systemImage: "mappin.and.ellipse")
            }
        } label: {
            Image(systemName: hasParked ? "car.fill" : "car")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(.white)
        }
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 46, height: 46)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(.white)
        }
    }

    // MARK: - Helpers

    private static let tideTimeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f
    }()

    private func tideStrip(_ t: TideService.Tide) -> some View {
        pill {
            HStack(spacing: 6) {
                Image(systemName: t.isHigh ? "arrow.up" : "arrow.down")
                Text("\(t.isHigh ? "High" : "Low") tide \(Self.tideTimeFmt.string(from: t.time))")
                Text(String(format: "%.1f ft", t.heightFt)).foregroundStyle(.cyan)
                if let s = tides.stationName {
                    Text("· \(s)").foregroundStyle(.white.opacity(0.6)).lineLimit(1).truncationMode(.tail)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 6)
    }

    private func markerCard(_ m: SelectedMarker) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: markerIcon(m.kind)).font(.title3).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.title).font(.headline).lineLimit(2)
                    Text(markerKindLabel(m.kind)).font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button { selectedMarker = nil } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.white.opacity(0.5))
                }
            }
            Button {
                onNavigateTo(NavDestination(name: m.title,
                                            latitude: m.coordinate.latitude, longitude: m.coordinate.longitude))
                selectedMarker = nil
            } label: {
                Label("Take me here", systemImage: "location.north.line.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(.cyan, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.black)
            }
        }
        .padding(14)
        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 18))
        .foregroundStyle(.white)
    }

    private func markerKindLabel(_ kind: String) -> String {
        switch kind {
        case "gauge": return "River gauge"
        case "waypoint": return "Saved spot"
        case "channelMarker": return "Channel marker"
        case "hazard": return "Hazard"
        case "launch": return "Launch / ramp"
        case "access": return "Access point"
        case "blind": return "Blind / stand"
        default: return "Marker"
        }
    }

    private func markerIcon(_ kind: String) -> String {
        switch kind {
        case "gauge": return "gauge.with.dots.needle.bottom.50percent"
        case "hazard": return "exclamationmark.triangle.fill"
        case "launch": return "ferry.fill"
        case "blind": return "scope"
        default: return "mappin.circle.fill"
        }
    }

    private func pill<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content()
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.black.opacity(0.55), in: Capsule())
    }

    private func gaugeText(_ g: WaterGauge) -> String {
        var parts: [String] = []
        if let s = g.stageFeet { parts.append(String(format: "Stage %.2f ft", s)) }
        if let c = g.dischargeCFS { parts.append(String(format: "%.0f cfs", c)) }
        return parts.joined(separator: "   ")
    }

    private var gpsText: String {
        guard let acc = location.fix?.horizontalAccuracy, acc >= 0 else { return "No GPS" }
        return String(format: "GPS %.0fm", acc)
    }
    private var gpsSymbol: String {
        guard let acc = location.fix?.horizontalAccuracy, acc >= 0 else { return "location.slash" }
        return acc <= 10 ? "location.fill" : "location"
    }
    private var gpsColor: Color {
        guard let acc = location.fix?.horizontalAccuracy, acc >= 0 else { return .red }
        if acc <= 8 { return .green }
        if acc <= 20 { return .yellow }
        return .orange
    }
}
