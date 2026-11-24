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

// MARK: - Inicio

@Test func emptyTourHasNoTarget() {
    var tour = StudyTour()

    let next = tour.advance()

    #expect(next == nil)
    #expect(tour.target == nil)
    #expect(tour.revealed == nil)
    #expect(tour.position == nil)
    #expect(tour.count == 0)
    #expect(!tour.isTargetFound)
}

@Test func newTourTargetsFirstTermWithoutRevealingIt() {
    let terms = makeTerms("Anclaje", "Raycast")

    let tour = StudyTour(terms: terms)

    #expect(tour.target == terms[0])
    #expect(tour.revealed == nil)
    #expect(!tour.isTargetFound)
    #expect(tour.position == 1)
    #expect(tour.count == 2)
}

// MARK: - Tocar marcadores

@Test func selectingTargetMarkerRevealsItAndMarksItFound() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)

    let term = tour.select(markerID: try marker(of: terms[0]))

    #expect(term == terms[0])
    #expect(tour.revealed == terms[0])
    #expect(tour.isTargetFound)
}

@Test func selectingAnotherMarkerRevealsItButKeepsTarget() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var tour = StudyTour(terms: terms)

    let term = tour.select(markerID: try marker(of: terms[2]))

    #expect(term == terms[2])
    #expect(tour.revealed == terms[2])
    #expect(tour.target == terms[0])
    #expect(!tour.isTargetFound)
}

@Test func selectingTargetAfterAnotherMarkerMarksItFound() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[1]))

    tour.select(markerID: try marker(of: terms[0]))

    #expect(tour.revealed == terms[0])
    #expect(tour.isTargetFound)
}

@Test func selectingUnknownMarkerChangesNothing() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[1]))

    let term = tour.select(markerID: UUID())

    #expect(term == nil)
    #expect(tour.revealed == terms[1])
    #expect(tour.target == terms[0])
}

@Test func dismissClosesDefinitionAndKeepsTarget() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[0]))

    tour.dismiss()

    #expect(tour.revealed == nil)
    #expect(!tour.isTargetFound)
    #expect(tour.target == terms[0])
}

// MARK: - Avanzar

@Test func advanceTargetsNextTermAndClosesDefinition() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[0]))

    let next = tour.advance()

    #expect(next == terms[1])
    #expect(tour.target == terms[1])
    #expect(tour.revealed == nil)
    #expect(!tour.isTargetFound)
    #expect(tour.position == 2)
}

@Test func advanceFollowsTheOrderOfTheTerms() {
    var tour = StudyTour(terms: makeTerms("Anclaje", "Raycast", "Oclusión"))

    let first = tour.target?.name
    let rest = (0..<2).map { _ in tour.advance()?.name }

    #expect([first] + rest == ["Anclaje", "Raycast", "Oclusión"])
    #expect(tour.position == 3)
}

@Test func advanceAfterLastTermReturnsToFirst() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()

    let next = tour.advance()

    #expect(next == terms[0])
    #expect(tour.position == 1)
}

@Test func advanceWithoutFindingTargetSkipsIt() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)

    tour.advance()

    #expect(tour.target == terms[1])
}

@Test func tourWithOneTermKeepsTargetingIt() throws {
    let terms = makeTerms("Anclaje")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[0]))

    tour.advance()

    #expect(tour.target == terms[0])
    #expect(tour.revealed == nil)
    #expect(tour.position == 1)
}

// MARK: - Cambios en los términos

@Test func updateOnEmptyTourTargetsFirstTerm() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour()

    tour.update(terms: terms)

    #expect(tour.target == terms[0])
    #expect(tour.count == 2)
}

@Test func updateKeepsTargetAndRevealedWhenTheyStillExist() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()
    tour.select(markerID: try marker(of: terms[1]))

    tour.update(terms: terms + makeTerms("Oclusión"))

    #expect(tour.target == terms[1])
    #expect(tour.revealed == terms[1])
    #expect(tour.isTargetFound)
    #expect(tour.position == 2)
    #expect(tour.count == 3)
}

@Test func updateRestartsAtFirstTermWhenTargetWasRemoved() {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var tour = StudyTour(terms: terms)
    tour.advance()

    tour.update(terms: [terms[0], terms[2]])

    #expect(tour.target == terms[0])
    #expect(tour.position == 1)
}

@Test func updateClosesDefinitionWhenItsTermWasRemoved() throws {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.select(markerID: try marker(of: terms[1]))

    tour.update(terms: [terms[0]])

    #expect(tour.revealed == nil)
    #expect(tour.target == terms[0])
}

@Test func updateWithNoTermsLeavesTourEmpty() {
    var tour = StudyTour(terms: makeTerms("Anclaje"))

    tour.update(terms: [])

    #expect(tour.target == nil)
    #expect(tour.revealed == nil)
    #expect(tour.count == 0)
}
