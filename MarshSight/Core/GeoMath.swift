import Foundation
import CoreLocation
import simd

/// Geospatial helpers for converting between WGS84 coordinates and a local
/// East-North-Up (ENU) tangent plane centered on the device. This is what lets
/// us place markers in AR space without Apple's geo-anchors, which do not work
/// on open water or under forest canopy.
enum GeoMath {

    static let earthRadius = 6_378_137.0 // meters, WGS84 semi-major axis

    /// Meters per degree of latitude and longitude at a given latitude.
    static func metersPerDegree(atLatitude lat: Double) -> (latM: Double, lonM: Double) {
        let latRad = lat * .pi / 180
        // Standard ellipsoidal approximations, accurate to a few cm over short ranges.
        let latM = 111_132.92 - 559.82 * cos(2 * latRad) + 1.175 * cos(4 * latRad)
        let lonM = 111_412.84 * cos(latRad) - 93.5 * cos(3 * latRad)
        return (latM, lonM)
    }

    /// Offset of `target` from `origin` in local meters: x = east, y = north.
    static func enuOffset(from origin: CLLocationCoordinate2D,
                          to target: CLLocationCoordinate2D) -> SIMD2<Double> {
        let m = metersPerDegree(atLatitude: origin.latitude)
        let east = (target.longitude - origin.longitude) * m.lonM
        let north = (target.latitude - origin.latitude) * m.latM
        return SIMD2(east, north)
    }

    /// Great-circle distance in meters between two coordinates (haversine).
    static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }

    /// Initial bearing from `a` to `b` in degrees clockwise from true north (0..360).
    static func bearing(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let deg = atan2(y, x) * 180 / .pi
        return (deg + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Ray-casting point-in-polygon test in lon/lat space. Good enough at the
    /// scale of a single land unit, where the flat-earth error is negligible.
    static func pointInPolygon(_ p: CLLocationCoordinate2D, ring: [CLLocationCoordinate2D]) -> Bool {
        guard ring.count > 2 else { return false }
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let a = ring[i], b = ring[j]
            if (a.latitude > p.latitude) != (b.latitude > p.latitude) {
                let slope = (p.latitude - a.latitude) / (b.latitude - a.latitude)
                let x = a.longitude + slope * (b.longitude - a.longitude)
                if p.longitude < x { inside.toggle() }
            }
            j = i
        }
        return inside
    }

    /// Position of a geographic coordinate in the ARKit world frame.
    ///
    /// Requires `ARWorldTrackingConfiguration.worldAlignment = .gravityAndHeading`,
    /// which aligns the world so +x points geographic east and -z points geographic
    /// north (y is up). We clamp the placement distance so far targets render at a
    /// readable range on the horizon rather than kilometers away.
    static func arPosition(of target: CLLocationCoordinate2D,
                           from origin: CLLocationCoordinate2D,
                           maxDistance: Double = 120) -> SIMD3<Float> {
        let enu = enuOffset(from: origin, to: target)
        let east = enu.x
        let north = enu.y
        let dist = sqrt(east * east + north * north)
        let scale = dist > maxDistance ? maxDistance / dist : 1.0
        // ARKit gravityAndHeading: east = +x, north = -z, up = +y.
        return SIMD3(Float(east * scale), 0, Float(-north * scale))
    }
}
