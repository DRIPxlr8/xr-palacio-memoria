import PalacioCore

/// Lo que muestra el panel del modo Quiz en cada momento.
enum QuizPhase {
    /// No hay términos anclados para preguntar.
    case noTerms
    /// Esperando que el usuario toque un marcador.
    case waiting(answered: Int, total: Int)
    /// El usuario tocó un marcador: la respuesta está oculta o ya se reveló.
    case question(Term, isRevealed: Bool)
    /// Ya respondió todos los términos.
    case finished(correct: Int, total: Int, toReview: [Term])
}
