import Foundation
import Observation
import PalacioCore

/// Estado compartido de la app. Es el único punto de contacto entre la capa AR y la interfaz:
/// ambas leen y escriben aquí, y no se llaman directamente.
///
/// Las vistas lo reciben con `@Environment(AppState.self)`.
@Observable
final class AppState {
    /// Texto de los marcadores sin responder en modo Quiz.
    static let hiddenMarkerLabel = "?"

    /// Modo de uso actual.
    var mode: AppMode = .anchor

    /// Términos disponibles para anclar.
    let glossary: [Term] = Glossary.sample

    /// Términos ya anclados y marcador que está por fijarse. Se modifica con las acciones de abajo.
    private(set) var palace = Palace()

    /// Recorrido guiado del modo Estudio: qué término buscar y cuál tiene la definición abierta.
    private(set) var studyTour = StudyTour()

    /// Quiz sobre los términos anclados: pregunta abierta, respuestas y puntaje.
    private(set) var quiz = Quiz()

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
        termsDidChange()
    }

    /// Descarta el marcador provisorio: el usuario canceló o cambió de modo.
    func cancelPlacement() {
        palace.cancelPlacement()
    }

    /// Borra un término ya anclado.
    func removeTerm(_ term: Term) {
        palace.removeTerm(id: term.id)
        termsDidChange()
    }

    /// El recorrido de estudio y el quiz trabajan sobre los términos anclados.
    private func termsDidChange() {
        studyTour.update(terms: palace.terms)
        quiz.update(terms: palace.terms)
    }

    // MARK: - Marcadores

    /// Texto que la capa AR muestra sobre cada marcador fijado.
    /// En modo Quiz, los términos sin responder se muestran como «?».
    var markerLabels: [UUID: String] {
        guard mode == .quiz else { return palace.namesByMarker }

        return palace.terms.reduce(into: [UUID: String]()) { labels, term in
            guard let markerID = term.markerID else { return }
            labels[markerID] = quiz.answer(for: term.id) == nil ? Self.hiddenMarkerLabel : term.name
        }
    }

    /// Marcadores que la capa AR muestra con un aspecto distinto del normal.
    /// En Estudio, el del término con la definición abierta (nunca el buscado, para no delatar dónde está).
    /// En Quiz, los respondidos según acierto o error, y el de la pregunta abierta.
    var markerStyles: [UUID: MarkerStyle] {
        switch mode {
        case .anchor:
            return [:]
        case .study:
            guard let markerID = studyTour.revealed?.markerID else { return [:] }
            return [markerID: .selected]
        case .quiz:
            var styles = quiz.answersByMarker.mapValues { answer -> MarkerStyle in
                answer == QuizAnswer.correct ? MarkerStyle.correct : MarkerStyle.incorrect
            }
            if let markerID = quiz.current?.markerID {
                styles[markerID] = .selected
            }
            return styles
        }
    }

    /// La capa AR avisa que el usuario tocó un marcador.
    /// En Estudio abre la definición de su término; en Quiz abre su pregunta, si no la ha respondido.
    func selectMarker(_ markerID: UUID) {
        switch mode {
        case .anchor:
            break
        case .study:
            studyTour.select(markerID: markerID)
        case .quiz:
            quiz.select(markerID: markerID)
        }
    }

    /// Cierra lo que esté abierto en el panel: la definición de Estudio o la pregunta del Quiz.
    /// El usuario tocó fuera de un marcador o cambió de modo.
    func closeOpenTerm() {
        studyTour.dismiss()
        quiz.dismiss()
    }

    // MARK: - Estudio (CU2)

    /// Botón «Siguiente término»: pasa a buscar el término que sigue en el recorrido.
    func advanceStudy() {
        studyTour.advance()
    }

    // MARK: - Quiz (CU3)

    /// «Tocar para revelar»: muestra la respuesta de la pregunta abierta.
    func revealQuizAnswer() {
        quiz.reveal()
    }

    /// Botones «Acerté» y «No acerté»: registra la respuesta y cierra la pregunta.
    func answerQuiz(isCorrect: Bool) {
        quiz.answer(isCorrect ? .correct : .incorrect)
    }

    /// «Repetir quiz»: borra las respuestas y empieza de nuevo.
    func restartQuiz() {
        quiz.restart()
    }
}
