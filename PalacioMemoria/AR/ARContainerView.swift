import SwiftUI
import RealityKit
import ARKit

public struct ARContainerView: UIViewRepresentable {
    // Callbacks limpios para conectar con AppState / UI sin acoplar dependencias
    public var onMarkerSelected: ((UUID) -> Void)?
    public var onSurfaceTapped: ((simd_float4x4) -> Void)?

    public init(
        onMarkerSelected: ((UUID) -> Void)? = nil,
        onSurfaceTapped: ((simd_float4x4) -> Void)? = nil
    ) {
        self.onMarkerSelected = onMarkerSelected
        self.onSurfaceTapped = onSurfaceTapped
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        
        context.coordinator.arView = arView
        
        // 1. Coaching Overlay de ARKit para guiar al usuario en la detección de superficies
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // 2. Reconocimiento de gestos táctiles
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }

    public func updateUIView(_ uiView: ARView, context: Context) {}

    public class Coordinator: NSObject {
        var parent: ARContainerView
        weak var arView: ARView?
        var markers: [UUID: AnchorEntity] = [:]

        init(_ parent: ARContainerView) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)
            
            // A. Hit-testing sobre objeto 3D existente
            if let hitEntity = arView.entity(at: tapLocation) {
                // Buscamos la entidad raíz del marcador para obtener su UUID
                let markerRoot = hitEntity.anchor as? AnchorEntity ?? hitEntity
                if let idString = markerRoot.name.components(separatedBy: "_").last,
                   let markerId = UUID(uuidString: idString) {
                    
                    // Notificar a la app mediante el callback
                    parent.onMarkerSelected?(markerId)
                    
                    // Feedback visual en la esfera
                    if let modelEntity = hitEntity as? ModelEntity {
                        modelEntity.model?.materials = [SimpleMaterial(color: .systemGreen, isMetallic: false)]
                    }
                    return
                }
            }
            
            // B. Raycast contra planos físicos si no se tocó un marcador
            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )
            
            if let firstResult = results.first {
                let markerId = UUID()
                let transform = firstResult.worldTransform
                
                // Notificar posición al exterior (para cuando se guarde en base de datos/Core)
                parent.onSurfaceTapped?(transform)
                
                // Generar anclaje y componentes 3D
                let anchor = AnchorEntity(world: transform)
                anchor.name = "marker_\(markerId.uuidString)"
                
                // Marcador visual principal: esfera
                let sphereMesh = MeshResource.generateSphere(radius: 0.025)
                let sphereMaterial = SimpleMaterial(color: .systemBlue, isMetallic: false)
                let sphereModel = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
                sphereModel.generateCollisionShapes(recursive: false)
                sphereModel.name = "marker_\(markerId.uuidString)"
                anchor.addChild(sphereModel)
                
                // Etiqueta de texto 3D flotante sobre la esfera
                let textMesh = MeshResource.generateText(
                    "Concepto",
                    extrusionDepth: 0.002,
                    font: .systemFont(ofSize: 0.02, weight: .bold),
                    containerFrame: .zero,
                    alignment: .center
                )
                let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
                let textModel = ModelEntity(mesh: textMesh, materials: [textMaterial])
                // Posicionar el texto 4 cm por encima de la esfera
                textModel.position = simd_float3(-0.03, 0.04, 0)
                anchor.addChild(textModel)
                
                arView.scene.addAnchor(anchor)
                markers[markerId] = anchor
            }
        }
    }
}
