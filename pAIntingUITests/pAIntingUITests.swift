import XCTest

final class pAIntingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app past the onboarding, with deterministic services.
    @MainActor
    private func launchApp(_ arguments: [String] = ["--mock-services"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"] + arguments
        app.launch()
        return app
    }

    /// Progress slot of the given step (0 animal, 1 clothes, 2 accessory).
    @MainActor
    private func slot(_ step: Int, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["ideas.slot.\(step)"]
    }

    /// Taps the first card of `step` and waits until the pick is registered.
    @MainActor
    private func pickFirstCard(step: Int, in app: XCUIApplication) {
        let card = app.buttons["ideas.card.0"]
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.tap()
        let selected = NSPredicate(format: "isSelected == true")
        expectation(for: selected, evaluatedWith: slot(step, in: app))
        waitForExpectations(timeout: 15)
    }

    /// CL-5: after the onboarding the animal cards are shown straight away.
    @MainActor
    func testOnboardingLeadsToCards() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--reset-onboarding", "--mock-services"]
        app.launch()
        let start = app.buttons["onboarding.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        start.tap()
        XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 15))
    }

    /// RF-1 to RF-6: six picture cards without visible text at each of the
    /// three steps. CL-1: Back undoes the last pick.
    @MainActor
    func testCardsAdvanceThroughThreeSteps() throws {
        let app = launchApp()
        for step in 0..<3 {
            XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 15))
            for index in 0..<6 {
                let card = app.buttons["ideas.card.\(index)"]
                XCTAssertTrue(card.exists, "Missing card \(index) at step \(step)")
                // The name is only exposed to VoiceOver, never drawn as text.
                XCTAssertFalse(app.staticTexts[card.label].exists, "Card \(card.label) shows text")
            }
            XCTAssertFalse(app.buttons["ideas.card.6"].exists)
            if step < 2 {
                pickFirstCard(step: step, in: app)
            }
        }

        let back = app.buttons["ideas.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 15))
        back.tap()
        let unselected = NSPredicate(format: "isSelected == false")
        expectation(for: unselected, evaluatedWith: slot(1, in: app))
        waitForExpectations(timeout: 15)
        XCTAssertTrue(slot(0, in: app).isSelected)
        XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 15))
    }

    /// RF-7 to RF-9 and completion criterion: picking three cards, without
    /// typing, opens the coloring screen with a generated image.
    @MainActor
    func testGenerateOpensColoringAndUndo() throws {
        let app = launchApp()
        for step in 0..<2 {
            pickFirstCard(step: step, in: app)
        }
        // The last pick starts the generation straight away and the cards are
        // reset once the coloring screen opens, so wait for the canvas instead.
        let accessory = app.buttons["ideas.card.0"]
        XCTAssertTrue(accessory.waitForExistence(timeout: 15))
        accessory.tap()

        let canvas = app.otherElements["coloring.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 15))
        let undo = app.buttons["coloring.undo"]
        XCTAssertFalse(undo.isEnabled)

        app.buttons["coloring.color.4"].tap()
        // Sky, at the top left of the outline.
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05)).tap()
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: undo)
        waitForExpectations(timeout: 15)

        undo.tap()
        XCTAssertFalse(undo.isEnabled)
    }

    /// CL-3: a failed generation shows an icon (no text) and can be retried
    /// keeping the three picks. CL-2: Start over clears them.
    @MainActor
    func testFailedGenerationCanBeRetriedOrRestarted() throws {
        let app = launchApp(["--failing-image-generation"])
        for step in 0..<3 {
            pickFirstCard(step: step, in: app)
        }

        let error = app.images["create.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts[error.label].exists)

        let retry = app.buttons["create.generate"]
        XCTAssertTrue(retry.waitForExistence(timeout: 15))
        retry.tap()
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        for step in 0..<3 {
            XCTAssertTrue(slot(step, in: app).isSelected, "Pick \(step) was lost")
        }

        app.buttons["create.restart"].tap()
        XCTAssertTrue(app.buttons["ideas.card.0"].waitForExistence(timeout: 15))
        for step in 0..<3 {
            XCTAssertFalse(slot(step, in: app).isSelected)
        }
    }
}
