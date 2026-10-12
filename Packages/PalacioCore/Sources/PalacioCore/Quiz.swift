import Foundation

/// Quiz de autoevaluación sobre los términos anclados.
///
/// El estudiante toca un marcador (`select(markerID:)`), intenta recordar qué término dejó ahí,
/// revela la respuesta (`reveal()`) y marca si acertó (`answer(_:)`). Cada término se responde
/// una sola vez. Cuando están todos respondidos, el quiz termina y entrega el puntaje
/// y los términos a repasar.
public struct Quiz: Hashable, Sendable {
    /// Términos del quiz, en el orden en que se anclaron.
    public private(set) var terms: [Term]

    /// Respuesta de cada término ya respondido.
    private var answers: [Term.ID: QuizAnswer] = [:]

    /// Término de la pregunta abierta.
    private var currentID: Term.ID?

    /// Indica si ya se reveló la respuesta de la pregunta abierta.
    public private(set) var isAnswerRevealed = false

    public init(terms: [Term] = []) {
        self.terms = terms
    }

    // MARK: - Estado

    /// Término de la pregunta abierta, si hay alguna.
    public var current: Term? {
        terms.first { $0.id == currentID }
    }

    /// Respuesta que el estudiante dio para un término, o `nil` si todavía no lo responde.
    public func answer(for termID: Term.ID) -> QuizAnswer? {
        answers[termID]
    }

    /// Cantidad de términos del quiz.
    public var count: Int {
        terms.count
    }

    /// Cantidad de términos ya respondidos.
    public var answeredCount: Int {
        answers.count
    }

    /// Puntaje: cantidad de términos marcados como «Acerté».
    public var correctCount: Int {
        answers.values.filter { $0 == .correct }.count
    }

    /// Términos marcados como «No acerté», en el orden del quiz.
    public var termsToReview: [Term] {
        terms.filter { answers[$0.id] == .incorrect }
    }

    /// Indica si el estudiante ya respondió todos los términos. Un quiz sin términos no está terminado.
    public var isFinished: Bool {
        !terms.isEmpty && answeredCount == terms.count
    }

    /// Respuesta de cada marcador ya respondido. Es lo que la capa AR usa para pintar los marcadores.
    public var answersByMarker: [UUID: QuizAnswer] {
        terms.reduce(into: [:]) { result, term in
            if let markerID = term.markerID, let answer = answers[term.id] {
                result[markerID] = answer
            }
        }
    }

    /// Momento en que está el quiz, para el panel.
    public var phase: QuizPhase {
        if terms.isEmpty {
            return .noTerms
        }
        if let current {
            return .question(current, isRevealed: isAnswerRevealed)
        }
        if isFinished {
            return .finished(correct: correctCount, total: count, toReview: termsToReview)
        }
        return .waiting(answered: answeredCount, total: count)
    }

    // MARK: - Acciones

    /// El estudiante tocó un marcador: abre la pregunta de su término, con la respuesta oculta, y lo devuelve.
    /// Devuelve `nil`, sin cambiar nada, si ningún término usa ese marcador o si ya lo respondió.
    @discardableResult
    public mutating func select(markerID: UUID) -> Term? {
        guard let term = terms.first(where: { $0.markerID == markerID }),
              answers[term.id] == nil
        else { return nil }

        currentID = term.id
        isAnswerRevealed = false
        return term
    }

    /// Revela la respuesta de la pregunta abierta. Sin pregunta abierta no hace nada.
    public mutating func reveal() {
        guard currentID != nil else { return }
        isAnswerRevealed = true
    }

    /// Registra la respuesta de la pregunta abierta y la cierra.
    /// No hace nada si no hay pregunta abierta o si la respuesta todavía no se revela.
    public mutating func answer(_ answer: QuizAnswer) {
        guard let currentID, isAnswerRevealed else { return }

        answers[currentID] = answer
        dismiss()
    }

    /// Cierra la pregunta abierta sin responderla. El término queda pendiente.
    public mutating func dismiss() {
        currentID = nil
        isAnswerRevealed = false
    }

    /// Empieza el quiz de nuevo: borra todas las respuestas y cierra la pregunta abierta.
    public mutating func restart() {
        answers = [:]
        dismiss()
    }

    /// Reemplaza los términos del quiz, por ejemplo después de anclar o borrar uno.
    /// Conserva las respuestas de los términos que siguen existiendo.
    public mutating func update(terms newTerms: [Term]) {
        terms = newTerms

        let ids = Set(newTerms.map(\.id))
        answers = answers.filter { ids.contains($0.key) }
        if let currentID, !ids.contains(currentID) {
            dismiss()
        }
    }
}
