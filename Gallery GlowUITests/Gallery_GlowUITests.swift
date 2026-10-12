import XCTest

final class Gallery_GlowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPaintingControlsAndReturnToGallery() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "owned"
        app.launch()
        let featured = app.buttons["painting-of-the-day"]
        XCTAssertTrue(featured.waitForExistence(timeout: 15))
        attachScreenshot(app, name: "Gallery home")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForNonExistence(timeout: 5))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(featured.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Recently Viewed"].exists)
        // Reopening exercises the warm-image path and restored TV focus.
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(featured.waitForExistence(timeout: 10))
    }

    @MainActor
    func testDeepLinksReplaceOpenScreensaversAndGradientPauses() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "owned"
        app.launch()
        app.open(URL(string: "galleryglow://painting/Hopper%2FNighthawks")!)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["painting-info-title"].label, "Nighthawks")
        attachScreenshot(app, name: "Painting with information")
        app.open(URL(string: "galleryglow://gradient/Aurora")!)
        XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
        attachScreenshot(app, name: "Paused gradient")
        // Holding a pause past the feedback timeout must not let an old timer
        // erase the next resume command's feedback.
        Thread.sleep(forTimeInterval: 5.2)
        XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].exists)
        for _ in 0..<3 {
            XCUIRemote.shared.press(.home)
            XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
            app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
            XCUIRemote.shared.press(.playPause)
            XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 5))
            let before = app.screenshot().image.cgImage!.dataProvider!.data! as Data
            Thread.sleep(forTimeInterval: 0.8)
            let after = app.screenshot().image.cgImage!.dataProvider!.data! as Data
            XCTAssertNotEqual(before, after, "Gradient must resume animating after foregrounding")
            XCUIRemote.shared.press(.playPause)
            XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
        }
        app.open(URL(string: "galleryglow://painting/Munch%2FLinde_Frieze")!)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["painting-info-title"].label, "Linde Frieze")
        app.open(URL(string: "galleryglow://painting/removed-artwork")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForExistence(timeout: 10))
        attachScreenshot(app, name: "Invalid link feedback")
        XCUIRemote.shared.press(.select)
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testInvalidLinkHasActionableFeedback() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "owned"
        app.launch()
        app.open(URL(string: "galleryglow://painting/removed-artwork")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForExistence(timeout: 10))
        attachScreenshot(app, name: "Invalid link feedback")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testArtistNavigationAndReturn() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "owned"
        app.launch()
        let artist = app.buttons["artist-Gustav Klimt"]
        for _ in 0..<18 {
            if artist.exists && artist.hasFocus { break }
            let artistRowHasFocus = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'artist-'"))
                .allElementsBoundByAccessibilityElement.contains { $0.exists && $0.hasFocus }
            if artistRowHasFocus {
                XCUIRemote.shared.press(.left)
            } else {
                XCUIRemote.shared.press(.down)
            }
        }
        if !artist.exists || !artist.hasFocus { print(app.debugDescription) }
        XCTAssertTrue(artist.exists && artist.hasFocus, "Artist card should be reachable with the remote")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["1862 - 1918"].waitForExistence(timeout: 10))
        attachScreenshot(app, name: "Artist detail")
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.staticTexts["1862 - 1918"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(artist.waitForExistence(timeout: 10))
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) { XCUIApplication().launch() }
    }
}
