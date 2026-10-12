import XCTest

final class AppearanceUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testGalleryAndCheckoutFollowLiveSystemAppearance() throws {
        let device = XCUIDevice.shared
        let originalAppearance = device.appearance
        defer { device.appearance = originalAppearance }
        device.appearance = .light

        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "success"
        app.launch()
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 10))

        // Change the actual device setting while each screen remains open.
        // Sampling the gallery wall catches a forced scheme or a fixed palette.
        for appearance in [XCUIDevice.Appearance.light, .dark, .light] {
            device.appearance = appearance
            try verifyAppearance(appearance, screen: "Home", in: app)
        }

        let paidArtwork = PaidArtworkFixture.choose(in: app)
        app.open(URL(string: "galleryglow://painting/\(paidArtwork.path)")!)
        XCTAssertTrue(app.staticTexts["paywall-title"].waitForExistence(timeout: 10))
        for appearance in [XCUIDevice.Appearance.light, .dark, .light] {
            device.appearance = appearance
            try verifyAppearance(appearance, screen: "Checkout", in: app)
        }

        XCTAssertTrue(app.buttons["unlockLifetimeButton"].hasFocus)
        XCUIRemote.shared.press(.select)
        XCTAssertTrue(app.staticTexts["Play/Pause for artwork info · Back to gallery"].waitForExistence(timeout: 8))
        XCUIRemote.shared.press(.menu)
        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 5))
        // Dark artwork chrome must not leave the light gallery in dark mode.
        try verifyAppearance(.light, screen: "Home after artwork", in: app)
        app.open(URL(string: "galleryglow://painting/unknown")!)
        XCTAssertTrue(app.alerts["Artwork unavailable"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
    }

    @MainActor
    private func verifyAppearance(_ appearance: XCUIDevice.Appearance, screen: String,
                                  in app: XCUIApplication) throws {
        let isDark = appearance == .dark
        let deadline = Date().addingTimeInterval(8)
        var matches = false
        repeat {
            let cgImage = try XCTUnwrap(app.screenshot().image.cgImage)
            let corner = try XCTUnwrap(cgImage.cropping(to: CGRect(x: 40, y: 40, width: 1, height: 1)))
            var pixel: [UInt8] = [0, 0, 0, 0]
            pixel.withUnsafeMutableBytes { bytes in
                let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                                        bitsPerComponent: 8, bytesPerRow: 4,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
                context.draw(corner, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            }
            let brightness = Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])
            matches = isDark ? brightness < 150 : brightness > 600
            if !matches { Thread.sleep(forTimeInterval: 0.25) }
        } while !matches && Date() < deadline
        XCTAssertTrue(matches, "\(screen) did not follow the system's \(isDark ? "dark" : "light") appearance")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(screen) — \(isDark ? "Dark" : "Light")"
        attachment.lifetime = .keepAlways
        add(attachment)
        try app.performAccessibilityAudit()
    }
}
