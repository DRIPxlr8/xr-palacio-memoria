import Foundation

/// Recorrido del modo Estudio: cuál es el término actual y cuál sigue.
///
/// Los términos se recorren en el orden en que se anclaron y, después del último, se vuelve al primero.
/// El recorrido parte sin término actual: lo fija el estudiante al tocar un marcador o al pedir el siguiente.
public struct StudyTour: Hashable, Sendable {
    /// Términos del recorrido, en orden.
    public private(set) var terms: [Term]

    /// Índice del término actual en `terms`, o `nil` si todavía no se elige ninguno.
    private var currentIndex: Int?

    public init(terms: [Term] = []) {
        self.terms = terms
    }

    /// Término que el estudiante está repasando, si hay alguno.
    public var current: Term? {
        currentIndex.map { terms[$0] }
    }

    /// Cantidad de términos del recorrido.
    public var count: Int {
        terms.count
    }

    /// Posición del término actual, partiendo en 1, o `nil` si no hay término actual.
    public var position: Int? {
        currentIndex.map { $0 + 1 }
    }

    /// Pasa al siguiente término y lo devuelve. Sin término actual, parte por el primero;
    /// después del último, vuelve al primero. Devuelve `nil` si el recorrido está vacío.
    @discardableResult
    public mutating func advance() -> Term? {
        guard !terms.isEmpty else { return nil }

        currentIndex = currentIndex.map { ($0 + 1) % terms.count } ?? 0
        return current
    }

    /// Deja como actual el término anclado en el marcador indicado y lo devuelve.
    /// Si ningún término usa ese marcador, devuelve `nil` y no cambia el término actual.
    @discardableResult
    public mutating func select(markerID: UUID) -> Term? {
        guard let index = terms.firstIndex(where: { $0.markerID == markerID }) else { return nil }

        currentIndex = index
        return current
    }

    /// Reemplaza los términos del recorrido, por ejemplo después de anclar o borrar uno.
    /// Mantiene el término actual si sigue existiendo; si no, el recorrido queda sin término actual.
    public mutating func update(terms newTerms: [Term]) {
        let currentID = current?.id
        terms = newTerms
        currentIndex = newTerms.firstIndex { $0.id == currentID }
    }
}
