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
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var hasRemoteFocus: Bool
    @State private var showInfo = false
    @State private var showControls = true
    @State private var imageFailed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let imageAspectRatio: CGFloat
    private let loader: PaintingImageLoader

    init(painting: Painting, loader: PaintingImageLoader = .shared) {
        self.painting = painting
        self.loader = loader
        // Metadata-only read — resolving this up front means shouldFillScreen is
        // correct on first render instead of flipping (and re-decoding) onAppear
        self.imageAspectRatio = painting.forceFullScreen ? 16.0 / 9.0 : (getImageAspectRatio(for: painting.imageName) ?? 1.0)
    }

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

                // Blurred background fill for non-fullscreen paintings
                // Creates a Samsung Frame-style color-matched backdrop instead of black bars.
                // The 50pt blur destroys all fine detail, so decode at a fraction of
                // screen size — same look, a fraction of the memory and decode time.
                if !shouldFillScreen {
                    PaintingImage(painting.imageName, contentMode: .fill, targetSize: CGSize(width: 480, height: 270), loader: loader)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .blur(radius: 50)
                        .brightness(-0.2)
                        .saturation(1.2)
                        .clipped()
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                }

                // Painting image - fill for 16:9-ish images, fit for others
                PaintingImage(painting.imageName, contentMode: shouldFillScreen ? .fill : .fit, allowsRetry: true, loader: loader,
                              onFailureChange: { imageFailed = $0 })
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Info overlay — opacity derived from showInfo, no redundant state
                VStack {
                    Spacer()

                    if showInfo {
                        VStack(alignment: .leading, spacing: 13) {
                            Text("GALLERY GLOW / THE COLLECTION")
                                .font(.system(size: 16, weight: .medium))
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(painting.title)
                                .accessibilityIdentifier("painting-info-title")
                                .font(GalleryTheme.display(46))

                            Text("\(painting.artistName), \(String(painting.year))")
                                .font(.system(size: 23))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        .foregroundStyle(.white)
                        .padding(30)
                        // A predictable scrim keeps text readable even over
                        // pale drawings and in either system appearance.
                        .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 3))
                        .transition(.opacity)
                    }
                    if showControls {
                        Text("Play/Pause for artwork info · Back to gallery")
                            .font(.caption)
                            .padding(16)
                            .background(.regularMaterial, in: Capsule())
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("painting-screensaver")
        .accessibilityLabel("\(painting.title), \(painting.artistName)")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: showInfo)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: showControls)
        .task(id: painting.id) {
            showControls = true
            do { try await Task.sleep(for: .seconds(5)) } catch { return }
            showControls = false
        }
        .focusable(!imageFailed)
        .focused($hasRemoteFocus)
        .defaultFocus($hasRemoteFocus, true)
        .focusEffectDisabled()
        .onChange(of: scenePhase, initial: true) { _, phase in
            hasRemoteFocus = phase == .active && !imageFailed
        }
        .onChange(of: imageFailed) { _, failed in
            hasRemoteFocus = scenePhase == .active && !failed
        }
        .onPlayPauseCommand {
            showInfo.toggle()
        }
        .onExitCommand {
            dismiss()
        }
    }
}

#Preview {
    ScreensaverView(painting: PaintingData.shared.allPaintings[0])
}
