import XCTest

final class StudyFlowTests: XCTestCase {
    @MainActor
    func testWelcomeMakesSpatialSessionTheEntryPoint() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Palacio anatómico"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Estudia en tu espacio"].exists)
        let camera = app.buttons["open-palace-camera"]
        let unavailable = app.descendants(matching: .any)["spatial-device-required"].firstMatch
        XCTAssertTrue(camera.exists || unavailable.exists)
        XCTAssertFalse(app.buttons["mode-quiz"].exists)
        XCTAssertFalse(app.buttons["Ver en 3D"].exists)
    }
}
