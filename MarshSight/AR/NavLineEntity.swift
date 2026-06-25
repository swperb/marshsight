import RealityKit
import UIKit
import simd

/// A blue trackline lying on the water in AR, running from the user toward the
/// destination (Apple-Maps style). A single merged ribbon mesh, so it is cheap.
final class NavLineEntity: Entity {

    private let width: Float = 1.6

    /// `end` is the destination's position relative to the user, on the ground
    /// plane (x = east-ish, z = north-ish), already clamped to a sane range.
    init(end: SIMD2<Float>, y: Float) {
        super.init()
        build(end: end, y: y)
    }

    required init() { fatalError("init() unavailable") }

    private func build(end: SIMD2<Float>, y: Float) {
        let start = SIMD2<Float>(0, 0)
        let len = simd_length(end - start)
        guard len > 0.5 else { return }
        let dir = (end - start) / len
        let perp = SIMD2(-dir.y, dir.x) * (width / 2)

        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        // Subdivide so the ribbon reads as a path, with small gaps as chevrons.
        let segs = max(1, Int(min(len, 200) / 8))
        for i in 0..<segs {
            let t0 = Float(i) / Float(segs)
            let t1 = (Float(i) + 0.6) / Float(segs)   // 0.6 leaves a gap = dashed
            let a = start + (end - start) * t0
            let b = start + (end - start) * t1
            let base = UInt32(positions.count)
            positions.append(SIMD3(a.x + perp.x, y, a.y + perp.y))
            positions.append(SIMD3(a.x - perp.x, y, a.y - perp.y))
            positions.append(SIMD3(b.x + perp.x, y, b.y + perp.y))
            positions.append(SIMD3(b.x - perp.x, y, b.y - perp.y))
            indices += [base, base + 1, base + 2, base + 2, base + 1, base + 3]
            indices += [base + 2, base + 1, base, base + 3, base + 1, base + 2]
        }
        guard !positions.isEmpty else { return }

        var desc = MeshDescriptor(name: "navline")
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)
        let material = UnlitMaterial(color: UIColor(red: 0.04, green: 0.52, blue: 1, alpha: 0.95))
        if let mesh = try? MeshResource.generate(from: [desc]) {
            addChild(ModelEntity(mesh: mesh, materials: [material]))
        }
    }
}
