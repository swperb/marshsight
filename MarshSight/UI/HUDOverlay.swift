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
            steeringCard
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 16)
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
                    Text("\(Int(alert.distance * 1.09361)) yd")
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
                if let d = guidance.distanceToWaypoint {
                    Text("\(Int(d * 1.09361)) yd ahead")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .monospacedDigit()
                }
                if let launchD = guidance.distanceToLaunch {
                    Text("Launch \(Int(launchD * 1.09361)) yd")
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

    private var steeringArrow: some View {
        ZStack {
            Circle().fill(.black.opacity(0.4))
            Circle().stroke(.white.opacity(0.3), lineWidth: 1)
            Image(systemName: "location.north.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.cyan)
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
