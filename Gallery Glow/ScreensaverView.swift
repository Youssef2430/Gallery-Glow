//
//  ScreensaverView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import UIKit

struct ScreensaverView: View {
    let painting: Painting
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo = false
    @State private var infoOpacity: Double = 0
    @State private var imageAspectRatio: CGFloat = 1.0

    // TV screen aspect ratio is 16:9 = 1.777...
    private let screenAspectRatio: CGFloat = 16.0 / 9.0
    // Tolerance for considering an image "close enough" to 16:9
    private let aspectRatioTolerance: CGFloat = 0.15

    private var shouldFillScreen: Bool {
        // Force fullscreen for specially curated paintings
        if painting.forceFullScreen {
            return true
        }
        // If image aspect ratio is close to screen aspect ratio, fill to avoid black bars
        return abs(imageAspectRatio - screenAspectRatio) / screenAspectRatio < aspectRatioTolerance
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                // Painting image - fill for 16:9-ish images, fit for others
                PaintingImage(painting.imageName, contentMode: shouldFillScreen ? .fill : .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .onAppear {
                        // Calculate aspect ratio without loading full image
                        if let ratio = getImageAspectRatio(for: painting.imageName) {
                            imageAspectRatio = ratio
                        }
                    }

            // Info overlay
            VStack {
                Spacer()

                if showInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(painting.title)
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("\(painting.artistName), \(String(painting.year))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 60)
                    .opacity(infoOpacity)
                }
            }
        }
        }
        .ignoresSafeArea()
        .onAppear {
            // Prevent TV from going into power saving mode while displaying painting
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Re-enable idle timer when leaving the view
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.3)) {
                showInfo.toggle()
                infoOpacity = showInfo ? 1 : 0
            }
        }
        .onExitCommand {
            dismiss()
        }
    }
}

#Preview {
    ScreensaverView(painting: PaintingData.shared.allPaintings[0])
}
