import CoreGraphics
import CoreVideo
import Foundation
import Vision

/// Aísla el objeto que el usuario señaló en un fotograma de la cámara.
enum ObjectSilhouette {
    static func detect(in pixels: CVPixelBuffer, at point: CGPoint) async throws -> CGPath? {
        guard let observation = try await GenerateForegroundInstanceMaskRequest().perform(on: pixels, orientation: .up) else {
            return nil
        }

        let offsets: [CGPoint] = [.zero, CGPoint(x: -0.025, y: 0), CGPoint(x: 0.025, y: 0),
                                 CGPoint(x: 0, y: -0.025), CGPoint(x: 0, y: 0.025)]
        let instances = offsets.lazy.compactMap { offset -> IndexSet? in
            let target = NormalizedPoint(x: point.x + offset.x, y: 1 - point.y - offset.y)
            guard (0...1).contains(target.x), (0...1).contains(target.y) else { return nil }
            let selected = observation.instanceAtPoint(target).intersection(observation.allInstances)
            return selected.isEmpty ? nil : selected
        }.first
        guard let instances else { return nil }

        let mask = try observation.generateMask(for: instances)
        var request = DetectContoursRequest()
        request.detectsDarkOnLight = false
        request.maximumImageDimension = 512
        let contour = try await request.perform(on: mask, orientation: .up)
        var topLeft = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 1)
        guard let silhouette = contour.normalizedPath.copy(using: &topLeft), !silhouette.isEmpty else { return nil }
        return silhouette
    }
}
