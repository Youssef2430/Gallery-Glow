#if DEBUG
import SwiftUI
import UIKit

/// Deterministic fault injection for UI tests. This entire harness is absent
/// from Release builds and is only entered with an explicit test environment.
struct GalleryUITestFixture: View {
    let scenario: String
    private let loader: PaintingImageLoader
    @State private var imageName = "Hopper/Nighthawks"
    @FocusState private var hasRemoteFocus: Bool

    init(scenario: String) {
        self.scenario = scenario
        let decoder = FixtureDecoder(scenario: scenario)
        let cache = ImageCache()
        if scenario == "optimistic",
           let request = ImageRequest(imageName: "Hopper/Nighthawks", size: CGSize(width: 400, height: 225), contentMode: .fill, scale: 1),
           let image = downsampleImage(named: request.imageName, to: request.size) {
            cache.insert(image, for: request)
        }
        loader = PaintingImageLoader(cache: cache, decode: { decoder.decode($0) })
    }

    var body: some View {
        if scenario == "reduce-motion" {
            GradientScreensaverView(palette: .aurora, reduceMotionOverride: true)
        } else if scenario == "fit" {
            ScreensaverView(painting: Painting(
                title: "The Creation of Adam", year: 1512, artistName: "Michelangelo",
                imageName: "Michelangelo/Creation_of_Adam", description: "Fit-mode verification",
                forceFullScreen: false
            ))
        } else if scenario == "identity" {
            PaintingImage(imageName, allowsRetry: true, loader: loader)
                .ignoresSafeArea()
                .focusable()
                .focused($hasRemoteFocus)
                .onAppear { hasRemoteFocus = true }
                .focusEffectDisabled()
                .onPlayPauseCommand {
                    imageName = "Munch/Linde_Frieze"
                }
        } else {
            ScreensaverView(painting: PaintingData.shared.allPaintings.first { $0.imageName == "Hopper/Nighthawks" }!, loader: loader)
        }
    }
}

nonisolated private final class FixtureDecoder: @unchecked Sendable {
    private let scenario: String
    private let lock = NSLock()
    private var calls = 0
    init(scenario: String) { self.scenario = scenario }

    func decode(_ request: ImageRequest) -> UIImage? {
        let call = lock.withLock { calls += 1; return calls }
        if scenario == "retry" && call == 1 { return nil }
        if scenario == "missing" { return nil }
        if scenario == "slow" || scenario == "optimistic" ||
            (scenario == "identity" && request.imageName == "Hopper/Nighthawks") {
            Thread.sleep(forTimeInterval: 8)
        }
        return downsampleImage(named: request.imageName, to: request.size, contentMode: request.contentMode)
    }
}
#endif
