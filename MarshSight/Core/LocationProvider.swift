import Foundation
import CoreLocation
import Combine

/// Wraps CoreLocation and publishes a fused NavFix (position + true heading).
/// On murky water there is no Apple VPS to lean on, so GPS and the magnetometer
/// are the whole story. We surface accuracy so the UI can warn when the fix is weak.
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var fix: NavFix?
    /// Published separately from `fix` so heading-only changes (turning the
    /// phone) do not retrigger coordinate-dependent work.
    @Published var heading: Double = 0
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    /// A breadcrumb trail of recent positions, used for the return-to-launch track.
    @Published private(set) var track: [CLLocationCoordinate2D] = []

    private let manager = CLLocationManager()
    private var lastCoordinate: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        // Best (not BestForNavigation) is plenty accurate for this and draws far
        // less power. Wider filters cut the update rate that drives UI redraws.
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 4
        manager.headingFilter = 4
        manager.activityType = .otherNavigation
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func resetTrack() {
        track.removeAll()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            manager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastCoordinate = loc.coordinate
        publishFix(from: loc)

        // Append to breadcrumb track when we have moved a meaningful amount.
        if let last = track.last {
            let moved = GeoMath.distance(last, loc.coordinate)
            if moved >= 3 { track.append(loc.coordinate) }
        } else {
            track.append(loc.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer true heading when the magnetometer is calibrated; fall back to magnetic.
        // Publishes only `heading`; does NOT republish the full fix.
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    private func publishFix(from loc: CLLocation) {
        fix = NavFix(
            coordinate: loc.coordinate,
            speedMetersPerSecond: max(0, loc.speed),
            horizontalAccuracy: loc.horizontalAccuracy,
            timestamp: loc.timestamp
        )
    }
}
