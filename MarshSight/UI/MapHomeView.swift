import SwiftUI
import CoreLocation

/// The home screen: a full, interactive map of the active region. This is what
/// the app opens to. The camera and AR are never started here, which keeps the
/// app private and calm on launch; you enter AR deliberately with a clear button.
struct MapHomeView: View {
    @ObservedObject var regions: RegionStore
    @ObservedObject var location: LocationProvider
    @ObservedObject var contributions: ContributionStore

    let nearestGauge: WaterGauge?
    let currentLand: PublicLand?
    let currentParcel: Parcel?
    let weather: Weather?

    var onEnterAR: () -> Void
    var onReport: () -> Void
    var onSwitchRegion: () -> Void

    var body: some View {
        ZStack {
            RegionMapView(region: regions.active,
                          track: location.track,
                          contributionMarkers: contributions.markers,
                          interactive: true)
                .equatable()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if weather != nil { weatherStrip }
                Spacer()
                contextCard
                enterARButton
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            sideButtons
        }
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
        }
        .padding(.top, 8)
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
            if let land = currentLand {
                contextRow(color: land.access.color, icon: "leaf.fill",
                           title: land.name, sub: "\(land.access.label)  -  \(land.manager)")
            } else if let parcel = currentParcel {
                contextRow(color: .orange, icon: "house.lodge.fill",
                           title: "Private Land",
                           sub: parcel.owner.map { "Owner: \($0)" } ?? "Owner not listed")
            }
            if let g = nearestGauge {
                contextRow(color: .teal, icon: "gauge.with.dots.needle.bottom.50percent",
                           title: g.name,
                           sub: gaugeText(g))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 12)
        .opacity(currentLand == nil && currentParcel == nil && nearestGauge == nil ? 0 : 1)
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
                Text("Look Around in AR").font(.headline)
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
            circleButton(icon: "plus", action: onReport)
            circleButton(icon: "location.fill.viewfinder", action: {})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 14)
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
