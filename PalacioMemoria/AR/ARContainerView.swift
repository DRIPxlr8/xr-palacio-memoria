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
        // Diccionario temporal para guardar anclajes por identificador único
        var markers: [UUID: AnchorEntity] = [:]

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // 1. Hit-testing sobre marcadores 3D existentes (Base para CU2 y CU3)
            if let hitEntity = arView.entity(at: tapLocation) as? ModelEntity {
                // Feedback visual básico: cambiar color temporalmente a verde al tocar
                hitEntity.model?.materials = [SimpleMaterial(color: .systemGreen, isMetallic: false)]
                return
            }
            
            // 2. Si no tocó un marcador, raycast sobre superficies para colocar uno nuevo (CU1)
            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )
            
            if let firstResult = results.first {
                let markerId = UUID()
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                anchor.name = markerId.uuidString
                
                // Marcador lo-fi: esfera azul con colisión para permitir toques posteriores
                let mesh = MeshResource.generateSphere(radius: 0.025)
                let material = SimpleMaterial(color: .systemBlue, isMetallic: false)
                let model = ModelEntity(mesh: mesh, materials: [material])
                
                // Habilitar detección física de toques (colisión esférica)
                model.generateCollisionShapes(recursive: false)
                
                anchor.addChild(model)
                arView.scene.addAnchor(anchor)
                markers[markerId] = anchor
            }
        }
    }
}
