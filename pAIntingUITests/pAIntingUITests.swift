import XCTest

final class pAIntingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingLeadsToTabs() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "NO"]
        app.launch()
        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        // En iOS 26 la barra de pestañas no se expone como `tabBars`;
        // se comprueba que aparece la pestaña Create, la primera.
        XCTAssertTrue(app.textFields["create.prompt"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testGenerateEnablesWithPrompt() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
        let generate = app.buttons["create.generate"]
        XCTAssertTrue(generate.waitForExistence(timeout: 10))
        XCTAssertFalse(generate.isEnabled)
        let field = app.textFields["create.prompt"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("sunset")
        XCTAssertTrue(generate.isEnabled)
    }

    /// En el simulador no hay Image Playground: se usa la silueta simulada.
    @MainActor
    func testGenerateOpensColoringAndUndo() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
        let field = app.textFields["create.prompt"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("house")
        app.buttons["create.generate"].tap()

        let canvas = app.otherElements["coloring.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        let undo = app.buttons["coloring.undo"]
        XCTAssertFalse(undo.isEnabled)

        app.buttons["coloring.color.4"].tap()
        // Cielo, arriba a la izquierda de la silueta.
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: undo)
        waitForExpectations(timeout: 5)

        undo.tap()
        XCTAssertFalse(undo.isEnabled)
    }
}
