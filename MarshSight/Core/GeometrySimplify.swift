import Foundation
import CoreLocation
import simd

/// Douglas-Peucker line simplification. Lake shorelines and river lines from NHD
/// can carry thousands of vertices; rendering them raw (in MapKit and as AR
/// boundary segments) was a major source of lag. We simplify once, when a region
/// pack is downloaded, and render the light version forever after.
enum GeometrySimplify {

    /// Simplify a polyline/ring to the given tolerance in meters.
    static func simplify(_ points: [CLLocationCoordinate2D],
                         toleranceMeters: Double,
                         refLat: Double) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }

        let m = GeoMath.metersPerDegree(atLatitude: refLat)
        let pts = points.map { SIMD2($0.longitude * m.lonM, $0.latitude * m.latM) }

        var keep = [Bool](repeating: false, count: points.count)
        keep[0] = true
        keep[points.count - 1] = true

        var stack: [(Int, Int)] = [(0, points.count - 1)]
        while let (first, last) = stack.popLast() {
            guard last > first + 1 else { continue }
            let a = pts[first], b = pts[last]
            let ab = b - a
            let abLen2 = simd_dot(ab, ab)

            var maxDist = 0.0
            var index = first
            for i in (first + 1)..<last {
                let p = pts[i]
                let d: Double
                if abLen2 == 0 {
                    d = simd_distance(p, a)
                } else {
                    let t = max(0, min(1, simd_dot(p - a, ab) / abLen2))
                    d = simd_distance(p, a + t * ab)
                }
                if d > maxDist { maxDist = d; index = i }
            }

            if maxDist > toleranceMeters {
                keep[index] = true
                stack.append((first, index))
                stack.append((index, last))
            }
        }

        return zip(points, keep).compactMap { $1 ? $0 : nil }
    }

    static func simplify(lines: [[CLLocationCoordinate2D]],
                         toleranceMeters: Double, refLat: Double) -> [[CLLocationCoordinate2D]] {
        lines.map { simplify($0, toleranceMeters: toleranceMeters, refLat: refLat) }
    }

    static func simplify(land: PublicLand, toleranceMeters: Double, refLat: Double) -> PublicLand {
        PublicLand(id: land.id, name: land.name, managerCode: land.managerCode,
                   access: land.access,
                   rings: land.rings.map { simplify($0, toleranceMeters: toleranceMeters, refLat: refLat) })
    }
}
