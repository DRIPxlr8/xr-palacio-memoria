import Foundation
import Testing
@testable import PalacioCore

@Test func sampleGlossaryHasBetweenTenAndFifteenTerms() {
    #expect((10...15).contains(Glossary.sample.count))
}

@Test func sampleGlossaryTermsAreComplete() {
    for term in Glossary.sample {
        #expect(term.isComplete, "Término incompleto: \(term.name)")
    }
}

@Test func sampleGlossaryTermsStartWithoutMarker() {
    #expect(Glossary.sample.allSatisfy { !$0.isAnchored })
}

@Test func sampleGlossaryNamesAreUnique() {
    let names = Glossary.sample.map { $0.name.lowercased() }

    #expect(Set(names).count == names.count)
}

@Test func sampleGlossaryIDsAreUnique() {
    let ids = Glossary.sample.map(\.id)

    #expect(Set(ids).count == ids.count)
}
