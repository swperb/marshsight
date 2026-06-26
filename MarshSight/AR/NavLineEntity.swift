import RealityKit
import UIKit
import simd

/// A run of flat blue chevron arrows lying on the ground in AR, marching from
/// the user toward the destination — like the direction arrows in a maps app, so
/// which way to go reads at a glance. A single merged mesh, so it is cheap.
final class NavLineEntity: Entity {

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
        guard len > 1 else { return }
        let dir = (end - start) / len
        let perp = SIMD2(-dir.y, dir.x)

        let spacing: Float = 6          // meters between chevrons
        let halfW: Float = 0.9          // chevron half-width
        let depth: Float = 1.1          // chevron length along travel
        let thick: Float = 0.5          // arm thickness
        let count = min(Int(len / spacing), 26)
        guard count >= 1 else { return }

        var positions: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        func quad(_ a: SIMD2<Float>, _ b: SIMD2<Float>, _ c: SIMD2<Float>, _ d: SIMD2<Float>) {
            let base = UInt32(positions.count)
            for p in [a, b, c, d] { positions.append(SIMD3(p.x, y, p.y)) }
            // Double-sided so it reads from any angle.
            indices += [base, base + 1, base + 2, base + 2, base + 1, base + 3]
            indices += [base + 2, base + 1, base, base + 3, base + 1, base + 2]
        }
        // A thick flat segment from p1 to p2 (one arm of a chevron).
        func segment(_ p1: SIMD2<Float>, _ p2: SIMD2<Float>) {
            let d = simd_normalize(p2 - p1)
            let n = SIMD2(-d.y, d.x) * (thick / 2)
            quad(p1 + n, p1 - n, p2 + n, p2 - n)
        }

        for i in 1...count {
            let center = start + dir * (Float(i) * spacing)
            let tip = center + dir * (depth / 2)
            let backC = center - dir * (depth / 2)
            // The two arms of a ">" pointing toward the destination.
            segment(backC + perp * halfW, tip)
            segment(backC - perp * halfW, tip)
        }
        guard !positions.isEmpty else { return }

        var desc = MeshDescriptor(name: "navchevrons")
        desc.positions = MeshBuffers.Positions(positions)
        desc.primitives = .triangles(indices)
        let material = UnlitMaterial(color: UIColor(red: 0.04, green: 0.52, blue: 1, alpha: 0.92))
        if let mesh = try? MeshResource.generate(from: [desc]) {
            addChild(ModelEntity(mesh: mesh, materials: [material]))
        }
    }
}
