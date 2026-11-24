import Foundation

/// Recorrido guiado del modo Estudio.
///
/// La app le dice al estudiante qué término buscar (`target`). El estudiante recuerda dónde lo dejó,
/// camina hasta ahí y toca su marcador, con lo que se abre la definición (`revealed`).
/// Luego pasa al siguiente término con `advance()`.
///
/// Los términos se buscan en el orden en que se anclaron y, después del último, se vuelve al primero.
public struct StudyTour: Hashable, Sendable {
    /// Términos del recorrido, en orden.
    public private(set) var terms: [Term]

    /// Índice en `terms` del término que hay que buscar, o `nil` si el recorrido está vacío.
    private var targetIndex: Int?

    /// Término cuya definición está abierta.
    private var revealedID: Term.ID?

    public init(terms: [Term] = []) {
        self.terms = terms
        targetIndex = terms.isEmpty ? nil : 0
    }

    /// Término que el estudiante tiene que buscar, o `nil` si el recorrido está vacío.
    public var target: Term? {
        targetIndex.map { terms[$0] }
    }

    /// Término cuya definición está abierta porque el estudiante tocó su marcador, si hay alguno.
    public var revealed: Term? {
        terms.first { $0.id == revealedID }
    }

    /// Indica si el estudiante encontró el término buscado: tocó su marcador y tiene su definición abierta.
    public var isTargetFound: Bool {
        revealedID != nil && revealedID == target?.id
    }

    /// Cantidad de términos del recorrido.
    public var count: Int {
        terms.count
    }

    /// Posición del término buscado, partiendo en 1, o `nil` si el recorrido está vacío.
    public var position: Int? {
        targetIndex.map { $0 + 1 }
    }

    /// El estudiante tocó un marcador: abre la definición de su término y lo devuelve.
    /// Sirve tanto si es el término buscado como si es otro.
    /// Si ningún término usa ese marcador, devuelve `nil` y no cambia nada.
    @discardableResult
    public mutating func select(markerID: UUID) -> Term? {
        guard let term = terms.first(where: { $0.markerID == markerID }) else { return nil }

        revealedID = term.id
        return term
    }

    /// Cierra la definición abierta. El término buscado sigue siendo el mismo.
    public mutating func dismiss() {
        revealedID = nil
    }

    /// Pasa a buscar el siguiente término, cierra la definición abierta y devuelve el nuevo término buscado.
    /// Después del último vuelve al primero. Devuelve `nil` si el recorrido está vacío.
    @discardableResult
    public mutating func advance() -> Term? {
        guard let index = targetIndex else { return nil }

        targetIndex = (index + 1) % terms.count
        revealedID = nil
        return target
    }

    /// Reemplaza los términos del recorrido, por ejemplo después de anclar o borrar uno.
    /// Mantiene el término buscado y la definición abierta si siguen existiendo.
    /// Si el término buscado ya no está, se parte de nuevo por el primero.
    public mutating func update(terms newTerms: [Term]) {
        let targetID = target?.id
        terms = newTerms

        targetIndex = newTerms.firstIndex { $0.id == targetID } ?? (newTerms.isEmpty ? nil : 0)
        if !newTerms.contains(where: { $0.id == revealedID }) {
            revealedID = nil
        }
    }
}
