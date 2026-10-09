import Foundation

/// Término técnico que el estudiante ubica en su palacio de memoria.
public struct Term: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// Nombre del término, sin espacios al inicio ni al final.
    public let name: String
    /// Definición del término, sin espacios al inicio ni al final.
    public let definition: String
    /// Identificador del marcador donde está anclado, o `nil` si todavía no se ancla.
    /// Lo genera la capa AR; PalacioCore no conoce tipos de ARKit.
    public var markerID: UUID?

    public init(id: UUID = UUID(), name: String, definition: String, markerID: UUID? = nil) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.definition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        self.markerID = markerID
    }

    /// Indica si tiene nombre y definición, es decir, si se puede anclar.
    public var isComplete: Bool {
        !name.isEmpty && !definition.isEmpty
    }

    /// Indica si ya está anclado a un marcador.
    public var isAnchored: Bool {
        markerID != nil
    }
}
