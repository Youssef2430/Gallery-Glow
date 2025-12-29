//
//  Gallery_GlowApp.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import TVServices

@main
struct Gallery_GlowApp: App {
    @State private var deepLinkPainting: Painting?
    @State private var deepLinkGradient: GradientPalette?
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .fullScreenCover(item: $deepLinkPainting) { painting in
                    ScreensaverView(painting: painting)
                }
                .fullScreenCover(item: $deepLinkGradient) { palette in
                    GradientScreensaverView(palette: palette)
                }
                .onAppear {
                    // Always force refresh to ensure Top Shelf stays in sync
                    TopShelfManager.shared.refresh()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Always force refresh to ensure Top Shelf stays in sync
                        TopShelfManager.shared.refresh()
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "galleryglow" else { return }

        switch url.host {
        case "painting":
            // Handle galleryglow://painting/ImageName URLs
            let imageName = url.path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""

            // Find the painting with this image name
            if let painting = PaintingData.shared.allPaintings.first(where: { $0.imageName == imageName }) {
                RecentlyUsedManager.shared.addPainting(painting)
                deepLinkPainting = painting
            }

        case "gradient":
            // Handle galleryglow://gradient/PaletteName URLs
            let paletteName = url.path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""

            // Find the gradient palette
            if let palette = GradientPalette.allCases.first(where: { $0.rawValue == paletteName }) {
                RecentlyUsedManager.shared.addGradient(
                    palette: palette.rawValue,
                    description: RecentlyUsedManager.gradientDescription(for: palette.rawValue)
                )
                deepLinkGradient = palette
            }

        default:
            break
        }
    }
}
