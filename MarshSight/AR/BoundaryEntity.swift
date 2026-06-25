import RealityKit
import CoreLocation
import UIKit
import simd

/// Renders a public-land boundary as a single flat ribbon mesh lying on the
/// ground in AR, colored by public access. Crucially this is ONE ModelEntity per
/// land unit (a merged mesh), not one entity per segment. Hundreds of separate
/// boxes were causing the camera to stutter on every turn; a merged mesh is a
/// handful of draw calls instead.
final class BoundaryEntity: Entity {

    let landID: Int
    private let maxDistance: Double = 180     // only draw boundary within this range
    private let minSpacing: Float = 6         // meters between drawn vertices
    private let halfWidth: Float = 0.7        // ribbon half-width (meters)
    private let maxSegments = 500             // hard cap per unit

    init(land: PublicLand, origin: CLLocationCoordinate2D, groundY: Float) {
        self.landID = land.id
        super.init()
        build(land: land, origin: origin, groundY: groundY)
    }

    required init() { fatalError("init() unavailable") }

    private func build(land: PublicLand, origin: CLLocationCoordinate2D, groundY: Float) {
        let lineY = groundY + 0.06
        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var labelAnchor: SIMD3<Float>?

        for ring in land.rings {
            // Project nearby ring vertices to ground points, decimated.
            var pts: [SIMD2<Float>] = []
            var lastKept: SIMD2<Float>?
            for coord in ring {
                guard GeoMath.distance(origin, coord) <= maxDistance else { continue }
                let p = GeoMath.arPosition(of: coord, from: origin, maxDistance: maxDistance)
                let g = SIMD2(p.x, p.z)
                if let last = lastKept, simd_distance(last, g) < minSpacing { continue }
                pts.append(g)
                lastKept = g
            }
            guard pts.count >= 2 else { continue }
            if labelAnchor == nil { labelAnchor = SIMD3(pts[0].x, lineY + 2, pts[0].y) }

            for i in 0..<(pts.count - 1) {
                guard indices.count / 12 < maxSegments else { break }
                appendQuad(from: pts[i], to: pts[i + 1], y: lineY,
                           positions: &positions, indices: &indices)
            }
        }

        guard !positions.isEmpty else { return }

        var desc = MeshDescriptor(name: "boundary-\(land.id)")
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)

        let color = UIColor(land.access.color)
        let material = UnlitMaterial(color: color.withAlphaComponent(0.85))
        if let mesh = try? MeshResource.generate(from: [desc]) {
            addChild(ModelEntity(mesh: mesh, materials: [material]))
        }

        if let anchor = labelAnchor {
            addChild(boundaryLabel(text: "\(land.name)\n\(land.access.label)", at: anchor))
        }
    }

    /// Append a double-sided quad (flat on the ground) between two points.
    private func appendQuad(from a: SIMD2<Float>, to b: SIMD2<Float>, y: Float,
                            positions: inout [SIMD3<Float>], indices: inout [UInt32]) {
        let d = b - a
        let len = simd_length(d)
        guard len > 0.01 else { return }
        let dir = d / len
        let perp = SIMD2(-dir.y, dir.x) * halfWidth

        let base = UInt32(positions.count)
        positions.append(SIMD3(a.x + perp.x, y, a.y + perp.y))
        positions.append(SIMD3(a.x - perp.x, y, a.y - perp.y))
        positions.append(SIMD3(b.x + perp.x, y, b.y + perp.y))
        positions.append(SIMD3(b.x - perp.x, y, b.y - perp.y))
        // Front and back faces so it is visible from any angle.
        indices += [base, base + 1, base + 2, base + 2, base + 1, base + 3]
        indices += [base + 2, base + 1, base, base + 3, base + 1, base + 2]
    }

    private func boundaryLabel(text: String, at point: SIMD3<Float>) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text, extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.5, weight: .bold),
            containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping
        )
        let model = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .white)])
        let bounds = model.visualBounds(relativeTo: nil)
        model.position = SIMD3(point.x - bounds.extents.x / 2, point.y, point.z)
        return model
    }
}
