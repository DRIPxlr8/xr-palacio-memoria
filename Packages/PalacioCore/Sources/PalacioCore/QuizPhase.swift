import Foundation

/// Momento en que está el quiz. Es lo que muestra el panel del modo Quiz.
public enum QuizPhase: Hashable, Sendable {
    /// No hay términos anclados para preguntar.
    case noTerms
    /// Esperando que el estudiante toque un marcador.
    case waiting(answered: Int, total: Int)
    /// El estudiante tocó un marcador: la respuesta está oculta o ya se reveló.
    case question(Term, isRevealed: Bool)
    /// Ya respondió todos los términos.
    case finished(correct: Int, total: Int, toReview: [Term])
}
