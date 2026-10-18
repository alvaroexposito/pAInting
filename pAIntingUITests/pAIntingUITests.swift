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
        XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 10))
    }

    /// Six cards are offered at each of the three steps, and Back undoes a pick.
    @MainActor
    func testCardsAdvanceThroughThreeSteps() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
        for _ in 0..<2 {
            let card = app.buttons["ideas.card.0"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["ideas.card.5"].exists)
            card.tap()
        }
        let back = app.buttons["ideas.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 5))
    }

    /// En el simulador no hay Image Playground: se usa la silueta simulada.
    @MainActor
    func testGenerateOpensColoringAndUndo() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()
        // Picks an animal, clothes and an accessory: no typing needed.
        for _ in 0..<3 {
            let card = app.buttons["ideas.card.0"]
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            card.tap()
        }

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
