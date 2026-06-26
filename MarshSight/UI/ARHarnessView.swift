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

            HUDOverlay(guidance: guidance,
                       fix: fix,
                       heading: 8,
                       nearestGauge: nil,
                       currentLand: nil,
                       currentParcel: nil,
                       regionName: "Coosa County")

        }
        // Harness controls pinned bottom-center, clear of the HUD's steering card
        .overlay(alignment: .bottom) {
            HStack(spacing: 10) {
                Button("BG: \(backgrounds[bg].0)") { bg = (bg + 1) % backgrounds.count }
                Button("Scenario \(scenario + 1)") { scenario = (scenario + 1) % 2 }
            }
            .font(.caption2.weight(.bold)).tint(.white)
            .padding(6).background(.purple.opacity(0.7), in: Capsule())
            .padding(.bottom, 2)
        }
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
