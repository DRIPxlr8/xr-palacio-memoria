import Foundation
import RealityKit

@main
enum VerifyModels {
    @MainActor
    static func main() async throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        for region in Region.allCases {
            let model = try await AnatomyModel.load(
                region, from: directory.appendingPathComponent("\(region.rawValue).usdz")
            )
            let extent = model.entity.visualBounds(relativeTo: nil).extents
            precondition(extent.x > 0 && extent.y > 0 && extent.z > 0)
            print("\(region.title): \(model.parts.count) superficies cargadas y seleccionables en RealityKit.")
        }
    }
}
