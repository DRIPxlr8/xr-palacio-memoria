import SwiftUI
import RealityKit
import ARKit
import Combine

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
    /// Texto de cada marcador fijado: el nombre del término o, en Quiz, «?».
    public var markerNames: [UUID: String]
    /// Marcadores que se muestran con un aspecto distinto del normal.
    public var markerStyles: [UUID: MarkerStyle]

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
        markerStyles: [UUID: MarkerStyle] = [:],
        onMarkerSelected: ((UUID) -> Void)? = nil,
        onSurfaceTapped: ((UUID, simd_float4x4) -> Void)? = nil,
        onEmptyTapped: (() -> Void)? = nil
    ) {
        self.isPlacementEnabled = isPlacementEnabled
        self.pendingMarkerID = pendingMarkerID
        self.markerNames = markerNames
        self.markerStyles = markerStyles
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
        context.coordinator.setupSceneSubscription()

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
        /// Nombre de la entidad contenedora de texto dentro de cada marcador.
        static let labelEntityName = "label"

        var parent: ARContainerView
        weak var arView: ARView?
        var markers: [UUID: AnchorEntity] = [:]
        /// Texto que muestra hoy cada marcador, para regenerar la etiqueta solo cuando cambia.
        var shownLabels: [UUID: String] = [:]
        /// Aspecto con que hoy se ve cada marcador que no va con su color normal.
        var shownStyles: [UUID: MarkerStyle] = [:]
        /// Suscripción al ciclo de render para orientar etiquetas hacia la cámara.
        private var updateSubscription: (any Cancellable)?

        init(_ parent: ARContainerView) {
            self.parent = parent
        }

        func setupSceneSubscription() {
            guard let arView = arView else { return }
            updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                self?.orientLabelsTowardsCamera()
            }
        }

        /// Orienta las etiquetas flotantes hacia la cámara para que siempre sean legibles desde cualquier ángulo
        /// de frente (sin efecto espejo).
        private func orientLabelsTowardsCamera() {
            guard let arView = arView else { return }
            let cameraPos = arView.cameraTransform.translation
            for (_, anchor) in markers {
                if let label = anchor.findEntity(named: Self.labelEntityName) {
                    let labelWorldPos = label.position(relativeTo: nil)
                    var targetPos = cameraPos
                    targetPos.y = labelWorldPos.y
                    // RealityKit orienta el eje -Z hacia targetPos con look(at:).
                    // Como MeshResource.generateText genera su cara frontal hacia +Z,
                    // rotamos 180° en el eje Y para que la cara frontal mire al usuario legible de izquierda a derecha.
                    label.look(at: targetPos, from: labelWorldPos, relativeTo: nil)
                    label.orientation *= simd_quatf(angle: .pi, axis: [0, 1, 0])
                }
            }
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
                    shownStyles[markerID] = nil
                    continue
                }

                if shownLabels[markerID] != text {
                    setLabel(text, on: anchor)
                    shownLabels[markerID] = text
                }
            }

            syncStyles()
        }

        /// Pinta cada marcador según el aspecto que indica la app.
        private func syncStyles() {
            for (markerID, anchor) in markers {
                let style = parent.markerStyles[markerID]
                if shownStyles[markerID] != style {
                    setSphereColor(Self.color(for: style), on: anchor)
                    shownStyles[markerID] = style
                }
            }
        }

        /// Color de la esfera para cada aspecto. Sin aspecto, el color normal (azul).
        private static func color(for style: MarkerStyle?) -> UIColor {
            guard let style else { return .systemBlue }

            switch style {
            case .selected: return .systemYellow
            case .correct: return .systemGreen
            case .incorrect: return .systemRed
            }
        }

        /// Cambia el color de la esfera del marcador, sin tocar su etiqueta.
        private func setSphereColor(_ color: UIColor, on anchor: AnchorEntity) {
            for child in anchor.children where child.name != Self.labelEntityName {
                if let sphere = child as? ModelEntity {
                    var material = SimpleMaterial()
                    material.color = .init(tint: color)
                    material.roughness = 0.15
                    material.metallic = 0.0
                    sphere.model?.materials = [material]
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
            textModel.name = "textMesh"
            // Habilitar colisión en la etiqueta para que tocar el texto también seleccione el marcador
            textModel.generateCollisionShapes(recursive: false)
            // Centrar el texto sobre el origen de su contenedor
            textModel.position = simd_float3(-textMesh.bounds.center.x, -textMesh.bounds.center.y, 0)

            // Contenedor colocado exactamente 4 cm por encima de la esfera
            let labelContainer = Entity()
            labelContainer.name = Self.labelEntityName
            labelContainer.position = simd_float3(0, 0.04, 0)
            labelContainer.addChild(textModel)

            anchor.addChild(labelContainer)
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = recognizer.location(in: arView)

            // A. Hit-testing sobre objeto 3D existente (esfera o etiqueta de texto)
            if let hitEntity = arView.entity(at: tapLocation) {
                // Buscamos hacia arriba en la jerarquía la entidad que tenga el identificador del marcador
                var current: Entity? = hitEntity
                while let entity = current {
                    if let idString = entity.name.components(separatedBy: "_").last,
                       let markerId = UUID(uuidString: idString) {
                        parent.onMarkerSelected?(markerId)
                        return
                    }
                    current = entity.parent
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
                var sphereMaterial = SimpleMaterial()
                sphereMaterial.color = .init(tint: .systemBlue)
                sphereMaterial.roughness = 0.15
                sphereMaterial.metallic = 0.0

                let sphereModel = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
                // Radio de toque cómodo (4.5 cm) para facilitar selección táctil en el espacio
                sphereModel.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.045)])
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
