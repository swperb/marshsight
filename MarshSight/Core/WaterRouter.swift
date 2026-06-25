import Foundation
import CoreLocation

/// Off-road, water-aware routing. For a boat on a lake, a straight line can run
/// across a point or a peninsula; this routes a path that stays on the water by
/// running A* over a grid of the lake. For land (neither end on water) it
/// returns nil and the caller uses a straight line. This is deliberately not
/// road-based: it never snaps to streets.
enum WaterRouter {

    /// Returns a path from `from` to `to` that stays on water (including both
    /// endpoints), or nil if water routing does not apply or no path is found.
    static func route(from: CLLocationCoordinate2D,
                      to: CLLocationCoordinate2D,
                      lakes: [[CLLocationCoordinate2D]]) -> [CLLocationCoordinate2D]? {
        guard !lakes.isEmpty else { return nil }
        let inWater: (CLLocationCoordinate2D) -> Bool = { c in
            lakes.contains { GeoMath.pointInPolygon(c, ring: $0) }
        }
        // Only route on water when at least one endpoint is on a lake.
        guard inWater(from) || inWater(to) else { return nil }

        // Grid over the bounding box of the two points, with margin.
        let minLat = min(from.latitude, to.latitude), maxLat = max(from.latitude, to.latitude)
        let minLon = min(from.longitude, to.longitude), maxLon = max(from.longitude, to.longitude)
        let mLat = max((maxLat - minLat) * 0.25, 0.003)
        let mLon = max((maxLon - minLon) * 0.25, 0.003)
        let south = minLat - mLat, north = maxLat + mLat
        let west = minLon - mLon, east = maxLon + mLon

        let dim = 56
        let rows = dim, cols = dim
        let dLat = (north - south) / Double(rows)
        let dLon = (east - west) / Double(cols)
        func center(_ r: Int, _ c: Int) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: south + (Double(r) + 0.5) * dLat,
                                   longitude: west + (Double(c) + 0.5) * dLon)
        }
        func cell(_ p: CLLocationCoordinate2D) -> (Int, Int) {
            let r = min(rows - 1, max(0, Int((p.latitude - south) / dLat)))
            let c = min(cols - 1, max(0, Int((p.longitude - west) / dLon)))
            return (r, c)
        }

        // Water mask.
        var water = [[Bool]](repeating: [Bool](repeating: false, count: cols), count: rows)
        for r in 0..<rows { for c in 0..<cols { water[r][c] = inWater(center(r, c)) } }

        // Snap endpoints to the nearest water cell (BFS) if they are not on water.
        func nearestWater(_ start: (Int, Int)) -> (Int, Int)? {
            if water[start.0][start.1] { return start }
            var seen = Set<Int>(); var q = [start]; seen.insert(start.0 * cols + start.1)
            var head = 0
            while head < q.count {
                let (r, c) = q[head]; head += 1
                if water[r][c] { return (r, c) }
                for (dr, dc) in [(-1,0),(1,0),(0,-1),(0,1)] {
                    let nr = r + dr, nc = c + dc
                    guard nr >= 0, nr < rows, nc >= 0, nc < cols else { continue }
                    let key = nr * cols + nc
                    if !seen.contains(key) { seen.insert(key); q.append((nr, nc)) }
                }
            }
            return nil
        }
        guard let start = nearestWater(cell(from)), let goal = nearestWater(cell(to)) else { return nil }

        // A* over water cells (8-connectivity).
        func h(_ r: Int, _ c: Int) -> Double { GeoMath.distance(center(r, c), center(goal.0, goal.1)) }
        var gScore = [[Double]](repeating: [Double](repeating: .greatestFiniteMagnitude, count: cols), count: rows)
        var came = [[Int]](repeating: [Int](repeating: -1, count: cols), count: rows)
        gScore[start.0][start.1] = 0
        var open: [(f: Double, r: Int, c: Int)] = [(h(start.0, start.1), start.0, start.1)]
        var closed = Set<Int>()
        var found = false
        var iterations = 0

        while !open.isEmpty {
            iterations += 1
            if iterations > rows * cols * 2 { break }
            // Pop lowest f (linear scan; grid is small).
            var bi = 0
            for i in 1..<open.count where open[i].f < open[bi].f { bi = i }
            let cur = open.remove(at: bi)
            if cur.r == goal.0 && cur.c == goal.1 { found = true; break }
            let key = cur.r * cols + cur.c
            if closed.contains(key) { continue }
            closed.insert(key)
            for (dr, dc) in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)] {
                let nr = cur.r + dr, nc = cur.c + dc
                guard nr >= 0, nr < rows, nc >= 0, nc < cols, water[nr][nc] else { continue }
                let tentative = gScore[cur.r][cur.c] + GeoMath.distance(center(cur.r, cur.c), center(nr, nc))
                if tentative < gScore[nr][nc] {
                    gScore[nr][nc] = tentative
                    came[nr][nc] = key
                    open.append((tentative + h(nr, nc), nr, nc))
                }
            }
        }
        guard found else { return nil }

        // Reconstruct, simplify, and bookend with the real endpoints.
        var path: [CLLocationCoordinate2D] = []
        var r = goal.0, c = goal.1
        while !(r == start.0 && c == start.1) {
            path.append(center(r, c))
            let prev = came[r][c]
            if prev < 0 { break }
            r = prev / cols; c = prev % cols
        }
        path.append(center(start.0, start.1))
        path.reverse()

        let refLat = (south + north) / 2
        let simplified = GeometrySimplify.simplify(path, toleranceMeters: 25, refLat: refLat)
        let middle = simplified.count > 2 ? Array(simplified[1..<(simplified.count - 1)]) : []
        return [from] + middle + [to]
    }
}
