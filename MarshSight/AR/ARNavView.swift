import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import Combine

/// SwiftUI wrapper around a RealityKit ARView that draws navigation markers
/// floating in the real world. The trick that makes this work off-grid: we run
/// the session with `worldAlignment = .gravityAndHeading`, so the AR world axes
/// line up with true geographic directions. We can then place any GPS coordinate
/// at a known offset from the camera without Apple geo-anchors.
struct ARNavView: UIViewRepresentable {

    var features: [MarkerFeature]
    var fix: NavFix?
    var publicLands: [PublicLand] = []
    var regionToken: String = ""

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        // Turn off the expensive cinematic render passes. None of them help a
        // navigation overlay, and together they were the main source of GPU heat.
        arView.renderOptions = [
            .disableMotionBlur, .disableDepthOfField, .disableHDR,
            .disableCameraGrain, .disablePersonOcclusion,
            .disableGroundingShadows, .disableAREnvironmentLighting,
            .disableFaceMesh
        ]
        arView.environment.sceneUnderstanding.options = []

        let config = ARWorldTrackingConfiguration()
        config.worldAlignment = .gravityAndHeading
        config.planeDetection = []
        config.environmentTexturing = .none
        config.frameSemantics = []
        arView.session.run(config)

        let root = AnchorEntity(world: .zero)
        arView.scene.addAnchor(root)
        context.coordinator.root = root
        context.coordinator.arView = arView

        // Billboard labels toward the camera, but only a few times per second.
        context.coordinator.updateSub = arView.scene.subscribe(to: SceneEvents.Update.self) { _ in
            context.coordinator.tickBillboard()
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.sync(features: features, fix: fix)
        context.coordinator.syncBoundaries(lands: publicLands, fix: fix, regionToken: regionToken)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        coordinator.updateSub?.cancel()
    }

    // MARK: - Coordinator

    final class Coordinator {
        var arView: ARView?
        var root: AnchorEntity?
        var updateSub: Cancellable?

        private var entities: [UUID: MarkerEntity] = [:]
        private var boundaries: [Int: BoundaryEntity] = [:]

        private var lastSyncOrigin: CLLocationCoordinate2D?
        private var lastFeatureIDs: Set<UUID> = []
        private var lastBoundaryOrigin: CLLocationCoordinate2D?
        private var lastRegionToken = ""
        private var frame = 0

        // Only do real work when the user has actually moved a little.
        private let markerMoveThreshold: Double = 2.5     // meters
        private let boundaryMoveThreshold: Double = 12     // meters
        private let boundaryRange: Double = 400            // only build nearby land

        func sync(features: [MarkerFeature], fix: NavFix?) {
            guard let root, let fix else { return }
            let origin = fix.coordinate
            let ids = Set(features.map { $0.id })

            let moved = lastSyncOrigin.map { GeoMath.distance($0, origin) } ?? .greatestFiniteMagnitude
            // Skip if neither the feature set nor our position changed meaningfully.
            // ARKit keeps existing markers world-fixed in the meantime.
            guard lastSyncOrigin == nil || moved > markerMoveThreshold || ids != lastFeatureIDs else {
                return
            }
            lastSyncOrigin = origin
            lastFeatureIDs = ids

            let cameraPos = arView?.cameraTransform.translation ?? .zero

            for (id, entity) in entities where !ids.contains(id) {
                entity.removeFromParent()
                entities[id] = nil
            }

            for feature in features {
                let offset = GeoMath.arPosition(of: feature.coordinate, from: origin)
                let distance = GeoMath.distance(origin, feature.coordinate)
                let worldPos = SIMD3<Float>(cameraPos.x + offset.x,
                                            cameraPos.y - 0.3,
                                            cameraPos.z + offset.z)

                if let existing = entities[feature.id] {
                    existing.position = worldPos
                    existing.update(distance: distance)
                } else {
                    let marker = MarkerEntity(feature: feature)
                    marker.position = worldPos
                    marker.update(distance: distance)
                    root.addChild(marker)
                    entities[feature.id] = marker
                }
            }
        }

        /// Rebuild boundary lines only when the region changes or we move far
        /// enough. The cheap movement/token gate runs FIRST, so the expensive
        /// "which units are nearby" scan only happens on an actual rebuild.
        func syncBoundaries(lands: [PublicLand], fix: NavFix?, regionToken: String) {
            guard let root, let fix, let arView else { return }
            let origin = fix.coordinate
            let moved = lastBoundaryOrigin.map { GeoMath.distance($0, origin) } ?? .greatestFiniteMagnitude
            let regionChanged = regionToken != lastRegionToken
            guard lastBoundaryOrigin == nil || regionChanged || moved > boundaryMoveThreshold else {
                return
            }

            // Now that we are actually rebuilding, do the nearby scan once.
            let nearby = lands.filter { land in
                land.rings.contains { ring in
                    ring.contains { GeoMath.distance(origin, $0) <= boundaryRange }
                }
            }

            for entity in boundaries.values { entity.removeFromParent() }
            boundaries.removeAll()

            let groundY = arView.cameraTransform.translation.y - 1.5
            for land in nearby {
                let entity = BoundaryEntity(land: land, origin: origin, groundY: groundY)
                root.addChild(entity)
                boundaries[land.id] = entity
            }
            lastBoundaryOrigin = origin
            lastRegionToken = regionToken
        }

        /// Billboard at roughly 10 fps rather than every frame.
        func tickBillboard() {
            frame &+= 1
            guard frame % 6 == 0, let arView else { return }
            let cam = arView.cameraTransform.translation
            for entity in entities.values { entity.billboard(toward: cam) }
        }
    }
}
