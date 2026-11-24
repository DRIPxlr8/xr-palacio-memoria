import ARKit
import CoreImage
import Foundation
import Observation
import OSLog
import RealityKit
import UIKit

@Observable
final class ObjectScan {
    enum CaptureError: LocalizedError {
        case trackingUnavailable
        case insufficientDetail
        case objectUnavailable
        case imageUnavailable
        case imageUnsuitable

        var errorDescription: String? {
            switch self {
            case .trackingUnavailable:
                "Mueve el dispositivo despacio alrededor del objeto y vuelve a intentarlo."
            case .insufficientDetail:
                "Faltan detalles del objeto. Obsérvalo desde más ángulos o prueba con uno que tenga más textura."
            case .objectUnavailable:
                "La cámara no pudo terminar el escaneo 3D. Vuelve a seleccionar el objeto e inténtalo de nuevo."
            case .imageUnavailable:
                "Todavía no hay una imagen de cámara lista. Vuelve a intentarlo."
            case .imageUnsuitable:
                "Encuadra una zona con más detalles, de frente y sin reflejos, y vuelve a intentarlo."
            }
        }
    }

    static var isSupported: Bool { ARObjectScanningConfiguration.isSupported }
    static let imageGuide = CGRect(x: 0.14, y: 0.17, width: 0.72, height: 0.66)
    private static let logger = Logger(subsystem: "cl.uc.vsanjuan.PalacioMemoria", category: "Escaneo")

    private struct Volume {
        let origin: SIMD3<Float>
        let direction: SIMD3<Float>
        let rotation: simd_quatf
        let extent: SIMD3<Float>
        let distance: Double
    }

    @ObservationIgnored weak var camera: ARView?
    @ObservationIgnored private lazy var imageContext = CIContext()
    private var volume: Volume?
    private(set) var selectionID: UUID?
    private(set) var outline: CGPath?
    private(set) var isSelecting = false
    private(set) var selectionMessage: String?
    var distance = 45.0

    private var center: SIMD3<Float>? {
        volume.map { $0.origin + $0.direction * Float(distance / 100) }
    }

    func selectObject(at point: CGPoint) async {
        guard !isSelecting, let camera, let frame = camera.session.currentFrame,
              let display = displayTransform(for: frame, in: camera) else { return }

        isSelecting = true
        outline = nil
        selectionID = nil
        volume = nil
        selectionMessage = nil
        defer { isSelecting = false }

        let tap = CGPoint(x: point.x / camera.bounds.width, y: point.y / camera.bounds.height)
            .applying(display.inverted())
        let silhouette = try? await ObjectSilhouette.detect(in: frame.capturedImage, at: tap)
        guard !Task.isCancelled else { return }
        guard let silhouette else {
            selectionMessage = "No distinguí el objeto. Acércate y vuelve a tocarlo."
            return
        }

        let selection = estimateVolume(of: silhouette, in: frame)
        volume = selection
        distance = selection.distance
        showOutline(silhouette, display: display)
        selectionID = UUID()
    }

    func refreshOutline() async {
        guard let selectionID, let center, let camera, let frame = camera.session.currentFrame,
              let display = displayTransform(for: frame, in: camera) else { return }
        guard let point = imagePoint(for: center, camera: frame.camera).map(\.point),
              CGRect(x: 0, y: 0, width: 1, height: 1).contains(point.applying(display)) else {
            outline = nil
            return
        }

        let silhouette = try? await ObjectSilhouette.detect(in: frame.capturedImage, at: point)
        guard !Task.isCancelled, selectionID == self.selectionID else { return }
        showOutline(silhouette, display: display)
    }

    private func showOutline(_ silhouette: CGPath?, display: CGAffineTransform) {
        var transform = display
        outline = silhouette?.copy(using: &transform)
    }

    private func estimateVolume(of silhouette: CGPath, in frame: ARFrame) -> Volume {
        let camera = frame.camera
        let depths = (frame.rawFeaturePoints?.points ?? []).compactMap { point -> Float? in
            guard let hit = imagePoint(for: point, camera: camera),
                  (0.15...2.5).contains(hit.depth), silhouette.contains(hit.point, using: .evenOdd)
            else { return nil }
            return hit.depth
        }.sorted()

        let surface = depths.isEmpty ? Float(0.45) : depths[depths.count / 3]
        let bounds = silhouette.boundingBoxOfPath
        let forward = camera.transform.columns.2
        let rotation = simd_quatf(angle: atan2(forward.x, forward.z), axis: [0, 1, 0])
        let left = worldDirection(at: CGPoint(x: bounds.minX, y: bounds.midY), camera: camera)
        let right = worldDirection(at: CGPoint(x: bounds.maxX, y: bounds.midY), camera: camera)
        let top = worldDirection(at: CGPoint(x: bounds.midX, y: bounds.minY), camera: camera)
        let bottom = worldDirection(at: CGPoint(x: bounds.midX, y: bounds.maxY), camera: camera)
        let lateralSpan = rotation.inverse.act((right - left) * surface)
        let verticalSpan = rotation.inverse.act((bottom - top) * surface)
        let depth = max(0.05, min(simd_length(lateralSpan), simd_length(verticalSpan)))
        let flatExtent = SIMD3(abs(lateralSpan.x) + abs(verticalSpan.x),
                               abs(lateralSpan.y) + abs(verticalSpan.y),
                               abs(lateralSpan.z) + abs(verticalSpan.z))
        let extent = SIMD3(max(flatExtent.x * 1.2, 0.05),
                           max(flatExtent.y * 1.2, depth), max(flatExtent.z * 1.2, depth))
        let target = CGPoint(x: bounds.midX, y: bounds.midY)
        let position = camera.transform.columns.3
        return Volume(origin: SIMD3(position.x, position.y, position.z),
                      direction: worldDirection(at: target, camera: camera), rotation: rotation, extent: extent,
                      distance: min(250, Double((surface + depth / 2) * 100)))
    }

    private func worldDirection(at point: CGPoint, camera: ARCamera) -> SIMD3<Float> {
        let intrinsics = camera.intrinsics
        let x = (Float(point.x * camera.imageResolution.width) - intrinsics.columns.2.x) / intrinsics.columns.0.x
        let y = (Float(point.y * camera.imageResolution.height) - intrinsics.columns.2.y) / intrinsics.columns.1.y
        let world = camera.transform * SIMD4(x, -y, -1, 0)
        return SIMD3(world.x, world.y, world.z)
    }

    private func imagePoint(for point: SIMD3<Float>, camera: ARCamera) -> (point: CGPoint, depth: Float)? {
        let local = camera.transform.inverse * SIMD4(point, 1)
        let depth = -local.z
        guard depth > 0 else { return nil }
        let intrinsics = camera.intrinsics
        let x = local.x / depth * intrinsics.columns.0.x + intrinsics.columns.2.x
        let y = -local.y / depth * intrinsics.columns.1.y + intrinsics.columns.2.y
        return (CGPoint(x: CGFloat(x) / camera.imageResolution.width,
                        y: CGFloat(y) / camera.imageResolution.height), depth)
    }

    private func displayTransform(for frame: ARFrame, in camera: ARView) -> CGAffineTransform? {
        guard let orientation = camera.window?.windowScene?.effectiveGeometry.interfaceOrientation,
              camera.bounds.width > 0, camera.bounds.height > 0 else { return nil }
        return frame.displayTransform(for: orientation, viewportSize: camera.bounds.size)
    }

    func capture() async throws -> ARReferenceObject {
        guard let camera, let volume, let center,
              case .normal = camera.session.currentFrame?.camera.trackingState
        else { throw CaptureError.trackingUnavailable }

        var transform = simd_float4x4(volume.rotation)
        transform.columns.3 = SIMD4(center, 1)
        let extent = volume.extent * Float(distance / volume.distance)

        // Da margen al volumen estimado si la primera región no contiene suficientes detalles.
        for expansion: Float in [1, 1.35] {
            try Task.checkCancellation()
            do {
                let reference = try await camera.session.createReferenceObject(
                    transform: transform,
                    center: .zero,
                    extent: extent * expansion
                )
                if !reference.rawFeaturePoints.points.isEmpty { return reference }
            } catch let error as ARError where error.code == .insufficientFeatures {
                continue
            } catch {
                let cause = error as NSError
                Self.logger.error("Error de captura 3D \(cause.domain, privacy: .public) / \(cause.code, privacy: .public)")
                throw CaptureError.objectUnavailable
            }
        }
        throw CaptureError.insufficientDetail
    }

    func captureImage(widthInMeters: Double) async throws -> (data: Data, reference: ARReferenceImage) {
        guard let camera, let frame = camera.session.currentFrame,
              let display = displayTransform(for: frame, in: camera)
        else { throw CaptureError.imageUnavailable }

        let viewport = camera.bounds.size
        let pixels = CGSize(width: 1024, height: 1024 * viewport.height / viewport.width)
        let source = CIImage(cvPixelBuffer: frame.capturedImage)
        // Core Image usa el origen inferior y ARKit el superior para coordenadas normalizadas.
        let flipY = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 1)
        let transform = CGAffineTransform(scaleX: 1 / source.extent.width, y: 1 / source.extent.height)
            .concatenating(flipY)
            .concatenating(display)
            .concatenating(flipY)
            .concatenating(CGAffineTransform(scaleX: pixels.width, y: pixels.height))
        let crop = Self.imageGuide.applying(flipY)
            .applying(CGAffineTransform(scaleX: pixels.width, y: pixels.height)).integral
        guard let image = imageContext.createCGImage(source.transformed(by: transform), from: crop),
              let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.9)
        else { throw CaptureError.imageUnavailable }

        let reference = ARReferenceImage(image, orientation: .up, physicalWidth: widthInMeters)
        do {
            try await reference.validate()
        } catch {
            throw CaptureError.imageUnsuitable
        }
        return (data, reference)
    }
}
