import Testing
@testable import PalacioCore

@Test func versionIsDefined() {
    #expect(!PalacioCore.version.isEmpty)
}
