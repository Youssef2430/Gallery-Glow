//
//  AppStoreScreenshotTests.swift
//  Gallery GlowTests
//
//  Renders key screens to 1920x1080 PNGs for the App Store listing.
//  Hosted unit tests run inside the app process, so views can be
//  presented in the real window and snapshotted without StoreKit.
//  Output: /tmp/gg-shots/*.png
//

import Testing
import SwiftUI
import UIKit
@testable import Gallery_Glow

struct AppStoreScreenshotTests {

    @Test("Render App Store screenshots")
    @MainActor
    func renderAppStoreScreenshots() async throws {
        let data = PaintingData.shared

        func painting(_ imageName: String) -> Painting? {
            data.allPaintings.first { $0.imageName == imageName }
        }

        var screens: [(String, AnyView)] = []

        if let p = painting("Van Gogh/Starry_Night_Over_the_Rhone") {
            screens.append(("02-starry-night", AnyView(ScreensaverView(painting: p))))
        }
        if let p = painting("Hokusai/Great_Wave") {
            screens.append(("03-great-wave", AnyView(ScreensaverView(painting: p))))
        }
        if let p = painting("Botticelli/Birth_of_Venus") {
            screens.append(("04-birth-of-venus", AnyView(ScreensaverView(painting: p))))
        }
        if let p = painting("Hopper/Nighthawks") {
            screens.append(("05-nighthawks", AnyView(ScreensaverView(painting: p))))
        }
        if let monet = data.artists.first(where: { $0.name.contains("Monet") }) {
            screens.append(("06-artist-monet", AnyView(
                NavigationStack { ArtistView(artist: monet) }
                    .environmentObject(PurchaseManager(startsTransactionListener: false))
            )))
        }
        screens.append(("07-gradient-aurora", AnyView(GradientScreensaverView(palette: .aurora))))

        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = try #require(scene.windows.first)
        let originalRoot = window.rootViewController

        let outputDir = URL(fileURLWithPath: "/tmp/gg-shots")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        for (name, view) in screens {
            window.rootViewController = UIHostingController(rootView: view)

            // Let images decode and entrance animations settle.
            try await Task.sleep(for: .seconds(4))

            let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
            let image = renderer.image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let png = try #require(image.pngData())
            try png.write(to: outputDir.appendingPathComponent("\(name).png"))
        }

        window.rootViewController = originalRoot
    }
}
