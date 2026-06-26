import SwiftUI
import CoreLocation

/// A device-free harness for iterating on the AR heads-up layer. It renders the
/// real `HUDOverlay` (the SwiftUI part of the AR view) over stand-in camera
/// backgrounds with mock navigation data, so the overlay's layout, contrast,
/// Dynamic Type behavior, and VoiceOver structure can be reviewed in the
/// Simulator without ARKit or a real device.
///
/// Reached only when the app is launched with the "ARHARNESS" argument
/// (see App.swift). Never part of the normal app.
struct ARHarnessView: View {
    @State private var bg = 0
    @State private var scenario = 0
    @State private var heading: Double = 20      // facing direction, pannable

    // Mock markers around a fixed origin, placed by true bearing + distance.
    private let markerOrigin = CLLocationCoordinate2D(latitude: 32.84, longitude: -86.71)
    private var mockMarkers: [(name: String, hazard: Bool, coord: CLLocationCoordinate2D)] {
        [("North Stand", false, GeoMath.destination(from: markerOrigin, bearingDegrees: 20, meters: 300)),
         ("Submerged stump", true, GeoMath.destination(from: markerOrigin, bearingDegrees: 62, meters: 70)),
         ("Boat Launch", false, GeoMath.destination(from: markerOrigin, bearingDegrees: 205, meters: 600)),
         ("Feeder", false, GeoMath.destination(from: markerOrigin, bearingDegrees: 332, meters: 180))]
    }
    private let fov: Double = 64                  // horizontal field of view, degrees

    // Stand-in "camera" backgrounds, worst-cases first (bright sky blows out
    // white text; dark timber hides shadows).
    private let backgrounds: [(String, [Color])] = [
        ("Bright sky", [Color(white: 0.95), Color(white: 0.75)]),
        ("Open water", [Color(hex: "7FA9B8"), Color(hex: "3C5A66")]),
        ("Timber / dusk", [Color(hex: "21301F"), Color(hex: "0B130C")]),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: backgrounds[bg].1, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            markerLayer

            HUDOverlay(guidance: guidance,
                       fix: fix,
                       heading: heading,
                       nearestGauge: nil,
                       currentLand: nil,
                       currentParcel: nil,
                       regionName: "Coosa County")

        }
        // Harness controls pinned bottom-center, clear of the HUD's steering card
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Button("BG") { bg = (bg + 1) % backgrounds.count }
                Button("Scenario") { scenario = (scenario + 1) % 2 }
                Button("Pan -") { heading = (heading - 20).truncatingRemainder(dividingBy: 360) }
                Text("hdg \(Int((heading + 360).truncatingRemainder(dividingBy: 360)))°")
                Button("Pan +") { heading = (heading + 20).truncatingRemainder(dividingBy: 360) }
            }
            .font(.caption2.weight(.bold)).tint(.white)
            .padding(6).background(.purple.opacity(0.7), in: Capsule())
            .padding(.bottom, 2)
        }
    }

    /// Projects the mock markers onto the "windshield" using true bearing vs.
    /// heading (horizontal) and distance (size). Markers outside the field of
    /// view are dropped - the HUD's edge chevron handles off-screen direction.
    /// Reuses the unit-tested GeoMath, so this mirrors real AR placement.
    private var markerLayer: some View {
        GeometryReader { geo in
            ForEach(mockMarkers, id: \.name) { m in
                let bearing = GeoMath.bearing(from: markerOrigin, to: m.coord)
                let rel = NavigationEngine.relativeBearing(heading: heading, target: bearing)
                if abs(rel) <= fov / 2 {
                    let dist = GeoMath.distance(markerOrigin, m.coord)
                    let x = geo.size.width / 2 + CGFloat(rel / (fov / 2)) * (geo.size.width / 2 - 40)
                    let size = max(16.0, 60.0 - dist / 12)   // closer = bigger
                    VStack(spacing: 3) {
                        Image(systemName: m.hazard ? "exclamationmark.triangle.fill" : "mappin.circle.fill")
                            .font(.system(size: size))
                            .foregroundStyle(m.hazard ? .red : .cyan)
                            .shadow(color: .black.opacity(0.6), radius: 2)
                        Text("\(m.name)  ·  \(Fmt.distance(dist))")
                            .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(.black.opacity(0.5), in: Capsule())
                    }
                    .position(x: x, y: geo.size.height * 0.42)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var fix: NavFix {
        NavFix(coordinate: .init(latitude: 32.84, longitude: -86.71),
               speedMetersPerSecond: scenario == 0 ? 2.1 : 0,
               horizontalAccuracy: scenario == 0 ? 6 : 24,
               timestamp: .init(timeIntervalSince1970: 1_700_000_000))
    }

    private var guidance: NavigationEngine.Guidance {
        let dest = MarkerFeature(kind: .waypoint, name: "North Stand",
                                 latitude: 32.842, longitude: -86.709)
        let hazard = NavigationEngine.HazardAlert(
            id: UUID(),
            feature: MarkerFeature(kind: .hazard, name: "Submerged stump", latitude: 32.841, longitude: -86.710),
            distance: 58)
        return NavigationEngine.Guidance(
            activeWaypoint: dest,
            distanceToWaypoint: scenario == 0 ? 412 : 1180,
            bearingToWaypoint: scenario == 0 ? 48 : 300,
            nearbyHazards: scenario == 0 ? [hazard] : [],
            bearingToLaunch: 210,
            distanceToLaunch: 1340)
    }
}
