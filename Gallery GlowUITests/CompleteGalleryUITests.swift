import XCTest

final class CompleteGalleryUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launch(fixture: String? = nil, storeScenario: String = "owned") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = storeScenario
        if let fixture { app.launchEnvironment["GALLERY_GLOW_UI_FIXTURE"] = fixture }
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func image(_ app: XCUIApplication, _ name: String, timeout: TimeInterval = 12) {
        XCTAssertTrue(app.images["artwork-\(name)"].firstMatch.waitForExistence(timeout: timeout), "Artwork did not render: \(name)")
    }

    @MainActor
    private func focus(_ identifier: String, in app: XCUIApplication) {
        let target = app.buttons[identifier]
        var previousFocus: String?
        var previousMoveWasVertical = false
        for _ in 0..<40 {
            if target.exists && target.hasFocus { return }
            guard target.exists,
                  // Resolve the focused element in one fresh query. Lazy grid
                  // cells can disappear while iterating a previous snapshot.
                  app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch.exists else {
                XCUIRemote.shared.press(.down)
                continue
            }
            let current = app.buttons.matching(NSPredicate(format: "hasFocus == true")).firstMatch
            let dy = target.frame.midY - current.frame.midY
            let dx = target.frame.midX - current.frame.midX
            let currentID = current.identifier
            // Align columns before changing rows: down from an empty column
            // can skip an incomplete final row entirely. A full-width featured
            // card cannot move horizontally, so fall back to the vertical move.
            if abs(dx) > 100 && !(previousFocus == currentID && !previousMoveWasVertical) {
                XCUIRemote.shared.press(dx > 0 ? .right : .left)
                previousMoveWasVertical = false
            } else if abs(dy) > 100 {
                XCUIRemote.shared.press(dy > 0 ? .down : .up)
                previousMoveWasVertical = true
            } else {
                XCUIRemote.shared.press(dx > 0 ? .right : .left)
                previousMoveWasVertical = false
            }
            previousFocus = currentID
        }
        XCTFail("Remote could not reach \(identifier): \(app.debugDescription)")
    }

    @MainActor
    func testDailyArtworkIsFreeFromCardsArtistAndTopShelfWithoutStoreAvailability() throws {
        let app = launch(storeScenario: "unavailable")
        let hero = app.buttons["painting-of-the-day"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        XCTAssertEqual(hero.value as? String, "Free today")
        let catalog = [
            ("Curled Up Girl on Bed", "Klimt/curled_up_girl_on_bed_1974.83.1", "Gustav Klimt"),
            ("Linde Frieze", "Munch/Linde_Frieze", "Edvard Munch"),
            ("The Creation of Adam", "Michelangelo/Creation_of_Adam", "Michelangelo"),
            ("Nighthawks", "Hopper/Nighthawks", "Edward Hopper"),
            ("The Birth of Venus", "Botticelli/Birth_of_Venus", "Sandro Botticelli"),
            ("Stacks of Wheat (End of Summer)", "Monet/Stacks_of_Wheat_End_of_Summer", "Claude Monet"),
            ("Heart of the Andes", "Church/Heart_of_the_Andes", "Frederic Edwin Church"),
            ("Washington Crossing the Delaware", "Leutze/Washington_Crossing_the_Delaware", "Emanuel Leutze"),
            ("A Brazilian Landscape", "Post/A_Brazilian_Landscape", "Frans Post")
        ]
        let (_, name, artist) = try XCTUnwrap(catalog.first { hero.label.hasPrefix($0.0 + ",") })
        for id in ["painting-of-the-day", "recent-painting/\(name)", "directors-cut-\(name)"] {
            focus(id, in: app)
            XCUIRemote.shared.press(.select)
            image(app, name)
            XCTAssertFalse(app.staticTexts["paywall-title"].exists)
            XCUIRemote.shared.press(.menu)
        }
        focus("artist-\(artist)", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["artist-painting-\(name)"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.select)
        image(app, name)
        XCTAssertFalse(app.staticTexts["paywall-title"].exists)
        capture(app, "Free daily artwork in full screen")
        XCUIRemote.shared.press(.menu)
        XCUIRemote.shared.press(.menu)
        // The Top Shelf extension opens this same URL in the main app.
        app.open(URL(string: "galleryglow://painting/\(name)")!)
        image(app, name)
        XCTAssertFalse(app.staticTexts["paywall-title"].exists)
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["purchaseBannerButton"].label.contains("Explore lifetime"))
        app.open(URL(string: "galleryglow://gradient/Aurora")!)
        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["unlockLifetimeButton"].label.contains("Try loading price again"))
    }

    @MainActor
    func testAccessibilityAuditForMainScreens() throws {
        let app = launch()
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
        try app.performAccessibilityAudit()
        focus("artist-Gustav Klimt", in: app)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["artist-painting-Klimt/curled_up_girl_on_bed_1974.83.1"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
        app.open(URL(string: "galleryglow://painting/Hopper/Nighthawks")!)
        image(app, "Hopper/Nighthawks")
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
        app.open(URL(string: "galleryglow://gradient/Aurora")!)
        XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
        app.open(URL(string: "galleryglow://painting/unknown")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testValidLinkDismissesPreviousLinkError() {
        let app = launch()
        app.open(URL(string: "galleryglow://gradient/Aurora")!)
        XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 5))
        app.open(URL(string: "galleryglow://painting/unknown")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForExistence(timeout: 5))
        app.open(URL(string: "galleryglow://painting/Hopper/Nighthawks")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForNonExistence(timeout: 5))
        image(app, "Hopper/Nighthawks")
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEveryGalleryCardAndArtistNavigation() {
        let app = launch()
        let catalog = [
            ("Gustav Klimt", "Klimt/curled_up_girl_on_bed_1974.83.1"),
            ("Edvard Munch", "Munch/Linde_Frieze"),
            ("Michelangelo", "Michelangelo/Creation_of_Adam"),
            ("Edward Hopper", "Hopper/Nighthawks"),
            ("Sandro Botticelli", "Botticelli/Birth_of_Venus"),
            ("Claude Monet", "Monet/Stacks_of_Wheat_End_of_Summer"),
            ("Frederic Edwin Church", "Church/Heart_of_the_Andes"),
            ("Emanuel Leutze", "Leutze/Washington_Crossing_the_Delaware"),
            ("Frans Post", "Post/A_Brazilian_Landscape")
        ]
        for (_, name) in catalog {
            focus("directors-cut-\(name)", in: app)
            if name == "Hopper/Nighthawks" { capture(app, "Directors Cut gallery") }
            XCUIRemote.shared.press(.select)
            image(app, name)
            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(app.buttons["directors-cut-\(name)"].waitForExistence(timeout: 5))
        }
        for (artist, name) in catalog {
            focus("artist-\(artist)", in: app)
            if artist == "Gustav Klimt" { capture(app, "Artists gallery") }
            XCUIRemote.shared.press(.select)
            XCTAssertTrue(app.buttons["artist-painting-\(name)"].waitForExistence(timeout: 5))
            capture(app, "Artist - \(artist)")
            XCUIRemote.shared.press(.select)
            image(app, name)
            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(app.buttons["artist-painting-\(name)"].waitForExistence(timeout: 5))
            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(app.buttons["artist-\(artist)"].waitForExistence(timeout: 5))
        }
        for palette in ["Magenta Purple", "Pink Orange", "Ocean Blue", "Sunrise Gold", "Aurora"] {
            focus("gradient-card-\(palette)", in: app)
            if palette == "Ocean Blue" { capture(app, "Gradients gallery") }
            XCUIRemote.shared.press(.select)
            XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 5))
            XCUIRemote.shared.press(.menu)
            XCTAssertTrue(app.buttons["gradient-card-\(palette)"].waitForExistence(timeout: 5))
        }
    }

    @MainActor
    func testEveryPaintingDeepLinkAndInformation() throws {
        let app = launch()
        let paintings = [
            ("Klimt/curled_up_girl_on_bed_1974.83.1", "Curled Up Girl on Bed"),
            ("Munch/Linde_Frieze", "Linde Frieze"),
            ("Michelangelo/Creation_of_Adam", "The Creation of Adam"),
            ("Hopper/Nighthawks", "Nighthawks"),
            ("Botticelli/Birth_of_Venus", "The Birth of Venus"),
            ("Monet/Stacks_of_Wheat_End_of_Summer", "Stacks of Wheat (End of Summer)"),
            ("Church/Heart_of_the_Andes", "Heart of the Andes"),
            ("Leutze/Washington_Crossing_the_Delaware", "Washington Crossing the Delaware"),
            ("Post/A_Brazilian_Landscape", "A Brazilian Landscape")
        ]
        for (name, title) in paintings {
            app.open(URL(string: "galleryglow://painting/\(name)")!)
            image(app, name)
            XCUIRemote.shared.press(.playPause)
            let info = app.staticTexts["painting-info-title"]
            XCTAssertTrue(info.waitForExistence(timeout: 5))
            XCTAssertEqual(info.label, title)
            try app.performAccessibilityAudit()
            capture(app, "Painting - \(title)")
        }
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testEveryGradientAnimatesPausesAndResumes() {
        let app = launch()
        for palette in ["Magenta Purple", "Pink Orange", "Ocean Blue", "Sunrise Gold", "Aurora"] {
            app.open(URL(string: "galleryglow://gradient/\(palette.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)")!)
            XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 10))
            XCUIRemote.shared.press(.playPause)
            XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
            let still = pixels(app)
            Thread.sleep(forTimeInterval: 0.8)
            XCTAssertEqual(still, pixels(app), "Paused \(palette) should not redraw")
            capture(app, "Gradient - \(palette)")
            XCUIRemote.shared.press(.playPause)
            XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 5))
            let moving = pixels(app)
            Thread.sleep(forTimeInterval: 0.8)
            XCTAssertNotEqual(moving, pixels(app), "\(palette) should animate after resuming")
        }
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testGradientColorCycleRemainsResponsive() {
        let app = launch()
        app.open(URL(string: "galleryglow://gradient/Aurora")!)
        XCTAssertTrue(app.staticTexts["Play/Pause to pause · Back to gallery"].waitForExistence(timeout: 10))
        let initial = pixels(app)
        // Cross the initial 20-second wait and eight-second color transition.
        Thread.sleep(forTimeInterval: 30)
        XCTAssertNotEqual(initial, pixels(app))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["Paused · Play/Pause to resume · Back to gallery"].waitForExistence(timeout: 5))
        capture(app, "Gradient after color cycle")
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testSlowLoadingFeedbackResolves() {
        let app = launch(fixture: "slow")
        XCTAssertTrue(app.staticTexts["Loading artwork"].waitForExistence(timeout: 5))
        capture(app, "Simulated slow artwork loading")
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 3), "Remote controls must remain responsive during decoding")
        image(app, "Hopper/Nighthawks")
        XCTAssertTrue(app.staticTexts["Loading artwork"].waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testOptimisticPreviewAppearsDuringSlowDecode() {
        let app = launch(fixture: "optimistic")
        image(app, "Hopper/Nighthawks", timeout: 2)
        XCTAssertFalse(app.staticTexts["Loading artwork"].exists)
        capture(app, "Cached preview during simulated slow decode")
        Thread.sleep(forTimeInterval: 8)
        image(app, "Hopper/Nighthawks")
        XCTAssertFalse(app.staticTexts["Artwork unavailable"].exists)
    }

    @MainActor
    func testRetryRecoversFromDecodeFailure() {
        let app = launch(fixture: "retry")
        let retry = app.buttons["Try Again"]
        XCTAssertTrue(retry.waitForExistence(timeout: 5))
        XCTAssertTrue(retry.hasFocus, "Failure should move remote focus to Try Again")
        capture(app, "Simulated artwork failure and retry")
        XCUIRemote.shared.press(.select)
        image(app, "Hopper/Nighthawks")
        XCTAssertTrue(retry.waitForNonExistence(timeout: 3))
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        capture(app, "Artwork recovered after retry")
    }

    @MainActor
    func testPermanentMissingArtworkRemainsRetryable() {
        let app = launch(fixture: "missing")
        XCTAssertTrue(app.buttons["Try Again"].waitForExistence(timeout: 5))
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.buttons["Try Again"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Artwork unavailable"].exists)
    }

    @MainActor
    func testLateImageCompletionCannotReplaceNewArtwork() {
        let app = launch(fixture: "identity")
        XCUIRemote.shared.press(.playPause)
        image(app, "Munch/Linde_Frieze")
        Thread.sleep(forTimeInterval: 8)
        image(app, "Munch/Linde_Frieze")
        XCTAssertFalse(app.images["artwork-Hopper/Nighthawks"].exists)
        capture(app, "New artwork survives stale completion")
    }

    @MainActor
    func testReduceMotionFreezesGradientIncludingPlayPause() {
        let app = launch(fixture: "reduce-motion")
        let hint = app.staticTexts["Reduce Motion is on · Back to gallery"]
        XCTAssertTrue(hint.waitForExistence(timeout: 5))
        capture(app, "Reduce Motion enabled")
        XCTAssertTrue(hint.waitForNonExistence(timeout: 8))
        let first = pixels(app)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(first, pixels(app))
        XCUIRemote.shared.press(.playPause)
        Thread.sleep(forTimeInterval: 1)
        XCTAssertEqual(first, pixels(app), "Play/Pause must not override Reduce Motion")
    }

    @MainActor
    func testFitArtworkHasBackdropAndWorkingControls() {
        let app = launch(fixture: "fit")
        image(app, "Michelangelo/Creation_of_Adam")
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        capture(app, "Fit artwork with blurred backdrop")
    }

    @MainActor
    func testRecentItemsSurviveRelaunchAndReopen() {
        let app = launch()
        app.open(URL(string: "galleryglow://painting/Hopper/Nighthawks")!)
        image(app, "Hopper/Nighthawks")
        XCUIRemote.shared.press(.menu)
        app.terminate()
        app.launch()
        let recent = app.buttons["recent-painting/Hopper/Nighthawks"]
        focus("recent-painting/Hopper/Nighthawks", in: app)
        XCTAssertTrue(recent.exists && recent.hasFocus)
        capture(app, "Recently Viewed persists after relaunch")
        XCUIRemote.shared.press(.select)
        image(app, "Hopper/Nighthawks")
        XCUIRemote.shared.press(.playPause)
        XCTAssertTrue(app.staticTexts["painting-info-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["painting-info-title"].label, "Nighthawks")
    }

    @MainActor
    private func pixels(_ app: XCUIApplication) -> Data {
        // Compare rendered pixels, excluding PNG metadata and encoders.
        let cgImage = app.screenshot().image.cgImage!
        return cgImage.dataProvider!.data! as Data
    }
}
