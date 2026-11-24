import ARKit
import RealityKit
import SwiftUI

struct ObjectScanCamera: UIViewRepresentable {
    let scan: ObjectScan
    let kind: ObjectCatalog.Kind
    let isSaving: Bool

    func makeCoordinator() -> Coordinator { Coordinator(scan: scan) }

    func makeUIView(context: Context) -> ARView {
        let camera = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
        scan.camera = camera
        switch kind {
        case .object:
            guard ObjectScan.isSupported else { return camera }
            camera.session.run(ARObjectScanningConfiguration())
            camera.addGestureRecognizer(UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap(_:))
            ))
        case .image:
            camera.session.run(ARWorldTrackingConfiguration())
        }
        return camera
    }

    func updateUIView(_ camera: ARView, context: Context) {
        context.coordinator.isSaving = isSaving
    }

    static func dismantleUIView(_ camera: ARView, coordinator: Coordinator) {
        coordinator.selectionTask?.cancel()
        camera.session.pause()
    }

    final class Coordinator: NSObject {
        let scan: ObjectScan
        var isSaving = false
        var selectionTask: Task<Void, Never>?

        init(scan: ObjectScan) { self.scan = scan }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !isSaving, selectionTask == nil else { return }
            let point = gesture.location(in: gesture.view)
            selectionTask = Task { [weak self] in
                guard let self else { return }
                defer { selectionTask = nil }
                await scan.selectObject(at: point)
            }
        }
    }
}
