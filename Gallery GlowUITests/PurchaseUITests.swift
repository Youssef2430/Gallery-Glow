import XCTest

final class PurchaseUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launch(_ scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = scenario
        app.launch()
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    @discardableResult
    private func openPaywall(_ app: XCUIApplication) -> String {
        let artwork = PaidArtworkFixture.choose(in: app)
        app.open(URL(string: "galleryglow://painting/\(artwork.path)")!)
        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["unlockLifetimeButton"].waitForExistence(timeout: 5))
        return artwork.title
    }

    @MainActor
    private func focus(_ id: String, in app: XCUIApplication) {
        let target = app.buttons[id]
        for _ in 0..<12 {
            if target.hasFocus { return }
            let current = app.buttons.allElementsBoundByAccessibilityElement.first { $0.hasFocus }
            guard let current else { XCUIRemote.shared.press(.down); continue }
            if abs(target.frame.midY - current.frame.midY) > 35 {
                XCUIRemote.shared.press(target.frame.midY > current.frame.midY ? .down : .up)
            } else {
                XCUIRemote.shared.press(target.frame.midX > current.frame.midX ? .right : .left)
            }
        }
        XCTFail("Could not focus \(id): \(app.debugDescription)")
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testPurchaseContinuesToSelectedPainting() throws {
        let app = launch("success")
        capture(app, "Redesigned gallery home")
        let expectedTitle = openPaywall(app)
        capture(app, "Gallery lifetime pass")
        try app.performAccessibilityAudit()
        focus("unlockLifetimeButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 8))
        XCUIRemote.shared.press(.playPause)
        XCTAssertEqual(app.staticTexts["painting-info-title"].label, expectedTitle)
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["purchaseBannerButton"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["purchaseBannerButton"].label.contains("Your lifetime pass"))
    }

    @MainActor
    func testCancellationAndKeepBrowsing() {
        let app = launch("cancelled")
        openPaywall(app)
        focus("unlockLifetimeButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["unlockLifetimeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["paywall-title"].exists)
        XCTAssertFalse(app.staticTexts["Play/Pause for artwork info · Back to gallery"].exists)
        focus("paywall-close", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testRestoreAndEmptyRestoreFeedback() {
        let app = launch("restore")
        openPaywall(app)
        focus("restorePurchaseButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 8))
        app.terminate()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "empty"
        app.launch()
        openPaywall(app)
        focus("restorePurchaseButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No lifetime purchase was found'")).firstMatch.waitForExistence(timeout: 5))
        capture(app, "Restore with no purchase")
    }

    @MainActor
    func testPendingApprovalAutomaticallyContinues() {
        let app = launch("approved")
        openPaywall(app)
        focus("unlockLifetimeButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Awaiting approval.'")).firstMatch.waitForExistence(timeout: 4))
        capture(app, "Purchase awaiting approval")
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testUnavailableStoreStillAllowsRestoreAndExit() {
        let app = launch("unavailable")
        openPaywall(app)
        XCTAssertTrue(app.buttons["unlockLifetimeButton"].label.contains("Try loading price again"))
        XCTAssertTrue(app.buttons["restorePurchaseButton"].isEnabled)
        focus("unlockLifetimeButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["paywall-title"].exists)
        capture(app, "Store unavailable with recovery actions")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 8))
    }

    @MainActor
    func testFailedVerificationOffersRestoreInsteadOfAnotherPurchase() {
        let app = launch("unverified")
        openPaywall(app)
        focus("unlockLifetimeButton", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Restore to verify purchase'")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Play/Pause for artwork info · Back to gallery"].exists)
        capture(app, "Verification recovery")
    }
}

/// Checkout tests must select a paid work regardless of the calendar date.
@MainActor
enum PaidArtworkFixture {
    static func choose(in app: XCUIApplication) -> (path: String, title: String) {
        let daily = app.buttons["painting-of-the-day"].label
        return daily.hasPrefix("Nighthawks,")
            ? ("Botticelli/Birth_of_Venus", "The Birth of Venus")
            : ("Hopper/Nighthawks", "Nighthawks")
    }
}
