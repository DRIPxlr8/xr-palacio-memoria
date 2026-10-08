import Foundation
import Testing
@testable import PalacioCore

@Test func termTrimsNameAndDefinition() {
    let term = Term(name: "  Anclaje \n", definition: "\tPunto fijo del mundo real.  ")

    #expect(term.name == "Anclaje")
    #expect(term.definition == "Punto fijo del mundo real.")
}

@Test func termWithNameAndDefinitionIsComplete() {
    #expect(Term(name: "Anclaje", definition: "Punto fijo del mundo real.").isComplete)
}

@Test(arguments: [
    ("", "Punto fijo del mundo real."),
    ("Anclaje", ""),
    ("   ", "Punto fijo del mundo real."),
    ("Anclaje", " \n "),
])
func termMissingNameOrDefinitionIsNotComplete(name: String, definition: String) {
    #expect(!Term(name: name, definition: definition).isComplete)
}

@Test func termStartsWithoutMarker() {
    let term = Term(name: "Anclaje", definition: "Punto fijo del mundo real.")

    #expect(term.markerID == nil)
    #expect(!term.isAnchored)
}

@Test func termWithMarkerIsAnchored() {
    let markerID = UUID()
    let term = Term(name: "Anclaje", definition: "Punto fijo del mundo real.", markerID: markerID)

    #expect(term.markerID == markerID)
    #expect(term.isAnchored)
}

@Test func termsCreatedSeparatelyHaveDifferentIDs() {
    let first = Term(name: "Anclaje", definition: "Punto fijo del mundo real.")
    let second = Term(name: "Anclaje", definition: "Punto fijo del mundo real.")

    #expect(first.id != second.id)
}
