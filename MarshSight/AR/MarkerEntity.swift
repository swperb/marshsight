import RealityKit
import UIKit
import simd

/// A single navigation marker rendered in AR: a colored beacon sphere, a thin
/// post dropping toward the water, and a floating text label with the feature
/// name, depth, and live distance. The label billboards toward the camera.
final class MarkerEntity: Entity {

    private let feature: MarkerFeature
    private let labelAnchor = Entity()
    private var labelModel: ModelEntity?
    private var lastDistanceBucket: Int = -1

    init(feature: MarkerFeature) {
        self.feature = feature
        super.init()
        buildBeacon()
        addChild(labelAnchor)
        labelAnchor.position = [0, 1.2, 0]
        rebuildLabel(distanceText: "")
    }

    required init() { fatalError("init() unavailable") }

    private func buildBeacon() {
        let color = UIColor(feature.kind.tint)

        // Beacon sphere.
        var mat = UnlitMaterial(color: color)
        mat.color = .init(tint: color.withAlphaComponent(0.95))
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.4), materials: [mat])
        addChild(sphere)

        // Post dropping toward the surface so the marker reads as grounded.
        let post = ModelEntity(mesh: .generateBox(width: 0.05, height: 1.2, depth: 0.05),
                               materials: [UnlitMaterial(color: color.withAlphaComponent(0.6))])
        post.position = [0, -0.6, 0]
        addChild(post)
    }

    /// Update only when the displayed distance changes by a meaningful step.
    /// Generating a text mesh is expensive, so we bucket to ~10 m to avoid
    /// rebuilding labels on every GPS jitter.
    func update(distance: Double) {
        let bucket = Int((distance / 10).rounded())
        guard bucket != lastDistanceBucket else { return }
        lastDistanceBucket = bucket
        rebuildLabel(distanceText: Self.format(distance: distance))
    }

    private func rebuildLabel(distanceText: String) {
        labelModel?.removeFromParent()

        var line = feature.name
        if let depth = feature.depthFeet {
            line += String(format: "  %.1f ft", depth)
        }
        if !distanceText.isEmpty {
            line += "\n" + distanceText
        }

        let mesh = MeshResource.generateText(
            line,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.3, weight: .semibold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let mat = UnlitMaterial(color: .white)
        let model = ModelEntity(mesh: mesh, materials: [mat])
        // Center the generated text on its anchor.
        let bounds = model.visualBounds(relativeTo: nil)
        model.position = [-bounds.extents.x / 2, 0, 0]
        labelAnchor.addChild(model)
        labelModel = model
    }

    /// Rotate the label to face the camera (yaw only, so text stays upright).
    func billboard(toward cameraWorldPosition: SIMD3<Float>) {
        let labelWorld = labelAnchor.position(relativeTo: nil)
        let dx = cameraWorldPosition.x - labelWorld.x
        let dz = cameraWorldPosition.z - labelWorld.z
        let yaw = atan2(dx, dz)
        labelAnchor.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
    }

    private static func format(distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        }
        // Yards are the working unit for hunters and boaters in the US.
        let yards = distance * 1.09361
        return String(format: "%.0f yd", yards)
    }
}
