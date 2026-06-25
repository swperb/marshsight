import Foundation
import CoreLocation
import Combine

/// Turns a raw fix plus a route into the guidance numbers the HUD shows:
/// active waypoint, distance and relative bearing to it, nearby hazards, and a
/// "back to launch" bearing. Pure derivation, no UI, easy to unit test.
final class NavigationEngine: ObservableObject {

    @Published var route: NavRoute
    @Published private(set) var guidance: Guidance = .empty

    /// How close, in meters, counts as "arrived" at a waypoint.
    var arrivalRadius: Double = 20
    /// Hazards inside this radius (meters) get flagged on the HUD.
    var hazardAlertRadius: Double = 80

    private var activeIndex = 0

    struct Guidance {
        var activeWaypoint: MarkerFeature?
        var distanceToWaypoint: Double?     // meters
        var bearingToWaypoint: Double?      // true, 0..360
        var nearbyHazards: [HazardAlert]
        var bearingToLaunch: Double?
        var distanceToLaunch: Double?

        static let empty = Guidance(activeWaypoint: nil, distanceToWaypoint: nil,
                                    bearingToWaypoint: nil,
                                    nearbyHazards: [], bearingToLaunch: nil,
                                    distanceToLaunch: nil)
    }

    struct HazardAlert: Identifiable {
        var id: UUID
        var feature: MarkerFeature
        var distance: Double
    }

    init(route: NavRoute) {
        self.route = route
    }

    func update(with fix: NavFix) {
        let here = fix.coordinate
        let waypoints = route.waypoints

        // Advance the active waypoint when we arrive at the current one.
        if activeIndex < waypoints.count {
            let target = waypoints[activeIndex]
            if GeoMath.distance(here, target.coordinate) <= arrivalRadius {
                activeIndex = min(activeIndex + 1, waypoints.count)
            }
        }

        var g = Guidance.empty

        if activeIndex < waypoints.count {
            let wp = waypoints[activeIndex]
            let d = GeoMath.distance(here, wp.coordinate)
            let brg = GeoMath.bearing(from: here, to: wp.coordinate)
            g.activeWaypoint = wp
            g.distanceToWaypoint = d
            g.bearingToWaypoint = brg
        }

        g.nearbyHazards = route.features
            .filter { $0.kind == .hazard }
            .map { HazardAlert(id: $0.id, feature: $0, distance: GeoMath.distance(here, $0.coordinate)) }
            .filter { $0.distance <= hazardAlertRadius }
            .sorted { $0.distance < $1.distance }

        if let launch = route.launch {
            g.bearingToLaunch = GeoMath.bearing(from: here, to: launch.coordinate)
            g.distanceToLaunch = GeoMath.distance(here, launch.coordinate)
        }

        guidance = g
    }

    /// Signed angle (-180..180) of `target` relative to current `heading`.
    /// Negative is to the left, positive to the right.
    static func relativeBearing(heading: Double, target: Double) -> Double {
        var diff = (target - heading).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }

    func resetToStart() { activeIndex = 0 }
}
