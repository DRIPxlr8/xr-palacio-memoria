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

    /// Término elegido: el que se va a anclar o el del marcador que se tocó.
    var selectedTerm: Term?
}
