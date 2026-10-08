import SwiftUI
import RealityKit
import ARKit

public struct ARContainerView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        // Detección de planos horizontales y verticales requerida para CU1
        config.planeDetection = [.horizontal, .vertical]
        
        arView.session.run(config)
        return arView
    }

    public func updateUIView(_ uiView: ARView, context: Context) {}
}
