import Foundation
import Testing
@testable import PalacioCore

/// Palacio con un término ya anclado en el marcador indicado.
private func makePalace(withTermNamed name: String, at markerID: UUID) -> Palace {
    var palace = Palace()
    palace.beginPlacement(markerID: markerID)
    palace.confirmPlacement(name: name, definition: "Definición de \(name).")
    return palace
}

@Test func newPalaceIsEmpty() {
    let palace = Palace()

    #expect(palace.terms.isEmpty)
    #expect(palace.pendingMarkerID == nil)
    #expect(!palace.isPlacing)
}

@Test func beginPlacementKeepsMarkerPending() {
    let markerID = UUID()
    var palace = Palace()

    palace.beginPlacement(markerID: markerID)

    #expect(palace.pendingMarkerID == markerID)
    #expect(palace.isPlacing)
    #expect(palace.terms.isEmpty)
}

@Test func beginPlacementReplacesPreviousPendingMarker() {
    let second = UUID()
    var palace = Palace()

    palace.beginPlacement(markerID: UUID())
    palace.beginPlacement(markerID: second)

    #expect(palace.pendingMarkerID == second)
}

@Test func beginPlacementIgnoresMarkerThatAlreadyHasTerm() {
    let markerID = UUID()
    var palace = makePalace(withTermNamed: "Anclaje", at: markerID)

    palace.beginPlacement(markerID: markerID)

    #expect(!palace.isPlacing)
    #expect(palace.terms.count == 1)
}

@Test func confirmPlacementSavesTermWithItsMarker() throws {
    let markerID = UUID()
    var palace = Palace()
    palace.beginPlacement(markerID: markerID)

    let confirmed = palace.confirmPlacement(name: " Anclaje ", definition: "Punto fijo del mundo real.")
    let term = try #require(confirmed)

    #expect(term.name == "Anclaje")
    #expect(term.markerID == markerID)
    #expect(palace.terms == [term])
    #expect(!palace.isPlacing)
}

@Test func confirmPlacementWithoutPendingMarkerDoesNothing() {
    var palace = Palace()

    let term = palace.confirmPlacement(name: "Anclaje", definition: "Punto fijo del mundo real.")

    #expect(term == nil)
    #expect(palace.terms.isEmpty)
}

@Test(arguments: [
    ("", "Punto fijo del mundo real."),
    ("Anclaje", "   "),
])
func confirmPlacementWithIncompleteTermKeepsMarkerPending(name: String, definition: String) {
    let markerID = UUID()
    var palace = Palace()
    palace.beginPlacement(markerID: markerID)

    let term = palace.confirmPlacement(name: name, definition: definition)

    #expect(term == nil)
    #expect(palace.terms.isEmpty)
    #expect(palace.pendingMarkerID == markerID)
}

@Test func cancelPlacementDiscardsPendingMarker() {
    var palace = Palace()
    palace.beginPlacement(markerID: UUID())

    palace.cancelPlacement()

    #expect(!palace.isPlacing)
    #expect(palace.terms.isEmpty)
}

@Test func cancelPlacementKeepsAnchoredTerms() {
    var palace = makePalace(withTermNamed: "Anclaje", at: UUID())
    palace.beginPlacement(markerID: UUID())

    palace.cancelPlacement()

    #expect(palace.terms.map(\.name) == ["Anclaje"])
}

@Test func termsKeepTheOrderInWhichTheyWereAnchored() {
    var palace = Palace()

    for name in ["Anclaje", "Raycast", "Oclusión"] {
        palace.beginPlacement(markerID: UUID())
        palace.confirmPlacement(name: name, definition: "Definición de \(name).")
    }

    #expect(palace.terms.map(\.name) == ["Anclaje", "Raycast", "Oclusión"])
}

@Test func removeTermDeletesOnlyThatTerm() throws {
    var palace = makePalace(withTermNamed: "Anclaje", at: UUID())
    palace.beginPlacement(markerID: UUID())
    palace.confirmPlacement(name: "Raycast", definition: "Rayo desde la pantalla.")
    let anchorTerm = try #require(palace.terms.first)

    let removed = palace.removeTerm(id: anchorTerm.id)

    #expect(removed == anchorTerm)
    #expect(palace.terms.map(\.name) == ["Raycast"])
}

@Test func removeTermWithUnknownIDDoesNothing() {
    var palace = makePalace(withTermNamed: "Anclaje", at: UUID())

    let removed = palace.removeTerm(id: UUID())

    #expect(removed == nil)
    #expect(palace.terms.count == 1)
}

@Test func termForMarkerFindsTheAnchoredTerm() {
    let markerID = UUID()
    let palace = makePalace(withTermNamed: "Anclaje", at: markerID)

    #expect(palace.term(forMarker: markerID)?.name == "Anclaje")
    #expect(palace.term(forMarker: UUID()) == nil)
}

@Test func removedTermFreesItsMarker() throws {
    let markerID = UUID()
    var palace = makePalace(withTermNamed: "Anclaje", at: markerID)
    let term = try #require(palace.terms.first)

    palace.removeTerm(id: term.id)

    #expect(palace.term(forMarker: markerID) == nil)
}
