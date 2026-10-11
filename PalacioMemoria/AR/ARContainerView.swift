import SwiftUI
import RealityKit
import ARKit

/// Vista de cámara AR. Muestra un marcador por cada término anclado y uno provisorio
/// mientras el usuario completa el término.
///
/// No conoce el estado de la app: recibe qué marcadores deben existir y avisa los toques
/// con callbacks. En cada actualización quita los marcadores que ya no están en lo que recibe.
public struct ARContainerView: UIViewRepresentable {
    /// `true` en modo Anclar: tocar una superficie crea un marcador provisorio.
    public var isPlacementEnabled: Bool
    /// Marcador provisorio que espera su término, si lo hay.
    public var pendingMarkerID: UUID?
    /// Nombre del término de cada marcador fijado.
    public var markerNames: [UUID: String]
    /// Marcador que se muestra resaltado, si lo hay.
    public var highlightedMarkerID: UUID?

    // Callbacks limpios para conectar con AppState / UI sin acoplar dependencias
    public var onMarkerSelected: ((UUID) -> Void)?
    /// Avisa el marcador provisorio recién creado y su posición.
    public var onSurfaceTapped: ((UUID, simd_float4x4) -> Void)?
    /// Avisa un toque que no cayó sobre un marcador ni creó uno nuevo (por ejemplo, en Estudio o Quiz).
    public var onEmptyTapped: (() -> Void)?

    public init(
        isPlacementEnabled: Bool = true,
        pendingMarkerID: UUID? = nil,
        markerNames: [UUID: String] = [:],
        highlightedMarkerID: UUID? = nil,
        onMarkerSelected: ((UUID) -> Void)? = nil,
        onSurfaceTapped: ((UUID, simd_float4x4) -> Void)? = nil,
        onEmptyTapped: (() -> Void)? = nil
    ) {
        self.isPlacementEnabled = isPlacementEnabled
        self.pendingMarkerID = pendingMarkerID
        self.markerNames = markerNames
        self.highlightedMarkerID = highlightedMarkerID
        self.onMarkerSelected = onMarkerSelected
        self.onSurfaceTapped = onSurfaceTapped
        self.onEmptyTapped = onEmptyTapped
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

    public func updateUIView(_ uiView: ARView, context: Context) {
        // Los callbacks y los datos del coordinador deben ser siempre los vigentes.
        context.coordinator.parent = self
        context.coordinator.syncMarkers()
    }

    public class Coordinator: NSObject {
        /// Texto del marcador provisorio, mientras no tiene término.
        static let pendingLabel = "Nuevo término"
        /// Nombre de la entidad de texto dentro de cada marcador.
        static let labelEntityName = "label"

        var parent: ARContainerView
        weak var arView: ARView?
        var markers: [UUID: AnchorEntity] = [:]
        /// Texto que muestra hoy cada marcador, para regenerar la etiqueta solo cuando cambia.
        var shownLabels: [UUID: String] = [:]
        /// Marcador que hoy se ve resaltado.
        var shownHighlightID: UUID?

        init(_ parent: ARContainerView) {
            self.parent = parent
        }

        /// Deja en la escena solo los marcadores que la app conoce (el provisorio y los fijados)
        /// y actualiza el texto de los que cambiaron.
        func syncMarkers() {
            for (markerID, anchor) in markers {
                let isPending = markerID == parent.pendingMarkerID
                guard let text = parent.markerNames[markerID] ?? (isPending ? Self.pendingLabel : nil) else {
                    arView?.scene.removeAnchor(anchor)
                    markers[markerID] = nil
                    shownLabels[markerID] = nil
                    continue
                }

                if shownLabels[markerID] != text {
                    setLabel(text, on: anchor)
                    shownLabels[markerID] = text
                }
            }

            syncHighlight()
        }

        /// Deja resaltado solo el marcador que indica la app.
        private func syncHighlight() {
            guard shownHighlightID != parent.highlightedMarkerID else { return }

            if let previousID = shownHighlightID, let anchor = markers[previousID] {
                setSphereColor(.systemBlue, on: anchor)
            }
            if let currentID = parent.highlightedMarkerID, let anchor = markers[currentID] {
                setSphereColor(.systemGreen, on: anchor)
            }
            shownHighlightID = parent.highlightedMarkerID
        }

        /// Cambia el color de la esfera del marcador, sin tocar su etiqueta.
        private func setSphereColor(_ color: UIColor, on anchor: AnchorEntity) {
            for child in anchor.children where child.name != Self.labelEntityName {
                if let sphere = child as? ModelEntity {
                    sphere.model?.materials = [SimpleMaterial(color: color, isMetallic: false)]
                }
            }
        }

        /// Reemplaza la etiqueta de texto 3D flotante del marcador.
        private func setLabel(_ text: String, on anchor: AnchorEntity) {
            anchor.findEntity(named: Self.labelEntityName)?.removeFromParent()

            let textMesh = MeshResource.generateText(
                text,
                extrusionDepth: 0.002,
                font: .systemFont(ofSize: 0.02, weight: .bold),
                containerFrame: .zero,
                alignment: .center
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textModel = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textModel.name = Self.labelEntityName
            // Centrar el texto sobre la esfera, 4 cm por encima
            textModel.position = simd_float3(-textMesh.bounds.center.x, 0.04, 0)
            anchor.addChild(textModel)
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

                    // Notificar a la app mediante el callback. El resaltado lo decide la app
                    // y se aplica en la siguiente actualización (ver syncHighlight).
                    parent.onMarkerSelected?(markerId)
                    return
                }
            }

            // B. Raycast contra planos físicos si no se tocó un marcador.
            // Solo en modo Anclar se crean marcadores.
            guard parent.isPlacementEnabled else {
                parent.onEmptyTapped?()
                return
            }

            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )

            if let firstResult = results.first {
                let markerId = UUID()
                let transform = firstResult.worldTransform

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

                // Etiqueta provisoria; pasa a ser el nombre del término cuando se fija
                setLabel(Self.pendingLabel, on: anchor)

                arView.scene.addAnchor(anchor)
                markers[markerId] = anchor
                shownLabels[markerId] = Self.pendingLabel

                // Avisar a la app el marcador creado. Si la app no lo registra como provisorio,
                // se quita en la siguiente actualización.
                parent.onSurfaceTapped?(markerId, transform)
            } else {
                parent.onEmptyTapped?()
            }
        }
    }
}
