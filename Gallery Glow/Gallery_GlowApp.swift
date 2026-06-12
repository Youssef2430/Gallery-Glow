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
    @StateObject private var purchaseManager = PurchaseManager()

    @State private var deepLinkPainting: Painting?
    @State private var deepLinkGradient: GradientPalette?
    @State private var pendingDeepLinkPainting: Painting?
    @State private var pendingDeepLinkGradient: GradientPalette?
    @State private var showDeepLinkPaywall = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    await purchaseManager.prepareForStore()
                }
                .fullScreenCover(item: $deepLinkPainting) { painting in
                    ScreensaverView(painting: painting)
                }
                .fullScreenCover(item: $deepLinkGradient) { palette in
                    GradientScreensaverView(palette: palette)
                }
                .sheet(isPresented: $showDeepLinkPaywall) {
                    PaywallView {
                        presentPendingDeepLinkIfUnlocked()
                    }
                    .environmentObject(purchaseManager)
                }
                .onChange(of: purchaseManager.isUnlocked) { _, unlocked in
                    guard unlocked else { return }
                    presentPendingDeepLinkIfUnlocked()
                }
                .onAppear {
                    // Force refresh on first launch to ensure Top Shelf is populated
                    TopShelfManager.shared.refresh()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Only refresh if the day changed (avoids redundant notifications)
                        TopShelfManager.shared.refreshIfNeeded()
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
                requestDeepLinkPainting(painting)
            }

        case "gradient":
            // Handle galleryglow://gradient/PaletteName URLs
            let paletteName = url.path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""

            // Find the gradient palette
            if let palette = GradientPalette.allCases.first(where: { $0.rawValue == paletteName }) {
                requestDeepLinkGradient(palette)
            }

        default:
            break
        }
    }

    private func requestDeepLinkPainting(_ painting: Painting) {
        guard purchaseManager.isUnlocked else {
            pendingDeepLinkPainting = painting
            pendingDeepLinkGradient = nil
            showDeepLinkPaywall = true
            return
        }

        presentDeepLinkPainting(painting)
    }

    private func requestDeepLinkGradient(_ palette: GradientPalette) {
        guard purchaseManager.isUnlocked else {
            pendingDeepLinkPainting = nil
            pendingDeepLinkGradient = palette
            showDeepLinkPaywall = true
            return
        }

        presentDeepLinkGradient(palette)
    }

    private func presentPendingDeepLinkIfUnlocked() {
        guard purchaseManager.isUnlocked else { return }

        if let painting = pendingDeepLinkPainting {
            pendingDeepLinkPainting = nil
            presentDeepLinkPainting(painting)
        } else if let palette = pendingDeepLinkGradient {
            pendingDeepLinkGradient = nil
            presentDeepLinkGradient(palette)
        }

        showDeepLinkPaywall = false
    }

    private func presentDeepLinkPainting(_ painting: Painting) {
        RecentlyUsedManager.shared.addPainting(painting)
        deepLinkPainting = painting
    }

    private func presentDeepLinkGradient(_ palette: GradientPalette) {
        RecentlyUsedManager.shared.addGradient(
            palette: palette.rawValue,
            description: palette.displayDescription
        )
        deepLinkGradient = palette
    }
}
