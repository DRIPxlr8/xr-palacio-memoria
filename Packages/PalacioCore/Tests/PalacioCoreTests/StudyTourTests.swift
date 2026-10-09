import Foundation
import Testing
@testable import PalacioCore

/// Términos anclados, cada uno en su propio marcador.
private func makeTerms(_ names: String...) -> [Term] {
    names.map { Term(name: $0, definition: "Definición de \($0).", markerID: UUID()) }
}

@Test func newTourHasNoCurrentTerm() {
    let tour = StudyTour(terms: makeTerms("Anclaje", "Raycast"))

    #expect(tour.current == nil)
    #expect(tour.position == nil)
    #expect(tour.count == 2)
}

@Test func emptyTourHasNothingToAdvanceTo() {
    var tour = StudyTour()

    let term = tour.advance()

    #expect(term == nil)
    #expect(tour.current == nil)
    #expect(tour.count == 0)
}

@Test func firstAdvanceStartsAtFirstTerm() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)

    let term = tour.advance()

    #expect(term == terms[0])
    #expect(tour.current == terms[0])
    #expect(tour.position == 1)
}

@Test func advanceFollowsTheOrderOfTheTerms() {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var tour = StudyTour(terms: terms)

    let visited = (0..<3).map { _ in tour.advance()?.name }

    #expect(visited == ["Anclaje", "Raycast", "Oclusión"])
    #expect(tour.position == 3)
}

@Test func advanceAfterLastTermReturnsToFirst() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()
    tour.advance()

    let term = tour.advance()

    #expect(term == terms[0])
    #expect(tour.position == 1)
}

@Test func tourWithOneTermStaysOnIt() {
    let terms = makeTerms("Anclaje")
    var tour = StudyTour(terms: terms)

    tour.advance()
    tour.advance()

    #expect(tour.current == terms[0])
    #expect(tour.position == 1)
}

@Test func selectMarkerMakesItsTermCurrent() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var tour = StudyTour(terms: terms)
    let markerID = try #require(terms[2].markerID)

    let term = tour.select(markerID: markerID)

    #expect(term == terms[2])
    #expect(tour.current == terms[2])
    #expect(tour.position == 3)
}

@Test func advanceContinuesFromSelectedTerm() throws {
    let terms = makeTerms("Anclaje", "Raycast", "Oclusión")
    var tour = StudyTour(terms: terms)
    let markerID = try #require(terms[1].markerID)
    tour.select(markerID: markerID)

    let term = tour.advance()

    #expect(term == terms[2])
}

@Test func selectUnknownMarkerKeepsCurrentTerm() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()

    let term = tour.select(markerID: UUID())

    #expect(term == nil)
    #expect(tour.current == terms[0])
}

@Test func updateKeepsCurrentTermWhenItStillExists() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()
    tour.advance()

    tour.update(terms: makeTerms("Oclusión") + terms)

    #expect(tour.current == terms[1])
    #expect(tour.position == 3)
    #expect(tour.count == 3)
}

@Test func updateClearsCurrentTermWhenItWasRemoved() {
    let terms = makeTerms("Anclaje", "Raycast")
    var tour = StudyTour(terms: terms)
    tour.advance()

    tour.update(terms: [terms[1]])

    #expect(tour.current == nil)
    #expect(tour.position == nil)
    #expect(tour.count == 1)
}

@Test func updateWithoutCurrentTermOnlyReplacesTerms() {
    var tour = StudyTour(terms: makeTerms("Anclaje"))

    tour.update(terms: makeTerms("Raycast", "Oclusión"))

    #expect(tour.current == nil)
    #expect(tour.count == 2)

    let term = tour.advance()

    #expect(term?.name == "Raycast")
}
