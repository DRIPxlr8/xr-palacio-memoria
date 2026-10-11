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

    /// Términos ya anclados y marcador que está por fijarse. Se modifica con las acciones de abajo.
    private(set) var palace = Palace()

    /// Recorrido del modo Estudio sobre los términos anclados.
    private(set) var studyTour = StudyTour()

    /// Término abierto en el panel superior: el del marcador tocado en Estudio
    /// o el que se está preguntando en Quiz.
    var selectedTerm: Term?

    // MARK: - Anclar (CU1)

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
        studyTour.update(terms: palace.terms)
    }

    /// Descarta el marcador provisorio: el usuario canceló o cambió de modo.
    func cancelPlacement() {
        palace.cancelPlacement()
    }

    /// Borra un término ya anclado.
    func removeTerm(_ term: Term) {
        palace.removeTerm(id: term.id)
        studyTour.update(terms: palace.terms)
        if selectedTerm?.id == term.id {
            selectedTerm = nil
        }
    }

    // MARK: - Estudio (CU2)

    /// Término que se está repasando en modo Estudio, si hay alguno.
    var currentStudyTerm: Term? {
        studyTour.current
    }

    /// Marcador que la capa AR debe resaltar: el del término que se repasa, solo en modo Estudio.
    var highlightedMarkerID: UUID? {
        mode == .study ? studyTour.current?.markerID : nil
    }

    /// La capa AR avisa que el usuario tocó un marcador.
    /// En modo Estudio, su término pasa a ser el que se repasa.
    func selectMarker(_ markerID: UUID) {
        guard mode == .study else { return }
        studyTour.select(markerID: markerID)
    }

    /// Botón «Siguiente término»: pasa al término que sigue en el recorrido.
    func advanceStudy() {
        studyTour.advance()
    }
}
