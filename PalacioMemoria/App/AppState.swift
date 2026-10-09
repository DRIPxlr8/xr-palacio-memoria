import Foundation
import Observation
import PalacioCore

/// Estado compartido de la app. Es el único punto de contacto entre la capa AR y la interfaz:
/// ambas leen y escriben aquí, y no se llaman directamente.
///
/// Las vistas lo reciben con `@Environment(AppState.self)`.
@Observable
final class AppState {
    /// Modo de uso actual.
    var mode: AppMode = .anchor

    /// Términos disponibles para anclar.
    let glossary: [Term] = Glossary.sample

    /// Término elegido: el del marcador que se tocó.
    var selectedTerm: Term?

    /// Términos ya anclados y marcador que está por fijarse. Se modifica con las acciones de abajo.
    private(set) var palace = Palace()

    /// `true` cuando el usuario tocó una superficie y falta completar el término.
    var isPlacingTerm: Bool {
        palace.isPlacing
    }

    /// La capa AR avisa que creó un marcador provisorio al tocar una superficie.
    /// Solo tiene efecto en modo Anclar.
    func beginPlacement(markerID: UUID) {
        guard mode == .anchor else { return }
        palace.beginPlacement(markerID: markerID)
    }

    /// Fija el término del formulario en el marcador provisorio.
    /// No hace nada si falta el nombre o la definición.
    func confirmPlacement(name: String, definition: String) {
        palace.confirmPlacement(name: name, definition: definition)
    }

    /// Descarta el marcador provisorio: el usuario canceló o cambió de modo.
    func cancelPlacement() {
        palace.cancelPlacement()
    }

    /// Borra un término ya anclado.
    func removeTerm(_ term: Term) {
        palace.removeTerm(id: term.id)
        if selectedTerm?.id == term.id {
            selectedTerm = nil
        }
    }
}
