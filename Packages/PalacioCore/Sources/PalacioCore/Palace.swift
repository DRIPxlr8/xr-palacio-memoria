import Foundation

/// Palacio de memoria del estudiante: los términos que ya ancló en su sala
/// y el marcador que está por fijar.
///
/// Para anclar un término: `beginPlacement(markerID:)` cuando el estudiante toca una superficie,
/// y luego `confirmPlacement(name:definition:)` o `cancelPlacement()`.
public struct Palace: Hashable, Sendable {
    /// Términos anclados, en el orden en que se fijaron.
    public private(set) var terms: [Term] = []

    /// Marcador provisorio que espera su término, o `nil` si no se está anclando nada.
    public private(set) var pendingMarkerID: UUID?

    public init() {}

    /// Indica si hay un marcador esperando su término.
    public var isPlacing: Bool {
        pendingMarkerID != nil
    }

    /// Empieza a anclar un término en el marcador indicado.
    /// Si ya había un marcador pendiente, lo reemplaza. Si el marcador ya tiene un término, no hace nada.
    public mutating func beginPlacement(markerID: UUID) {
        guard term(forMarker: markerID) == nil else { return }
        pendingMarkerID = markerID
    }

    /// Fija el término en el marcador pendiente y lo devuelve.
    /// Devuelve `nil`, sin cambiar nada, si no hay marcador pendiente o si falta el nombre o la definición.
    @discardableResult
    public mutating func confirmPlacement(name: String, definition: String) -> Term? {
        guard let markerID = pendingMarkerID else { return nil }

        let term = Term(name: name, definition: definition, markerID: markerID)
        guard term.isComplete else { return nil }

        terms.append(term)
        pendingMarkerID = nil
        return term
    }

    /// Descarta el marcador pendiente, si lo hay.
    public mutating func cancelPlacement() {
        pendingMarkerID = nil
    }

    /// Borra un término anclado y lo devuelve, o devuelve `nil` si no existe.
    @discardableResult
    public mutating func removeTerm(id: Term.ID) -> Term? {
        guard let index = terms.firstIndex(where: { $0.id == id }) else { return nil }
        return terms.remove(at: index)
    }

    /// Término anclado en el marcador indicado, si lo hay.
    public func term(forMarker markerID: UUID) -> Term? {
        terms.first { $0.markerID == markerID }
    }

    /// Nombre del término de cada marcador fijado. Es lo que la capa AR muestra sobre cada uno.
    public var namesByMarker: [UUID: String] {
        terms.reduce(into: [:]) { names, term in
            if let markerID = term.markerID {
                names[markerID] = term.name
            }
        }
    }
}
