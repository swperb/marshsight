import SwiftUI
import RealityKit
import ARKit
import CoreLocation
import Combine
import os

/// Live AR diagnostics, mirrored to os_log (readable over the wire with
/// `log stream`/Console) and to an on-screen debug HUD. Enable with the
/// "ARDEBUG" launch argument or by setting the "arDebug" default.
final class ARDebugStats: ObservableObject {
    static let shared = ARDebugStats()
    static let log = Logger(subsystem: "com.marshsight.app", category: "ar")
    @Published var tracking = "starting"
    @Published var markers = 0
    @Published var boundaries = 0
    @Published var fps = 0
    @Published var note = ""

    static var enabled: Bool {
        ProcessInfo.processInfo.arguments.contains("ARDEBUG")
            || UserDefaults.standard.bool(forKey: "arDebug")
    }

    /// AR delegate callbacks arrive off the main thread; hop to main so SwiftUI
    /// and @Published stay happy.
    func set(_ apply: @escaping (ARDebugStats) -> Void) {
        if Thread.isMainThread { apply(self) }
        else { DispatchQueue.main.async { apply(self) } }
    }
}

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
    var destination: CLLocationCoordinate2D? = nil

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
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        ARDebugStats.log.info("AR session started (gravityAndHeading)")

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
        context.coordinator.syncNavLine(destination: destination, fix: fix)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
        coordinator.updateSub?.cancel()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var root: AnchorEntity?
        var updateSub: Cancellable?
        private var fpsWindowStart = CACurrentMediaTime()
        private var fpsCount = 0

        // MARK: ARSessionDelegate

        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            let desc: String
            switch camera.trackingState {
            case .normal: desc = "normal"
            case .notAvailable: desc = "not available"
            case .limited(let reason):
                switch reason {
                case .initializing: desc = "limited: initializing"
                case .excessiveMotion: desc = "limited: too much motion"
                case .insufficientFeatures: desc = "limited: low detail / glare"
                case .relocalizing: desc = "limited: relocalizing"
                @unknown default: desc = "limited"
                }
            @unknown default: desc = "unknown"
            }
            ARDebugStats.log.info("tracking: \(desc, privacy: .public)")
            ARDebugStats.shared.set { $0.tracking = desc }
        }

        func session(_ session: ARSession, didFailWithError error: Error) {
            ARDebugStats.log.error("session failed: \(error.localizedDescription, privacy: .public)")
            ARDebugStats.shared.set { $0.note = "error: \(error.localizedDescription)" }
        }

        func sessionWasInterrupted(_ session: ARSession) {
            ARDebugStats.log.notice("session interrupted")
            ARDebugStats.shared.set { $0.note = "interrupted" }
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            ARDebugStats.log.notice("session resumed")
            ARDebugStats.shared.set { $0.note = "" }
        }

        private var entities: [UUID: MarkerEntity] = [:]
        private var boundaries: [Int: BoundaryEntity] = [:]

        private var lastSyncOrigin: CLLocationCoordinate2D?
        private var lastFeatureIDs: Set<UUID> = []
        private var lastBoundaryOrigin: CLLocationCoordinate2D?
        private var lastRegionToken = ""
        private var navLine: NavLineEntity?
        private var lastNavOrigin: CLLocationCoordinate2D?
        private var lastDestKey = ""
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
                // Place far markers at a capped distance in the correct direction
                // so a destination miles away is a readable pin on the path, not
                // an invisible speck on the horizon. The label shows the true
                // distance.
                let offset = GeoMath.arPosition(of: feature.coordinate, from: origin, maxDistance: 150)
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
            let m = entities.count; ARDebugStats.shared.set { $0.markers = m }
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
            let b = boundaries.count; ARDebugStats.shared.set { $0.boundaries = b }
        }

        /// Draw a blue trackline on the water from the user toward the
        /// destination, rebuilt as the user moves or the destination changes.
        func syncNavLine(destination: CLLocationCoordinate2D?, fix: NavFix?) {
            guard let root, let arView else { return }
            guard let destination, let fix else {
                navLine?.removeFromParent(); navLine = nil; lastDestKey = ""
                return
            }
            let origin = fix.coordinate
            let key = String(format: "%.5f,%.5f", destination.latitude, destination.longitude)
            let moved = lastNavOrigin.map { GeoMath.distance($0, origin) } ?? .greatestFiniteMagnitude
            guard navLine == nil || key != lastDestKey || moved > 8 else { return }

            navLine?.removeFromParent()
            let offset = GeoMath.arPosition(of: destination, from: origin, maxDistance: 200)
            let cam = arView.cameraTransform.translation
            let entity = NavLineEntity(end: SIMD2(offset.x, offset.z), y: 0)
            entity.position = SIMD3(cam.x, cam.y - 1.4, cam.z)
            root.addChild(entity)
            navLine = entity
            lastNavOrigin = origin
            lastDestKey = key
        }

        /// Billboard labels toward the camera and scale each marker so it keeps a
        /// roughly constant on-screen size no matter how far away it is. Without
        /// this, distant markers shrink to unreadable specks. ~10 fps.
        func tickBillboard() {
            frame &+= 1
            fpsCount += 1
            let now = CACurrentMediaTime()
            if now - fpsWindowStart >= 1.0 {
                let f = fpsCount
                ARDebugStats.shared.set { $0.fps = f }
                fpsCount = 0; fpsWindowStart = now
            }
            guard frame % 6 == 0, let arView else { return }
            let cam = arView.cameraTransform.translation
            for entity in entities.values {
                entity.billboard(toward: cam)
                // Scale roughly with distance for a near-constant on-screen size,
                // clamped so it stays readable but never screen-spanning.
                let d = simd_distance(entity.position(relativeTo: nil), cam)
                entity.scale = SIMD3(repeating: min(7, max(1.0, d / 22)))
            }
        }
    }
}

/// On-screen AR diagnostics (tracking state, fps, marker counts). Shown only
/// when ARDebugStats.enabled. Reads the same data mirrored to os_log.
struct ARDebugHUD: View {
    @ObservedObject private var stats = ARDebugStats.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("AR DEBUG").font(.caption2.bold())
            Text("track: \(stats.tracking)")
            Text("fps \(stats.fps)  ·  markers \(stats.markers)  ·  bounds \(stats.boundaries)")
            if !stats.note.isEmpty { Text(stats.note).foregroundStyle(.orange) }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(.white)
        .padding(8)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}
