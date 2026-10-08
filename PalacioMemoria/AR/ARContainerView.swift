import SwiftUI
import RealityKit
import ARKit

public struct ARContainerView: UIViewRepresentable {
    public init() {}

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        context.coordinator.arView = arView
        
        // Agregar gesto de toque en pantalla
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    public func updateUIView(_ uiView: ARView, context: Context) {}

    public class Coordinator: NSObject {
        weak var arView: ARView?

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // Raycast contra planos físicos detectados (CU1)
            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )
            
            if let firstResult = results.first {
                // Crear un anclaje en la posición 3D real
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                
                // Marcador lo-fi: esfera azul de 5 cm de diámetro
                let mesh = MeshResource.generateSphere(radius: 0.025)
                let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
                let model = ModelEntity(mesh: mesh, materials: [material])
                
                anchor.addChild(model)
                arView.scene.addAnchor(anchor)
            }
        }
    }
}
