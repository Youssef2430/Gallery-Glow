import Testing
import Foundation
import SwiftUI
import UIKit
@testable import Gallery_Glow

@MainActor
struct PerformanceAndStateTests {
    @Test("Image identity includes pixels, artwork, and content mode")
    func requestIdentity() throws {
        let size = CGSize(width: 400, height: 225)
        let one = try #require(ImageRequest(imageName: "one", size: size, contentMode: .fill, scale: 1))
        let retina = try #require(ImageRequest(imageName: "one", size: size, contentMode: .fill, scale: 2))
        #expect(one != retina)
        #expect(one.pixelWidth >= 400 && retina.pixelWidth >= 800)
        #expect(one != ImageRequest(imageName: "two", size: size, contentMode: .fill, scale: 1))
        #expect(one != ImageRequest(imageName: "one", size: size, contentMode: .fit, scale: 1))
        #expect(one == ImageRequest(imageName: "one", size: CGSize(width: 401, height: 226), contentMode: .fill, scale: 1))
        #expect(ImageRequest(imageName: "one", size: .zero, contentMode: .fill, scale: 1) == nil)
        #expect(ImageRequest(imageName: "one", size: size, contentMode: .fill, scale: .infinity) == nil)
    }

    @Test("Concurrent consumers share a decode and cache warm loads")
    func coalescedLoads() async throws {
        let probe = DecodeProbe()
        let cache = ImageCache()
        let loader = PaintingImageLoader(cache: cache, decode: { probe.decode($0) })
        let request = try #require(ImageRequest(imageName: "same", size: CGSize(width: 400, height: 225), contentMode: .fill, scale: 1))
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<24 { group.addTask { await loader.image(for: request) != nil } }
            for await success in group { #expect(success) }
        }
        #expect(probe.count == 1)
        #expect(probe.mainThreadDecodes == 0)
        #expect(await loader.image(for: request) != nil)
        #expect(probe.count == 1)
        #expect(cache.preview(for: "same") != nil)
        cache.removeAll()
        #expect(cache.image(for: request) == nil)
        #expect(cache.preview(for: "same") == nil)
    }

    @Test("Scrolling bursts never run more than two decoders")
    func boundedDecoding() async {
        let probe = DecodeProbe()
        let loader = PaintingImageLoader(cache: ImageCache(), decode: { probe.decode($0) })
        await withTaskGroup(of: Bool.self) { group in
            for index in 0..<12 {
                let request = ImageRequest(imageName: "image-\(index)", size: CGSize(width: 400, height: 225), contentMode: .fill, scale: 1)!
                group.addTask { await loader.image(for: request) != nil }
            }
            for await success in group { #expect(success) }
        }
        #expect(probe.count == 12)
        #expect(probe.maximumConcurrent <= 2)
        #expect(probe.mainThreadDecodes == 0)
    }

    @Test("Cancelling one consumer leaves shared decoding available to others")
    func cancellationDoesNotPoisonSharedLoad() async throws {
        let probe = DecodeProbe()
        let loader = PaintingImageLoader(cache: ImageCache(), decode: { probe.decode($0) })
        let request = try #require(ImageRequest(imageName: "shared", size: CGSize(width: 400, height: 225), contentMode: .fill, scale: 1))
        let first = Task { await loader.image(for: request) }
        // Wait until actual work begins before cancelling its first consumer.
        for _ in 0..<1000 {
            if probe.count > 0 { break }
            try await Task.sleep(for: .milliseconds(1))
        }
        try #require(probe.count > 0)
        first.cancel()
        #expect(await loader.image(for: request) != nil)
        _ = await first.value
        #expect(probe.count == 1)
    }

    @Test("Large decoded images retain only a small optimistic preview")
    func boundedPreviewSize() async throws {
        let cache = ImageCache()
        let request = try #require(ImageRequest(imageName: "Hopper/Nighthawks", size: CGSize(width: 1920, height: 1080), contentMode: .fill, scale: 1))
        let loader = PaintingImageLoader(cache: cache)
        #expect(await loader.image(for: request) != nil)
        let preview = try #require(cache.preview(for: request.imageName)?.cgImage)
        #expect(max(preview.width, preview.height) <= 640)
        #expect(preview.bytesPerRow * preview.height < 2 * 1024 * 1024)
    }

    @Test("Missing images can be retried instead of caching failures")
    func failureRetry() async throws {
        let probe = DecodeProbe(failFirst: true)
        let loader = PaintingImageLoader(cache: ImageCache(), decode: { probe.decode($0) })
        let request = try #require(ImageRequest(imageName: "retry", size: CGSize(width: 400, height: 225), contentMode: .fit, scale: 1))
        #expect(await loader.image(for: request) == nil)
        #expect(await loader.image(for: request) != nil)
        #expect(probe.count == 2)
    }

    @Test("Fit and fill decode sufficient pixels without materializing native resolution")
    func downsampling() async throws {
        let result = await Task.detached {
            let name = "Hopper/Nighthawks"
            let fit = downsampleImage(named: name, to: CGSize(width: 400, height: 225), contentMode: .fit)
            let fill = downsampleImage(named: name, to: CGSize(width: 400, height: 225), contentMode: .fill)
            return (fit, fill)
        }.value
        let fit = try #require(result.0?.cgImage)
        let fill = try #require(result.1?.cgImage)
        #expect(fit.width <= 401 && fit.height <= 226)
        #expect(fill.width >= 399 && fill.height >= 224)
        #expect(fill.width < 1000 && fill.height < 1000)
        #expect(downsampleImage(named: "missing-artwork", to: CGSize(width: 400, height: 225)) == nil)
        #expect(downsampleImage(named: "Hopper/Nighthawks", to: .zero) == nil)
    }

    @Test("Recent items update immediately, deduplicate, persist, and stay bounded")
    func recentItems() throws {
        let suite = "GalleryGlowTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var notifications = 0
        let store = RecentlyUsedManager(defaults: defaults, notify: { notifications += 1 })
        let extensionReader = RecentlyUsedManager(defaults: defaults, notify: {})
        for index in 0..<12 { store.addGradient(palette: "Gradient \(index)", description: "Test") }
        #expect(store.items.count == 10)
        store.addGradient(palette: "Gradient 5", description: "Updated")
        #expect(store.items.first?.identifier == "Gradient 5")
        #expect(store.items.first?.subtitle == "Updated")
        #expect(store.items.filter { $0.identifier == "Gradient 5" }.count == 1)
        #expect(extensionReader.getRecentItems().first?.identifier == "Gradient 5")
        #expect(notifications == 13)
        #expect(RecentlyUsedManager(defaults: defaults, notify: {}).items == store.items)
        store.clearAll()
        #expect(store.items.isEmpty)
        #expect(extensionReader.getRecentItems().isEmpty)
        defaults.set(Data("bad json".utf8), forKey: "recentlyUsedItems")
        #expect(RecentlyUsedManager(defaults: defaults, notify: {}).items.isEmpty)
    }

    @Test("Top Shelf links parse escaped paths and reject unsupported destinations")
    func links() throws {
        let painting = try #require(GallerySession.selection(for: URL(string: "galleryglow://painting/Hopper%2FNighthawks")!))
        #expect(painting.id == "painting/Hopper/Nighthawks")
        #expect(GallerySession.selection(for: URL(string: "galleryglow://gradient/Ocean%20Blue")!) == .gradient(.oceanBlue))
        #expect(GallerySession.selection(for: URL(string: "galleryglow://painting/missing")!) == nil)
        #expect(GallerySession.selection(for: URL(string: "https://gradient/Aurora")!) == nil)
        let session = GallerySession()
        session.selection = painting
        session.selection = .gradient(.aurora)
        #expect(session.selection?.id == "gradient/Aurora")
        session.selection = nil
        #expect(session.selection == nil)
    }

    @Test("Painting of the Day is deterministic across time and changes at local midnight")
    func dailyPainting() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 4)))
        let data = PaintingData.shared
        #expect(data.paintingOfTheDay(on: start, calendar: calendar) == data.paintingOfTheDay(on: start.addingTimeInterval(86399), calendar: calendar))
        #expect(data.paintingOfTheDay(on: start, calendar: calendar) != data.paintingOfTheDay(on: start.addingTimeInterval(86400), calendar: calendar))
    }
}

/// A thread-safe probe exercises real worker scheduling, including overlap.
private final class DecodeProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    private var active = 0
    private var maximum = 0
    private var mainCalls = 0
    private let failFirst: Bool

    init(failFirst: Bool = false) { self.failFirst = failFirst }
    var count: Int { lock.withLock { calls } }
    var maximumConcurrent: Int { lock.withLock { maximum } }
    var mainThreadDecodes: Int { lock.withLock { mainCalls } }

    func decode(_ request: ImageRequest) -> UIImage? {
        let number = lock.withLock {
            calls += 1
            active += 1
            maximum = max(maximum, active)
            if Thread.isMainThread { mainCalls += 1 }
            return calls
        }
        defer { lock.withLock { active -= 1 } }
        Thread.sleep(forTimeInterval: 0.04)
        if failFirst && number == 1 { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8), format: format).image { context in
            context.cgContext.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}
