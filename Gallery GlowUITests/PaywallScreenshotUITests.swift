//
//  PaywallScreenshotUITests.swift
//  Gallery GlowUITests
//
//  Captures the paywall for the App Store Connect in-app purchase
//  review screenshot. Run on the 1080p Apple TV simulator to get the
//  required 1920x1080 image, then export the attachment from the
//  result bundle.
//

import XCTest

final class PaywallScreenshotUITests: XCTestCase {

    @MainActor
    func testCapturePaywallScreenshot() throws {
        let app = XCUIApplication()
        app.launch()

        // The purchase banner is the first focused element when locked.
        sleep(3)
        XCUIRemote.shared.press(.select)

        // Give the paywall time to present and load the product.
        sleep(5)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Paywall"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
