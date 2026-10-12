import SwiftUI

@main
struct Gallery_GlowApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let fixture = ProcessInfo.processInfo.environment["GALLERY_GLOW_UI_FIXTURE"] {
                GalleryUITestFixture(scenario: fixture)
            } else if let scenario = ProcessInfo.processInfo.environment["GALLERY_GLOW_STORE_FIXTURE"] {
                PurchaseFixtureRoot(scenario: scenario)
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}

#if DEBUG
private struct PurchaseFixtureRoot: View {
    @State private var session: GallerySession
    init(scenario: String) {
        _session = State(initialValue: GallerySession(purchases: PurchaseManager(store: PurchaseUITestStore(scenario: scenario))))
    }
    var body: some View { ContentView(session: session) }
}
#endif
