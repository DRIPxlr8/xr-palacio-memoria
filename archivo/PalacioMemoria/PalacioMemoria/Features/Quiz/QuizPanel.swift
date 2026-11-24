import SwiftUI
import PalacioCore

/// Panel del modo Quiz (CU3).
///
/// Pide acercarse a un marcador «?» y tocarlo. Al tocarlo pregunta qué término está ahí,
/// deja revelar la respuesta y marcar Acerté / No acerté. Al responder todos, muestra el resumen.
struct QuizPanel: View {
    let phase: QuizPhase
    let onReveal: () -> Void
    /// Recibe `true` si el usuario acertó.
    let onAnswer: (Bool) -> Void
    let onRestart: () -> Void

    var body: some View {
        switch phase {
        case .noTerms:
            ContentUnavailableView {
                Label("Tu palacio está vacío", systemImage: AppMode.quiz.systemImage)
            } description: {
                Text("Ancla términos en el modo Anclar para hacer el quiz.")
            }

        case .waiting(let answered, let total):
            ContentUnavailableView {
                Label("Ponte a prueba", systemImage: AppMode.quiz.systemImage)
            } description: {
                if answered > 0 {
                    Text("Acércate a otro marcador «?» y tócalo.\nRespondidos \(answered) de \(total).")
                } else {
                    Text("Acércate a un marcador «?», intenta recordar qué término dejaste ahí y tócalo.")
                }
            }

        case .question(let term, let isRevealed):
            QuizQuestionCard(term: term, isRevealed: isRevealed, onReveal: onReveal, onAnswer: onAnswer)

        case .finished(let correct, let total, let toReview):
            QuizSummaryView(correct: correct, total: total, toReview: toReview, onRestart: onRestart)
        }
    }
}

#Preview("Esperando") {
    QuizPanel(phase: .waiting(answered: 2, total: 5), onReveal: {}, onAnswer: { _ in }, onRestart: {})
}

#Preview("Pregunta") {
    QuizPanel(phase: .question(Glossary.sample[0], isRevealed: false), onReveal: {}, onAnswer: { _ in }, onRestart: {})
}

#Preview("Resumen") {
    QuizPanel(
        phase: .finished(correct: 3, total: 5, toReview: Array(Glossary.sample.prefix(2))),
        onReveal: {}, onAnswer: { _ in }, onRestart: {}
    )
}
