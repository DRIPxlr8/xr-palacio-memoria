import ARKit
import RealityKit
import SwiftUI
import UIKit

enum TrackingStatus: Equatable {
    case starting, ready, limited, failed
}

struct StationHighlight: Equatable {
    let region: Region
    let parts: Set<String>
}

private struct StationAppearance: Equatable {
    var quizColors: [String: QuizZoneColor] = [:]
    var highlighted: Set<String> = []
    var awaitingAnswer = false
    var preview = false
}

struct AnatomyViewer: UIViewRepresentable {
    let layout: PalaceLayout
    let placementRegion: Region?
    let showLabels: Bool
    let highlighted: StationHighlight?
    let showQuizColors: Bool
    let awaitingAnswer: Bool
    let jointSpacing: [Region: Float]
    let onLoaded: (Set<Region>) -> Void
    let onTracking: (TrackingStatus) -> Void
    let onSurfaceUnavailable: () -> Void
    let onPlacement: (Region, StationPlacement) -> Void
    let onResize: (Region, Float) -> Void
    let onSelection: (Region, String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        context.coordinator.start(in: view)
        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.update(self)
    }

    static func dismantleUIView(_ view: ARView, coordinator: Coordinator) {
        coordinator.stop(in: view)
    }

    @MainActor
    final class Coordinator: NSObject, ARSessionDelegate {
        private var input: AnatomyViewer
        private weak var view: ARView?
        private var stations: [Region: Station] = [:]
        private var loadTask: Task<Void, Never>?
        private var tracking = TrackingStatus.starting
        private var active = true
        private weak var manipulated: Station?
        private var resizing: (region: Region, initialScale: Float)?

        init(_ input: AnatomyViewer) { self.input = input }

        func start(in view: ARView) {
            self.view = view
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            let pan = UIPanGestureRecognizer(target: self, action: #selector(rotated(_:)))
            pan.maximumNumberOfTouches = 1
            tap.require(toFail: pan)
            view.addGestureRecognizer(tap)
            view.addGestureRecognizer(pan)
            view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(scaled(_:))))

            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            view.session.delegate = self
            view.session.run(configuration)

            loadTask = Task { [weak self] in
                for region in Region.allCases {
                    do {
                        let model = try await AnatomyModel.load(region)
                        try Task.checkCancellation()
                        self?.stations[region] = try Station(region: region, model: model)
                    } catch is CancellationError {
                        return
                    } catch {
                        print("AnatomiaCanina · \(region.rawValue) · \(error)")
                    }
                }
                guard let self, active else { return }
                update(input)
                input.onLoaded(Set(stations.keys))
            }
        }

        func stop(in view: ARView) {
            active = false
            loadTask?.cancel()
            view.session.delegate = nil
            view.session.pause()
            view.scene.anchors.removeAll()
        }

        func update(_ input: AnatomyViewer) {
            self.input = input
            guard let view else { return }
            for (region, station) in stations {
                station.place(at: input.layout.visiblePlacement(for: region), in: view.scene)
                guard station.anchor != nil else { continue }
                station.label.isEnabled = input.showLabels
                station.applyJointSpacing(input.jointSpacing[region, default: 0])
                station.applyAppearance(StationAppearance(
                    quizColors: input.showQuizColors ? station.quizColors : [:],
                    highlighted: input.highlighted?.region == region ? input.highlighted?.parts ?? [] : [],
                    awaitingAnswer: input.awaitingAnswer,
                    preview: input.layout.draft?.region == region
                ))
            }
        }

        private func setTracking(_ status: TrackingStatus) {
            guard active, tracking != status, tracking != .failed else { return }
            tracking = status
            input.onTracking(status)
        }

        private func hitTest(_ point: CGPoint, in view: ARView) -> (Station, ModelEntity)? {
            guard let part = view.hitTest(point, query: .nearest).first?.entity as? ModelEntity,
                  let station = stations.values.first(where: { $0.contains(part) })
            else { return nil }
            return (station, part)
        }

        @objc private func tapped(_ gesture: UITapGestureRecognizer) {
            guard let view, tracking == .ready else { return }
            let point = gesture.location(in: view)
            if let region = input.placementRegion, stations[region] != nil {
                if hitTest(point, in: view)?.0.region == region { return }
                let detected = view.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .horizontal)
                let results = detected.isEmpty
                    ? view.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal)
                    : detected
                guard let hit = results.first else {
                    input.onSurfaceUnavailable()
                    return
                }

                let column = hit.worldTransform.columns.3
                let position = SIMD3(column.x, column.y, column.z)
                let camera = view.cameraTransform.translation
                let facing = atan2(camera.x - position.x, camera.z - position.z)
                input.onPlacement(region, StationPlacement(position: position, facing: facing))
                return
            }

            if let (station, part) = hitTest(point, in: view) {
                input.onSelection(station.region, part.name)
            }
        }

        @objc private func rotated(_ gesture: UIPanGestureRecognizer) {
            guard let view, input.placementRegion == nil, tracking == .ready else { return }
            switch gesture.state {
            case .began:
                let motion = gesture.translation(in: view)
                let location = gesture.location(in: view)
                let start = CGPoint(x: location.x - motion.x, y: location.y - motion.y)
                manipulated = hitTest(start, in: view)?.0
            case .changed:
                if let station = manipulated { station.rotate(by: gesture.translation(in: view)) }
                gesture.setTranslation(.zero, in: view)
            default:
                manipulated = nil
            }
        }

        @objc private func scaled(_ gesture: UIPinchGestureRecognizer) {
            guard let view, tracking == .ready else {
                resizing = nil
                return
            }
            switch gesture.state {
            case .began:
                var hit = hitTest(gesture.location(in: view), in: view)
                for index in 0..<gesture.numberOfTouches where hit == nil {
                    hit = hitTest(gesture.location(ofTouch: index, in: view), in: view)
                }
                if let region = hit?.0.region,
                   input.placementRegion == nil || input.layout.draft?.region == region,
                   let placement = input.layout.visiblePlacement(for: region) {
                    resizing = (region, placement.dimensions.scale)
                } else {
                    resizing = nil
                }
            case .changed:
                if let resizing {
                    input.onResize(resizing.region, resizing.initialScale * Float(gesture.scale))
                }
            default:
                resizing = nil
            }
        }

        nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            let status: TrackingStatus = switch camera.trackingState {
            case .normal: .ready
            case .notAvailable, .limited: .limited
            @unknown default: .limited
            }
            Task { @MainActor [weak self] in self?.setTracking(status) }
        }

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            Task { @MainActor [weak self] in self?.setTracking(.failed) }
        }

        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor [weak self] in self?.setTracking(.limited) }
        }

        nonisolated func sessionInterruptionEnded(_ session: ARSession) {
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .normal? = view?.session.currentFrame?.camera.trackingState { setTracking(.ready) }
            }
        }
    }
}

@MainActor
private final class Station {
    let region: Region
    let label = Entity()
    let quizColors: [String: QuizZoneColor]
    private let holder = Entity()
    private let pivot = Entity()
    private let model: AnatomyModel
    private let originalPositions: [SIMD3<Float>]
    private var placement: StationPlacement?
    private var jointSpacing: Float = 0
    private var appearance: StationAppearance?
    private var drag: SIMD2<Float> = .zero
    private(set) var anchor: AnchorEntity?

    init(region: Region, model: AnatomyModel) throws {
        self.region = region
        quizColors = region.quizColors
        self.model = model
        originalPositions = model.parts.map(\.position)

        let text = MeshResource.generateText(region.title, extrusionDepth: 0.001,
                                             font: .systemFont(ofSize: 0.045, weight: .semibold))
        let caption = ModelEntity(mesh: text, materials: [
            UnlitMaterial(color: UIColor(red: 0.61, green: 1, blue: 0.85, alpha: 1))
        ])
        caption.position.x = -caption.visualBounds(relativeTo: caption).center.x
        label.addChild(caption)
        label.components.set(BillboardComponent())

        holder.addChild(pivot)
        pivot.addChild(model.entity)
        let bounds = model.entity.visualBounds(relativeTo: pivot)
        let span = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
        guard span > 0 else { throw AnatomyModel.LoadError.missingSurface }
        let scale = 0.36 / span
        model.entity.scale = .init(repeating: scale)
        model.entity.position = -bounds.center * scale
        adjustHeight()
        applyAppearance(StationAppearance())
    }

    func place(at next: StationPlacement?, in scene: RealityKit.Scene) {
        guard placement != next else { return }
        let previousPosition = placement?.position
        placement = next

        if next?.position != previousPosition {
            if let anchor { scene.removeAnchor(anchor) }
            anchor = nil
            if let next {
                let placed = AnchorEntity(world: next.position)
                placed.addChild(holder)
                placed.addChild(label)
                scene.addAnchor(placed)
                anchor = placed
            }
        }

        guard let next else { return }
        holder.orientation = simd_quatf(angle: next.facing, axis: [0, 1, 0])
        pivot.scale = .init(repeating: next.dimensions.scale)
        adjustHeight()
    }

    func contains(_ part: ModelEntity) -> Bool {
        model.parts.contains { $0 === part }
    }

    func applyJointSpacing(_ spacing: Float) {
        guard jointSpacing != spacing else { return }
        jointSpacing = spacing
        let humeralParts = Set(["humerus", "humeral_head"])
        for (part, original) in zip(model.parts, originalPositions) {
            let offset = region == .shoulder && humeralParts.contains(part.name) ? -spacing : 0
            let lift = region == .elbow && part.name == "humerus" ? spacing : offset
            part.position = original + [0, lift, 0]
        }
        adjustHeight()
    }

    func rotate(by movement: CGPoint) {
        drag.x += Float(movement.x) * 0.012
        drag.y = min(1.15, max(-1.15, drag.y + Float(movement.y) * 0.010))
        orient()
    }

    private func adjustHeight() {
        let bounds = pivot.visualBounds(relativeTo: holder)
        let elevation = placement?.dimensions.elevation ?? StationDimensions.standard.elevation
        holder.position.y = elevation - bounds.min.y
        label.position.y = holder.position.y + bounds.max.y + 0.04
    }

    private func orient() {
        let yaw = simd_quatf(angle: drag.x, axis: [0, 1, 0])
        let pitch = simd_quatf(angle: drag.y, axis: [1, 0, 0])
        pivot.orientation = yaw * pitch
        adjustHeight()
    }

    func applyAppearance(_ next: StationAppearance) {
        guard appearance != next else { return }
        for part in model.parts {
            let color: UIColor
            if next.preview {
                color = UIColor(red: 0.35, green: 0.85, blue: 0.76, alpha: 1)
            } else if next.highlighted.contains(part.name) {
                color = next.awaitingAnswer ? .white : UIColor(red: 0.27, green: 0.87, blue: 0.73, alpha: 1)
            } else if let zone = next.quizColors[part.name] {
                color = UIColor(hue: zone.hue, saturation: zone.saturation, brightness: zone.brightness, alpha: 1)
            } else {
                color = UIColor(red: 0.88, green: 0.80, blue: 0.65, alpha: 1)
            }
            part.model?.materials = [SimpleMaterial(color: color, roughness: 0.74, isMetallic: false)]
        }
        appearance = next
    }
}
