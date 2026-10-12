import Testing
import XCTest
import SwiftUI
import UIKit
@testable import Gallery_Glow

@MainActor
struct CompleteCatalogTests {
    @Test("Every painting decodes in fit/fill at 1x and 2x")
    func everyPaintingDecodes() async throws {
        for painting in PaintingData.shared.allPaintings {
            for scale: CGFloat in [1, 2] {
                for fill in [true, false] {
                    let image = await Task.detached {
                        downsampleImage(named: painting.imageName, to: CGSize(width: 400, height: 225),
                                        contentMode: fill ? .fill : .fit, scale: scale)
                    }.value
                    let bitmap = try #require(image?.cgImage, "Decode failed: \(painting.imageName)")
                    if fill {
                        #expect(bitmap.width >= Int(399 * scale))
                        #expect(bitmap.height >= Int(224 * scale))
                    } else {
                        #expect(bitmap.width <= Int(401 * scale))
                        #expect(bitmap.height <= Int(226 * scale))
                    }
                }
            }
        }
    }

    @Test("Every Top Shelf painting and gradient has an image and a valid route")
    func topShelfResourcesAndRoutes() throws {
        let plugins = try #require(Bundle.main.builtInPlugInsURL)
        let shelf = try #require(Bundle(url: plugins.appendingPathComponent("Gallery Shelf.appex")))
        func verifyCard(_ resource: String) throws {
            let url = try #require(shelf.url(forResource: resource, withExtension: "jpg", subdirectory: "TopShelfImages") ??
                                   shelf.url(forResource: resource, withExtension: "jpg"), "Missing shelf card: \(resource)")
            let bitmap = try #require(UIImage(contentsOfFile: url.path)?.cgImage, "Invalid shelf card: \(resource)")
            #expect(bitmap.width == 888)
            #expect(bitmap.height == 500)
        }
        for painting in PaintingData.shared.allPaintings {
            let resource = painting.imageName.replacingOccurrences(of: "/", with: "_")
            try verifyCard(resource)
            try verifyCard("featured_" + resource)
            let encoded = painting.imageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            #expect(GallerySession.selection(for: URL(string: "galleryglow://painting/\(encoded)")!) == .painting(painting))
        }
        for palette in GradientPalette.allCases {
            try verifyCard("gradient_" + palette.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))
            let encoded = palette.rawValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            #expect(GallerySession.selection(for: URL(string: "galleryglow://gradient/\(encoded)")!) == .gradient(palette))
            #expect(palette.colors.count == 4)
            #expect(!palette.displayDescription.isEmpty)
        }
    }

    @Test("Unknown links report failure without discarding the open viewer")
    func invalidLinksPreserveSelection() async {
        let purchases = PurchaseManager(store: PurchaseUITestStore(scenario: "owned"))
        await purchases.refreshEntitlement()
        let session = GallerySession(purchases: purchases)
        session.selection = .gradient(.aurora)
        session.open(URL(string: "galleryglow://painting/unknown")!)
        #expect(session.linkError)
        #expect(session.selection == .gradient(.aurora))
        session.linkError = false
        session.open(URL(string: "https://example.com/painting/unknown")!)
        #expect(!session.linkError)
        #expect(session.selection == .gradient(.aurora))
        for url in ["galleryglow://", "galleryglow://gradient/", "galleryglow://invalid/Aurora", "galleryglow://painting/%252FHopper"] {
            #expect(GallerySession.selection(for: URL(string: url)!) == nil)
        }
        session.linkError = true
        session.open(URL(string: "galleryglow://gradient/Ocean%20Blue")!)
        #expect(!session.linkError)
        #expect(session.selection == .gradient(.oceanBlue))
    }

    @Test("Daily selection handles leap days, year rollover, and DST boundaries")
    func calendarBoundaries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Toronto"))
        for components in [DateComponents(year: 2024, month: 2, day: 29),
                           DateComponents(year: 2026, month: 3, day: 8),
                           DateComponents(year: 2026, month: 11, day: 1),
                           DateComponents(year: 2026, month: 12, day: 31)] {
            let date = try #require(calendar.date(from: components))
            let day = try #require(calendar.dateInterval(of: .day, for: date))
            let data = PaintingData.shared
            #expect(data.paintingOfTheDay(on: day.start, calendar: calendar) ==
                    data.paintingOfTheDay(on: day.end.addingTimeInterval(-1), calendar: calendar))
            #expect(data.directorsCut.contains(data.paintingOfTheDay(on: day.end, calendar: calendar)))
        }
    }

    @Test("Top Shelf refresh handles both forward and backward clock changes")
    func topShelfRefreshDates() throws {
        let defaults = UserDefaults.standard
        let key = "TopShelfLastRefreshDate"
        let versionKey = "TopShelfDesignVersion"
        let previous = defaults.object(forKey: key)
        let previousVersion = defaults.object(forKey: versionKey)
        defer {
            if let previous { defaults.set(previous, forKey: key) }
            else { defaults.removeObject(forKey: key) }
            if let previousVersion { defaults.set(previousVersion, forKey: versionKey) }
            else { defaults.removeObject(forKey: versionKey) }
        }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        defaults.set(today, forKey: key)
        defaults.removeObject(forKey: versionKey)
        TopShelfManager.shared.refreshIfNeeded()
        #expect(defaults.integer(forKey: versionKey) == 6)
        #expect(abs((try #require(defaults.object(forKey: key) as? Date)).timeIntervalSinceNow) < 5)
        defaults.set(today, forKey: key)
        TopShelfManager.shared.refreshIfNeeded()
        #expect(defaults.object(forKey: key) as? Date == today)
        for offset in [-2, 2] {
            let otherDay = try #require(calendar.date(byAdding: .day, value: offset, to: today))
            defaults.set(otherDay, forKey: key)
            TopShelfManager.shared.refreshIfNeeded()
            let refreshed = try #require(defaults.object(forKey: key) as? Date)
            #expect(abs(refreshed.timeIntervalSinceNow) < 5)
        }
        defaults.removeObject(forKey: key)
        TopShelfManager.shared.refreshIfNeeded()
        #expect(defaults.object(forKey: key) is Date)
    }
}

/// Hosted XCTest cases run separately from the Swift Testing suite. Restore the
/// app window after each case, so normal app/UI tests keep their own lifecycle.
final class HostedLifecycleTests: XCTestCase {
    @MainActor
    func testIdleTimerAndMemoryWarningLifecycle() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = try XCTUnwrap(scene.windows.first)
        let original = window.rootViewController
        let originalIdle = UIApplication.shared.isIdleTimerDisabled
        let purchases = PurchaseManager(store: PurchaseUITestStore(scenario: "owned"))
        await purchases.refreshEntitlement()
        let session = GallerySession(purchases: purchases)
        let model = LifecycleModel()
        defer {
            window.rootViewController = original
            UIApplication.shared.isIdleTimerDisabled = originalIdle
        }
        window.rootViewController = UIHostingController(rootView: LifecycleHost(session: session, model: model))
        try await Task.sleep(for: .milliseconds(300))
        let refreshKey = "TopShelfLastRefreshDate"
        let previousRefresh = UserDefaults.standard.object(forKey: refreshKey)
        defer {
            if let previousRefresh { UserDefaults.standard.set(previousRefresh, forKey: refreshKey) }
            else { UserDefaults.standard.removeObject(forKey: refreshKey) }
        }
        UserDefaults.standard.set(Date.distantPast, forKey: refreshKey)
        NotificationCenter.default.post(name: UIApplication.significantTimeChangeNotification, object: nil)
        try await Task.sleep(for: .milliseconds(300))
        let refreshed = try XCTUnwrap(UserDefaults.standard.object(forKey: refreshKey) as? Date)
        XCTAssertTrue(Calendar.current.isDateInToday(refreshed), "A clock-change notification must restart the daily refresh")
        session.selection = .gradient(.aurora)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)
        model.phase = .background
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)
        model.phase = .active
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertTrue(UIApplication.shared.isIdleTimerDisabled)
        session.selection = nil
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(UIApplication.shared.isIdleTimerDisabled)

        let request = try XCTUnwrap(ImageRequest(imageName: "Hopper/Nighthawks", size: CGSize(width: 400, height: 225), contentMode: .fill, scale: 1))
        let loaded = await PaintingImageLoader.shared.image(for: request)
        XCTAssertNotNil(loaded)
        XCTAssertNotNil(ImageCache.shared.image(for: request))
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        XCTAssertNil(ImageCache.shared.image(for: request))
        let reloaded = await PaintingImageLoader.shared.image(for: request)
        XCTAssertNotNil(reloaded)
    }
}

@MainActor @Observable
private final class LifecycleModel { var phase: ScenePhase = .active }

private struct LifecycleHost: View {
    let session: GallerySession
    let model: LifecycleModel
    var body: some View { ContentView(session: session).environment(\.scenePhase, model.phase) }
}
