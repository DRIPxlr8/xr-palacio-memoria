import ARKit
import Foundation
import ImageIO
import Observation

/// Guarda las referencias escaneadas y permite elegir cuáles busca la cámara.
@Observable
final class ObjectCatalog {
    enum Kind {
        case object
        case image

        var title: String { self == .object ? "Objeto 3D" : "Imagen plana" }
    }

    struct Entry: Identifiable {
        let id: UUID
        let name: String
        var object: ARReferenceObject?
        var image: ARReferenceImage?

        var kind: Kind { image == nil ? .object : .image }
    }

    private struct StoredObject: Codable {
        let name: String
        let reference: Data
        var imageWidth: Double? = nil
    }

    private static let disabledKey = "ObjectCatalog.disabledIDs"
    private let directory = URL.applicationSupportDirectory.appending(path: "ObjectCatalog", directoryHint: .isDirectory)
    private var disabledIDs: Set<UUID>
    private(set) var entries: [Entry] = []
    private(set) var hasUnreadableEntries = false

    init() {
        disabledIDs = Set((UserDefaults.standard.stringArray(forKey: Self.disabledKey) ?? []).compactMap(UUID.init(uuidString:)))
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for url in files where url.pathExtension == "plist" {
                do {
                    entries.append(try Self.load(from: url))
                } catch {
                    hasUnreadableEntries = true
                }
            }
            sortEntries()
        } catch {
            hasUnreadableEntries = true
        }
    }

    var enabledEntries: [UUID: Entry] {
        Dictionary(uniqueKeysWithValues: entries.filter { isEnabled($0.id) }.map { ($0.id, $0) })
    }

    func isEnabled(_ id: UUID) -> Bool {
        !disabledIDs.contains(id)
    }

    func setEnabled(_ enabled: Bool, for id: UUID) {
        if enabled {
            disabledIDs.remove(id)
        } else {
            disabledIDs.insert(id)
        }
        saveSelection()
    }

    func add(name: String, reference: ARReferenceObject) throws -> UUID {
        let id = UUID()
        reference.name = id.uuidString
        let archive = try NSKeyedArchiver.archivedData(withRootObject: reference, requiringSecureCoding: true)
        try save(Entry(id: id, name: name, object: reference), data: archive)
        return id
    }

    func add(name: String, image: ARReferenceImage, data: Data) throws -> UUID {
        let id = UUID()
        image.name = id.uuidString
        try save(Entry(id: id, name: name, image: image), data: data)
        return id
    }

    private func save(_ entry: Entry, data reference: Data) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let record = StoredObject(name: entry.name, reference: reference, imageWidth: entry.image.map { Double($0.physicalSize.width) })
        let data = try encoder.encode(record)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL(for: entry.id), options: .atomic)

        entries.append(entry)
        sortEntries()
    }

    func remove(_ entry: Entry) throws {
        try FileManager.default.removeItem(at: fileURL(for: entry.id))
        entries.removeAll { $0.id == entry.id }
        disabledIDs.remove(entry.id)
        saveSelection()
    }

    private func fileURL(for id: UUID) -> URL {
        directory.appending(path: id.uuidString).appendingPathExtension("plist")
    }

    private static func load(from url: URL) throws -> Entry {
        let stored = try PropertyListDecoder().decode(StoredObject.self, from: Data(contentsOf: url))
        guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if let width = stored.imageWidth {
            guard width.isFinite, width > 0,
                  let source = CGImageSourceCreateWithData(stored.reference as CFData, nil),
                  let pixels = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else { throw CocoaError(.fileReadCorruptFile) }
            let image = ARReferenceImage(pixels, orientation: .up, physicalWidth: width)
            image.name = id.uuidString
            return Entry(id: id, name: stored.name, image: image)
        }
        guard let reference = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARReferenceObject.self, from: stored.reference) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        reference.name = id.uuidString
        return Entry(id: id, name: stored.name, object: reference)
    }

    private func sortEntries() {
        entries.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func saveSelection() {
        UserDefaults.standard.set(disabledIDs.map(\.uuidString), forKey: Self.disabledKey)
    }
}
