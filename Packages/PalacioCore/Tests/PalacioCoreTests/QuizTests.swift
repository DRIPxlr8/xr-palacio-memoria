import Foundation
import Testing
@testable import PalacioCore

/// Términos anclados, cada uno en su propio marcador.
private func makeTerms(_ names: String...) -> [Term] {
    names.map { Term(name: $0, definition: "Definición de \($0).", markerID: UUID()) }
}

/// Marcador de un término de prueba.
private func marker(of term: Term) throws -> UUID {
    try #require(term.markerID)
}

/// Responde un término completo: tocar su marcador, revelar y evaluar.
private func answer(_ term: Term, with answer: QuizAnswer, in quiz: inout Quiz) throws {
    quiz.select(markerID: try marker(of: term))
    quiz.reveal()
    quiz.answer(answer)
}

// MARK: - Inicio

@Test func quizWithoutTermsHasNothingToAsk() {
    let quiz = Quiz()

    #expect(quiz.phase == .noTerms)
    #expect(quiz.count == 0)
    #expect(!quiz.isFinished)
}

@Test func newQuizWaitsForAMarker() {
    let quiz = Quiz(terms: makeTerms("Anclaje", "Raycast"))

    #expect(quiz.phase == .waiting(answered: 0, total: 2))
    #expect(quiz.current == nil)
    #expect(quiz.answeredCount == 0)
    #expect(quiz.correctCount == 0)
    #expect(quiz.termsToReview.isEmpty)
    #expect(!quiz.isFinished)
}

// MARK: - Preguntar

@Test func selectingMarkerOpensItsQuestionWithAnswerHidden() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)

    let term = quiz.select(markerID: try marker(of: terms[1]))

    #expect(term == terms[1])
    #expect(quiz.current == terms[1])
    #expect(!quiz.isAnswerRevealed)
    #expect(quiz.phase == .question(terms[1], isRevealed: false))
}

@Test func selectingUnknownMarkerOpensNoQuestion() {
    var quiz = Quiz(terms: makeTerms("Anclaje"))

    let term = quiz.select(markerID: UUID())

    #expect(term == nil)
    #expect(quiz.phase == .waiting(answered: 0, total: 1))
}

@Test func revealShowsTheAnswerOfTheOpenQuestion() throws {
    let terms = makeTerms("Anclaje")
    var quiz = Quiz(terms: terms)
    quiz.select(markerID: try marker(of: terms[0]))

    quiz.reveal()

    #expect(quiz.isAnswerRevealed)
    #expect(quiz.phase == .question(terms[0], isRevealed: true))
}

@Test func revealWithoutOpenQuestionDoesNothing() {
    var quiz = Quiz(terms: makeTerms("Anclaje"))

    quiz.reveal()

    #expect(!quiz.isAnswerRevealed)
}

@Test func selectingAnotherMarkerHidesTheAnswerAgain() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    quiz.select(markerID: try marker(of: terms[0]))
    quiz.reveal()

    quiz.select(markerID: try marker(of: terms[1]))

    #expect(quiz.current == terms[1])
    #expect(!quiz.isAnswerRevealed)
    #expect(quiz.answer(for: terms[0].id) == nil)
}

@Test func dismissClosesTheQuestionAndLeavesTermPending() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    quiz.select(markerID: try marker(of: terms[0]))
    quiz.reveal()

    quiz.dismiss()

    #expect(quiz.current == nil)
    #expect(!quiz.isAnswerRevealed)
    #expect(quiz.answer(for: terms[0].id) == nil)
    #expect(quiz.phase == .waiting(answered: 0, total: 2))
}

// MARK: - Responder

@Test(arguments: [QuizAnswer.correct, QuizAnswer.incorrect])
func answeringSavesTheAnswerAndClosesTheQuestion(given: QuizAnswer) throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)

    try answer(terms[0], with: given, in: &quiz)

    #expect(quiz.answer(for: terms[0].id) == given)
    #expect(quiz.current == nil)
    #expect(!quiz.isAnswerRevealed)
    #expect(quiz.phase == .waiting(answered: 1, total: 2))
}

@Test func answeringBeforeRevealingDoesNothing() throws {
    let terms = makeTerms("Anclaje")
    var quiz = Quiz(terms: terms)
    quiz.select(markerID: try marker(of: terms[0]))

    quiz.answer(.correct)

    #expect(quiz.answer(for: terms[0].id) == nil)
    #expect(quiz.current == terms[0])
}

@Test func answeringWithoutOpenQuestionDoesNothing() {
    var quiz = Quiz(terms: makeTerms("Anclaje"))

    quiz.answer(.correct)

    #expect(quiz.answeredCount == 0)
}

@Test func answeredTermIsNotAskedAgain() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .incorrect, in: &quiz)

    let term = quiz.select(markerID: try marker(of: terms[0]))

    #expect(term == nil)
    #expect(quiz.current == nil)
    #expect(quiz.answer(for: terms[0].id) == .incorrect)
}

// MARK: - Puntaje y resumen

@Test func scoreCountsOnlyCorrectAnswers() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var quiz = Quiz(terms: terms)

    try answer(terms[0], with: .correct, in: &quiz)
    try answer(terms[1], with: .incorrect, in: &quiz)
    try answer(terms[2], with: .correct, in: &quiz)

    #expect(quiz.correctCount == 2)
    #expect(quiz.answeredCount == 3)
}

@Test func termsToReviewAreTheIncorrectOnesInQuizOrder() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var quiz = Quiz(terms: terms)

    try answer(terms[2], with: .incorrect, in: &quiz)
    try answer(terms[1], with: .correct, in: &quiz)
    try answer(terms[0], with: .incorrect, in: &quiz)

    #expect(quiz.termsToReview == [terms[0], terms[2]])
}

@Test func quizFinishesWhenEveryTermIsAnswered() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)

    try answer(terms[0], with: .correct, in: &quiz)
    #expect(!quiz.isFinished)

    try answer(terms[1], with: .incorrect, in: &quiz)

    #expect(quiz.isFinished)
    #expect(quiz.phase == .finished(correct: 1, total: 2, toReview: [terms[1]]))
}

@Test func perfectQuizHasNothingToReview() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)

    try answer(terms[0], with: .correct, in: &quiz)
    try answer(terms[1], with: .correct, in: &quiz)

    #expect(quiz.phase == .finished(correct: 2, total: 2, toReview: []))
}

@Test func answersByMarkerListsOnlyAnsweredMarkers() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var quiz = Quiz(terms: terms)

    try answer(terms[0], with: .correct, in: &quiz)
    try answer(terms[2], with: .incorrect, in: &quiz)

    let expected: [UUID: QuizAnswer] = [
        try marker(of: terms[0]): .correct,
        try marker(of: terms[2]): .incorrect,
    ]
    #expect(quiz.answersByMarker == expected)
}

// MARK: - Repetir

@Test func restartClearsAnswersAndOpenQuestion() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .correct, in: &quiz)
    quiz.select(markerID: try marker(of: terms[1]))
    quiz.reveal()

    quiz.restart()

    #expect(quiz.phase == .waiting(answered: 0, total: 2))
    #expect(quiz.correctCount == 0)
    #expect(quiz.answersByMarker.isEmpty)
    #expect(!quiz.isAnswerRevealed)
}

@Test func termCanBeAskedAgainAfterRestart() throws {
    let terms = makeTerms("Anclaje")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .incorrect, in: &quiz)
    quiz.restart()

    let term = quiz.select(markerID: try marker(of: terms[0]))

    #expect(term == terms[0])
}

// MARK: - Cambios en los términos

@Test func updateKeepsAnswersOfTermsThatStillExist() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .correct, in: &quiz)

    quiz.update(terms: terms + makeTerms("Oclusión"))

    #expect(quiz.answer(for: terms[0].id) == .correct)
    #expect(quiz.phase == .waiting(answered: 1, total: 3))
}

@Test func updateDropsAnswersOfRemovedTerms() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .incorrect, in: &quiz)

    quiz.update(terms: [terms[1]])

    #expect(quiz.answeredCount == 0)
    #expect(quiz.termsToReview.isEmpty)
    #expect(quiz.phase == .waiting(answered: 0, total: 1))
}

@Test func updateClosesQuestionWhenItsTermWasRemoved() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var quiz = Quiz(terms: terms)
    quiz.select(markerID: try marker(of: terms[0]))
    quiz.reveal()

    quiz.update(terms: [terms[1]])

    #expect(quiz.current == nil)
    #expect(!quiz.isAnswerRevealed)
}

@Test func finishedQuizReopensWhenATermIsAdded() throws {
    let terms = makeTerms("Anclaje")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .correct, in: &quiz)

    quiz.update(terms: terms + makeTerms("Raycast"))

    #expect(!quiz.isFinished)
    #expect(quiz.phase == .waiting(answered: 1, total: 2))
}

@Test func updateWithNoTermsLeavesNothingToAsk() throws {
    let terms = makeTerms("Anclaje")
    var quiz = Quiz(terms: terms)
    try answer(terms[0], with: .correct, in: &quiz)

    quiz.update(terms: [])

    #expect(quiz.phase == .noTerms)
    #expect(quiz.answeredCount == 0)
}
