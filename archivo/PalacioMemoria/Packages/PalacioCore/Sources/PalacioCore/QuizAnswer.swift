import Foundation

/// Cómo se evaluó el estudiante en un término del quiz.
public enum QuizAnswer: Hashable, Sendable {
    /// Recordó el término: marcó «Acerté».
    case correct
    /// No lo recordó: marcó «No acerté».
    case incorrect
}
