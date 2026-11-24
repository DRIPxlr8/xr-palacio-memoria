import SwiftUI
import RealityKit
import ARKit
import Combine

/// Vista de cámara AR. Muestra un marcador por cada término anclado y uno provisorio
/// mientras el usuario completa el término.
///
/// No conoce el estado de la app: recibe qué marcadores deben existir y avisa los toques
/// con callbacks. En cada actualización quita los marcadores que ya no están en lo que recibe.
struct ARContainerView: UIViewRepresentable {
    /// `true` en modo Anclar: tocar una superficie crea un marcador provisorio.
    let isPlacementEnabled: Bool
    let isSessionPaused: Bool
    /// Marcador provisorio que espera su término, si lo hay.
    let pendingMarkerID: UUID?
    /// Texto de cada marcador fijado: el nombre del término o, en Quiz, «?».
    let markerNames: [UUID: String]
    /// Marcadores que se muestran con un aspecto distinto del normal.
    let markerStyles: [UUID: MarkerStyle]
    let objectsToDetect: [UUID: ObjectCatalog.Entry]
    let onMarkerSelected: (UUID) -> Void
    let onPlacementStarted: (UUID) -> Void
    let onEmptyTapped: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)

        context.coordinator.arView = arView
        context.coordinator.updateSession()
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

    func updateUIView(_ uiView: ARView, context: Context) {
        // Los callbacks y los datos del coordinador deben ser siempre los vigentes.
        context.coordinator.parent = self
        context.coordinator.updateSession()
        context.coordinator.syncMarkers()
        context.coordinator.syncObjectCandidates()
    }

    final class Coordinator: NSObject {
        /// Texto del marcador provisorio, mientras no tiene término.
        static let pendingLabel = "Nuevo término"
        /// Nombre de la entidad contenedora de texto dentro de cada marcador.
        static let labelEntityName = "label"

        var parent: ARContainerView
        weak var arView: ARView?
        var markers: [UUID: AnchorEntity] = [:]
        private var objectCandidates: [UUID: AnchorEntity] = [:]
        private var configuredObjects: Set<UUID>?
        private var isPaused = false
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
                self?.syncObjectCandidates()
                self?.orientLabelsTowardsCamera()
            }
        }

        /// Pausa mientras el escáner usa la cámara y reanuda sin reiniciar el seguimiento del palacio.
        func updateSession() {
            guard let arView, ARWorldTrackingConfiguration.isSupported else { return }
            let session = arView.session
            if parent.isSessionPaused {
                if !isPaused { session.pause() }
                isPaused = true
                return
            }

            let enabledIDs = Set(parent.objectsToDetect.keys)
            guard isPaused || configuredObjects != enabledIDs else { return }
            for anchor in session.currentFrame?.anchors ?? [] {
                if let id = referenceID(for: anchor), !enabledIDs.contains(id) {
                    session.remove(anchor: anchor)
                }
            }

            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.detectionObjects = Set(parent.objectsToDetect.values.compactMap(\.object))
            configuration.detectionImages = Set(parent.objectsToDetect.values.compactMap(\.image))
            session.run(configuration)
            configuredObjects = enabledIDs
            isPaused = false
        }

        private func referenceID(for anchor: ARAnchor) -> UUID? {
            let name: String?
            switch anchor {
            case let object as ARObjectAnchor: name = object.referenceObject.name
            case let image as ARImageAnchor: name = image.referenceImage.name
            default: return nil
            }
            return name.flatMap(UUID.init(uuidString:))
        }

        /// Una referencia reconocida muestra su término en cualquier modo, o una opción para anclar en Anclar.
        func syncObjectCandidates() {
            guard let arView else { return }
            var detected: [UUID: ARAnchor] = [:]
            if !isPaused, !parent.objectsToDetect.isEmpty {
                for anchor in arView.session.currentFrame?.anchors ?? [] {
                    guard (anchor as? ARObjectAnchor)?.isTracked != false, let id = referenceID(for: anchor),
                          let entry = parent.objectsToDetect[id], markers[id] == nil
                    else { continue }
                    let label = parent.markerNames[id] ?? (parent.pendingMarkerID == id ? Self.pendingLabel : nil)
                    if let label {
                        let offset = markerOffset(for: entry)
                        let position = anchor.transform * SIMD4(offset, 1)
                        var transform = matrix_identity_float4x4
                        transform.columns.3 = position
                        addFixedMarker(id: id, transform: transform, label: label, in: arView)
                    } else if parent.isPlacementEnabled, detected[id] == nil {
                        detected[id] = anchor
                    }
                }
            }

            for (id, candidate) in objectCandidates where detected[id] == nil {
                arView.scene.removeAnchor(candidate)
                objectCandidates[id] = nil
            }
            for (id, detectedAnchor) in detected where objectCandidates[id] == nil {
                guard let entry = parent.objectsToDetect[id] else { continue }
                let candidate = AnchorEntity(anchor: detectedAnchor)
                let content = Entity()
                content.position = markerOffset(for: entry)
                addMarkerContents(to: content, id: id, label: entry.name, color: .systemTeal)
                candidate.addChild(content)
                arView.scene.addAnchor(candidate)
                objectCandidates[id] = candidate
            }
        }

        private func markerOffset(for entry: ObjectCatalog.Entry) -> SIMD3<Float> {
            guard let reference = entry.object else { return [0, 0.03, 0] }
            return (reference.center + SIMD3(0, reference.extent.y / 2, 0)) * reference.scale
        }

        /// Orienta las etiquetas flotantes hacia la cámara para que siempre sean legibles desde cualquier ángulo
        /// de frente (sin efecto espejo).
        private func orientLabelsTowardsCamera() {
            guard let arView = arView else { return }
            let cameraPos = arView.cameraTransform.translation
            for anchor in Array(markers.values) + Array(objectCandidates.values) {
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
        private func setLabel(_ text: String, on anchor: Entity) {
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

        private func addMarkerContents(to entity: Entity, id: UUID, label: String, color: UIColor) {
            let mesh = MeshResource.generateSphere(radius: 0.025)
            var material = SimpleMaterial()
            material.color = .init(tint: color)
            material.roughness = 0.15
            material.metallic = 0.0

            let sphere = ModelEntity(mesh: mesh, materials: [material])
            sphere.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.045)])
            entity.name = "marker_\(id.uuidString)"
            sphere.name = entity.name
            entity.addChild(sphere)
            setLabel(label, on: entity)
        }

        private func addFixedMarker(id: UUID, transform: simd_float4x4, label: String, in arView: ARView) {
            let anchor = AnchorEntity(world: transform)
            let style = parent.markerStyles[id]
            addMarkerContents(to: anchor, id: id, label: label, color: Self.color(for: style))
            arView.scene.addAnchor(anchor)
            markers[id] = anchor
            shownLabels[id] = label
            shownStyles[id] = style
        }

        private func startPlacement(id: UUID, transform: simd_float4x4, in arView: ARView) {
            addFixedMarker(id: id, transform: transform, label: Self.pendingLabel, in: arView)
            parent.onPlacementStarted(id)
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView, !isPaused else { return }
            let tapLocation = recognizer.location(in: arView)

            // A. Hit-testing sobre objeto 3D existente (esfera o etiqueta de texto)
            if let hitEntity = arView.entity(at: tapLocation) {
                // Buscamos hacia arriba en la jerarquía la entidad que tenga el identificador del marcador
                var current: Entity? = hitEntity
                while let entity = current {
                    if let idString = entity.name.components(separatedBy: "_").last,
                       let markerId = UUID(uuidString: idString) {
                        if parent.isPlacementEnabled,
                           let candidate = objectCandidates[markerId],
                           let content = candidate.children.first {
                            // Fija el término en la ubicación detectada, como cualquier otro lugar del palacio.
                            let position = content.position(relativeTo: nil)
                            var transform = matrix_identity_float4x4
                            transform.columns.3 = SIMD4(position, 1)
                            arView.scene.removeAnchor(candidate)
                            objectCandidates[markerId] = nil
                            startPlacement(id: markerId, transform: transform, in: arView)
                        } else {
                            parent.onMarkerSelected(markerId)
                        }
                        return
                    }
                    current = entity.parent
                }
            }

            // B. Raycast contra planos físicos si no se tocó un marcador.
            // Solo en modo Anclar se crean marcadores.
            guard parent.isPlacementEnabled else {
                parent.onEmptyTapped()
                return
            }

            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            )

            if let firstResult = results.first {
                startPlacement(id: UUID(), transform: firstResult.worldTransform, in: arView)
            } else {
                parent.onEmptyTapped()
            }
        }
    }
}
