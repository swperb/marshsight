import XCTest
import CoreLocation
import simd
@testable import MarshSight

/// Tests for the geospatial + AR-placement math. This is the "brain" of the AR
/// overlay (where a GPS coordinate lands in the camera world), and it can be
/// verified entirely headless - no device, no ARKit.
final class GeoMathTests: XCTestCase {

    private let origin = CLLocationCoordinate2D(latitude: 32.84, longitude: -86.71)
    private func c(_ lat: Double, _ lon: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // MARK: distance

    func testDistanceOneDegreeLongitudeAtEquator() {
        // ~111.3 km per degree of longitude at the equator.
        let d = GeoMath.distance(c(0, 0), c(0, 1))
        XCTAssertEqual(d, 111_319, accuracy: 500)
    }

    func testDistanceSymmetricAndZero() {
        let a = c(32.84, -86.71), b = c(32.85, -86.70)
        XCTAssertEqual(GeoMath.distance(a, b), GeoMath.distance(b, a), accuracy: 0.001)
        XCTAssertEqual(GeoMath.distance(a, a), 0, accuracy: 0.001)
    }

    func testDistanceShortRangeMatchesCoreLocation() {
        let a = c(32.8400, -86.7100), b = c(32.8430, -86.7060)
        let ref = CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
        XCTAssertEqual(GeoMath.distance(a, b), ref, accuracy: ref * 0.01) // within 1%
    }

    // MARK: bearing

    func testBearingCardinalDirections() {
        XCTAssertEqual(GeoMath.bearing(from: c(0, 0), to: c(1, 0)), 0, accuracy: 0.5)    // north
        XCTAssertEqual(GeoMath.bearing(from: c(0, 0), to: c(0, 1)), 90, accuracy: 0.5)   // east
        XCTAssertEqual(GeoMath.bearing(from: c(0, 0), to: c(-1, 0)), 180, accuracy: 0.5) // south
        XCTAssertEqual(GeoMath.bearing(from: c(0, 0), to: c(0, -1)), 270, accuracy: 0.5) // west
    }

    func testBearingAlwaysInRange() {
        for lat in stride(from: -1.0, through: 1.0, by: 0.5) {
            for lon in stride(from: -1.0, through: 1.0, by: 0.5) where !(lat == 0 && lon == 0) {
                let b = GeoMath.bearing(from: c(0, 0), to: c(lat, lon))
                XCTAssertTrue(b >= 0 && b < 360, "bearing \(b) out of range")
            }
        }
    }

    // MARK: ENU offset

    func testEnuOffsetDirections() {
        let east = GeoMath.enuOffset(from: origin, to: c(origin.latitude, origin.longitude + 0.001))
        XCTAssertGreaterThan(east.x, 0); XCTAssertEqual(east.y, 0, accuracy: 0.001)
        let north = GeoMath.enuOffset(from: origin, to: c(origin.latitude + 0.001, origin.longitude))
        XCTAssertGreaterThan(north.y, 0); XCTAssertEqual(north.x, 0, accuracy: 0.001)
    }

    // MARK: arPosition (the AR placement + clamping)

    func testArPositionMapsNorthToNegativeZ() {
        // gravityAndHeading: north = -z, east = +x, up = +y(0 here).
        let target = GeoMath.destination(from: origin, bearingDegrees: 0, meters: 50)
        let p = GeoMath.arPosition(of: target, from: origin, maxDistance: 120)
        XCTAssertLessThan(p.z, 0)                 // north is -z
        XCTAssertEqual(p.x, 0, accuracy: 0.5)     // due north has ~0 east
        XCTAssertEqual(p.y, 0, accuracy: 0.001)
    }

    func testArPositionMapsEastToPositiveX() {
        let target = GeoMath.destination(from: origin, bearingDegrees: 90, meters: 50)
        let p = GeoMath.arPosition(of: target, from: origin, maxDistance: 120)
        XCTAssertGreaterThan(p.x, 0)
        XCTAssertEqual(p.z, 0, accuracy: 0.5)
    }

    func testArPositionClampsFarTargets() {
        // A target 2 km away should be clamped to maxDistance in the same direction.
        let target = GeoMath.destination(from: origin, bearingDegrees: 45, meters: 2000)
        let p = GeoMath.arPosition(of: target, from: origin, maxDistance: 150)
        let mag = sqrt(p.x * p.x + p.z * p.z)
        XCTAssertEqual(Double(mag), 150, accuracy: 1.0)
    }

    func testArPositionDoesNotClampNearTargets() {
        let target = GeoMath.destination(from: origin, bearingDegrees: 45, meters: 40)
        let p = GeoMath.arPosition(of: target, from: origin, maxDistance: 150)
        let mag = sqrt(p.x * p.x + p.z * p.z)
        XCTAssertEqual(Double(mag), 40, accuracy: 1.0)   // unchanged, under the cap
    }

    // MARK: destination round-trip

    func testDestinationRoundTrip() {
        let dest = GeoMath.destination(from: origin, bearingDegrees: 120, meters: 300)
        XCTAssertEqual(GeoMath.distance(origin, dest), 300, accuracy: 1.0)
        XCTAssertEqual(GeoMath.bearing(from: origin, to: dest), 120, accuracy: 0.5)
    }

    // MARK: point in polygon

    func testPointInPolygon() {
        let square = [c(0, 0), c(0, 1), c(1, 1), c(1, 0)]
        XCTAssertTrue(GeoMath.pointInPolygon(c(0.5, 0.5), ring: square))
        XCTAssertFalse(GeoMath.pointInPolygon(c(1.5, 0.5), ring: square))
        XCTAssertFalse(GeoMath.pointInPolygon(c(0.5, -0.5), ring: square))
    }

    // MARK: relative bearing (steering)

    func testRelativeBearingWrapsShortWay() {
        XCTAssertEqual(NavigationEngine.relativeBearing(heading: 350, target: 10), 20, accuracy: 0.001)
        XCTAssertEqual(NavigationEngine.relativeBearing(heading: 10, target: 350), -20, accuracy: 0.001)
        XCTAssertEqual(NavigationEngine.relativeBearing(heading: 0, target: 180), 180, accuracy: 0.001)
        XCTAssertEqual(NavigationEngine.relativeBearing(heading: 90, target: 90), 0, accuracy: 0.001)
    }

    func testRelativeBearingAlwaysWithin180() {
        for h in stride(from: 0.0, to: 360, by: 30) {
            for t in stride(from: 0.0, to: 360, by: 30) {
                let r = NavigationEngine.relativeBearing(heading: h, target: t)
                XCTAssertTrue(r >= -180 && r <= 180, "relativeBearing \(r) out of range")
            }
        }
    }
}
