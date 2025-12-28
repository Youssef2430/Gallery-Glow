//
//  Gallery_GlowApp.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

@main
struct Gallery_GlowApp: App {
    @State private var deepLinkPainting: Painting?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .fullScreenCover(item: $deepLinkPainting) { painting in
                    ScreensaverView(painting: painting)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        // Handle galleryglow://painting/ImageName URLs
        guard url.scheme == "galleryglow",
              url.host == "painting" else { return }
        
        // Get the image name from the URL path
        let imageName = url.path.removingPercentEncoding?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        
        // Find the painting with this image name
        if let painting = PaintingData.shared.allPaintings.first(where: { $0.imageName == imageName }) {
            deepLinkPainting = painting
        }
    }
}
