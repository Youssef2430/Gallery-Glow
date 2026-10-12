//
//  Gallery_GlowUITestsLaunchTests.swift
//  Gallery GlowUITests
//
//  Created by Youssef Chouay on 2025-12-28.
//

import XCTest

final class Gallery_GlowUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GALLERY_GLOW_STORE_FIXTURE"] = "owned"
        app.launch()

        XCTAssertTrue(app.buttons["painting-of-the-day"].waitForExistence(timeout: 15))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
