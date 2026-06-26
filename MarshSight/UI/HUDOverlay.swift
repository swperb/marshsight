import SwiftUI

/// The heads-up layer drawn over the camera: active waypoint, a steering arrow,
/// speed and GPS quality, hazard alerts, and a return-to-launch readout.
struct HUDOverlay: View {

    let guidance: NavigationEngine.Guidance
    let fix: NavFix?
    var heading: Double = 0
    var nearestGauge: WaterGauge?
    var currentLand: PublicLand?
    var currentParcel: Parcel?
    var regionName: String?

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let land = currentLand { landBanner(land) }
            else if let parcel = currentParcel { parcelBanner(parcel) }
            if nearestGauge != nil { stageBanner }
            Spacer()
            hazardStack
            if guidance.activeWaypoint != nil { steeringCard }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .overlay(alignment: .leading) { if offscreen == .left { edgeChevron(left: true) } }
        .overlay(alignment: .trailing) { if offscreen == .right { edgeChevron(left: false) } }
    }

    /// When the destination is outside the camera's view, point the user which
    /// way to turn. nil means it's roughly ahead.
    private enum Side { case left, right }
    private var offscreen: Side? {
        guard guidance.activeWaypoint != nil else { return nil }
        let b = relativeBearing
        guard abs(b) > 32 else { return nil }
        return b < 0 ? .left : .right
    }

    private func edgeChevron(left: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: left ? "chevron.compact.left" : "chevron.compact.right")
                .font(.system(size: 64, weight: .black))
            Text("Turn").font(.caption.weight(.bold))
        }
        .foregroundStyle(.cyan)
        .shadow(color: .black.opacity(0.6), radius: 3)
        .padding(left ? .leading : .trailing, 2)
    }

    // MARK: - Top bar: speed + GPS quality

    private var topBar: some View {
        HStack {
            pill {
                Label(speedText, systemImage: "speedometer")
            }
            if let regionName, !regionName.isEmpty {
                pill {
                    Label(regionName, systemImage: "square.stack.3d.up.fill")
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            pill {
                Label(gpsText, systemImage: gpsSymbol)
                    .foregroundStyle(gpsColor)
            }
        }
    }

    // MARK: - Current public land

    private func landBanner(_ land: PublicLand) -> some View {
        HStack(spacing: 8) {
            Circle().fill(land.access.color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(land.name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Text("\(land.access.label)  -  \(land.manager)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(land.access.color, lineWidth: 1.5))
        .padding(.top, 8)
    }

    // MARK: - Current private parcel (owner lookup)

    private func parcelBanner(_ parcel: Parcel) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "house.lodge.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text("Private Land")
                    .font(.subheadline.weight(.bold))
                Text(parcel.owner.map { "Owner: \($0)" } ?? "Owner not listed")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.orange, lineWidth: 1.5))
        .padding(.top, 8)
    }

    // MARK: - Live river stage

    private var stageBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
            VStack(alignment: .leading, spacing: 1) {
                Text(nearestGauge?.name ?? "")
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 10) {
                    if let stage = nearestGauge?.stageFeet {
                        Text(String(format: "Stage %.2f ft", stage)).monospacedDigit()
                    }
                    if let cfs = nearestGauge?.dischargeCFS {
                        Text(String(format: "%.0f cfs", cfs)).monospacedDigit()
                    }
                }
                .font(.caption.weight(.bold))
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.teal.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
        .padding(.top, 8)
    }

    // MARK: - Hazard alerts

    private var hazardStack: some View {
        VStack(spacing: 6) {
            ForEach(guidance.nearbyHazards.prefix(3)) { alert in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(alert.feature.name)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(Fmt.distance(alert.distance))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.85), in: Capsule())
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Steering card

    private var steeringCard: some View {
        HStack(spacing: 16) {
            steeringArrow
            VStack(alignment: .leading, spacing: 2) {
                Text(guidance.activeWaypoint?.name ?? "Route complete")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(turnHint.text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(turnHint.color)
                if let d = guidance.distanceToWaypoint {
                    Text("\(Fmt.distance(d)) away")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .monospacedDigit()
                }
                if let launchD = guidance.distanceToLaunch {
                    Text("Launch \(Fmt.distance(launchD))")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .monospacedDigit()
                }
            }
            Spacer()
        }
        .padding(14)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))
    }

    /// Turn guidance from how far off the destination is from where you face.
    private var turnHint: (text: String, color: Color) {
        let a = abs(relativeBearing)
        if a <= 18 { return ("Straight ahead", .green) }
        if a >= 150 { return ("Turn around", .red) }
        if a >= 60 { return (relativeBearing < 0 ? "Turn left" : "Turn right", .orange) }
        return (relativeBearing < 0 ? "Bear left" : "Bear right", .yellow)
    }

    private var steeringArrow: some View {
        ZStack {
            Circle().fill(.black.opacity(0.4))
            Circle().stroke(.white.opacity(0.3), lineWidth: 1)
            Image(systemName: "location.north.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(turnHint.color)
                .rotationEffect(.degrees(relativeBearing))
        }
        .frame(width: 64, height: 64)
    }

    // MARK: - Helpers

    private func pill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.5), in: Capsule())
    }

    private var relativeBearing: Double {
        guard let target = guidance.bearingToWaypoint else { return 0 }
        return NavigationEngine.relativeBearing(heading: heading, target: target)
    }

    private var speedText: String {
        guard let mps = fix?.speedMetersPerSecond else { return "-- mph" }
        return String(format: "%.1f mph", mps * 2.23694)
    }

    private var gpsText: String {
        guard let acc = fix?.horizontalAccuracy, acc >= 0 else { return "No GPS" }
        return String(format: "GPS %.0fm", acc)
    }

    private var gpsSymbol: String {
        guard let acc = fix?.horizontalAccuracy, acc >= 0 else { return "location.slash" }
        return acc <= 10 ? "location.fill" : "location"
    }

    private var gpsColor: Color {
        guard let acc = fix?.horizontalAccuracy, acc >= 0 else { return .red }
        if acc <= 8 { return .green }
        if acc <= 20 { return .yellow }
        return .orange
    }
}
