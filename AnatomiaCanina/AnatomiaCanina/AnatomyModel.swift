import Foundation
import RealityKit

struct AnatomyModel {
    let entity: Entity
    let parts: [ModelEntity]

    @MainActor
    static func load(_ region: Region) async throws -> AnatomyModel {
        guard let url = Bundle.main.url(forResource: region.rawValue, withExtension: "usdz")
            ?? Bundle.main.url(forResource: region.rawValue, withExtension: "usdz", subdirectory: "Models")
        else { throw LoadError.missingResource }
        return try await load(region, from: url)
    }

    @MainActor
    static func load(_ region: Region, from url: URL) async throws -> AnatomyModel {
        let model = try await Entity(contentsOf: url)
        var meshes: [ModelEntity] = []

        func collect(_ entity: Entity) {
            if let mesh = entity as? ModelEntity, mesh.model != nil { meshes.append(mesh) }
            for child in entity.children { collect(child) }
        }
        collect(model)

        let names = Set(meshes.map(\.name))
        guard meshes.count == names.count,
              names == Set(region.modelParts.map(\.id)),
              region.targets.allSatisfy({ $0.parts.isSubset(of: names) }) else {
            throw LoadError.missingSurface
        }

        for mesh in meshes {
            try Task.checkCancellation()
            guard let geometry = mesh.model?.mesh else { continue }
            let shape = try await ShapeResource.generateStaticMesh(from: geometry)
            mesh.components.set(CollisionComponent(shapes: [shape]))
        }

        return AnatomyModel(entity: model, parts: meshes)
    }

    enum LoadError: Error {
        case missingResource, missingSurface
    }
}
