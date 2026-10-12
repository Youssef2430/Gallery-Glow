import SwiftUI
import Observation

/// One presentation owner for cards, artist pages, and Top Shelf links. Updating
/// the selection replaces an open screensaver without stacking modal covers.
@MainActor @Observable
final class GallerySession {
    enum Selection: Identifiable, Equatable {
        case painting(Painting)
        case gradient(GradientPalette)

        var id: String {
            switch self {
            case .painting(let painting): "painting/\(painting.id)"
            case .gradient(let palette): "gradient/\(palette.id)"
            }
        }
    }

    var selection: Selection?
    var linkError = false
    let purchases: PurchaseManager
    private(set) var pendingSelection: Selection?
    var isStorePresented = false
    private let now: () -> Date
    private var freeViewingSelectionID: String?

    init(purchases: PurchaseManager? = nil, now: @escaping () -> Date = Date.init) {
        self.purchases = purchases ?? PurchaseManager()
        self.now = now
    }

    var isPresenting: Bool { selection != nil || isStorePresented }
    var freePainting: Painting { PaintingData.shared.paintingOfTheDay(on: now()) }

    private func isFree(_ selection: Selection) -> Bool {
        guard case .painting(let painting) = selection else { return false }
        return painting.id == freePainting.id
    }

    private func canAccess(_ selection: Selection) -> Bool {
        purchases.isUnlocked || isFree(selection)
    }

    func showStore() { isStorePresented = true }

    func dismissPresentation() {
        selection = nil
        pendingSelection = nil
        isStorePresented = false
        freeViewingSelectionID = nil
    }

    func reconcileAccess() {
        if let pendingSelection, canAccess(pendingSelection) {
            self.pendingSelection = nil
            isStorePresented = false
            present(pendingSelection)
        } else if purchases.entitlement != .checking, let selection,
                  selection.id != freeViewingSelectionID, !canAccess(selection) {
            self.selection = nil
            pendingSelection = selection
            isStorePresented = true
        }
    }

    func present(_ selection: Selection) {
        linkError = false
        let isDailyArtwork = isFree(selection)
        guard purchases.isUnlocked || isDailyArtwork else {
            freeViewingSelectionID = nil
            pendingSelection = selection
            self.selection = nil
            isStorePresented = true
            return
        }
        pendingSelection = nil
        isStorePresented = false
        // An admitted free viewing session is uninterrupted by midnight or a
        // delayed StoreKit response. Reopening always checks the current day.
        freeViewingSelectionID = isDailyArtwork ? selection.id : nil
        self.selection = selection
        switch selection {
        case .painting(let painting): RecentlyUsedManager.shared.addPainting(painting)
        case .gradient(let palette):
            RecentlyUsedManager.shared.addGradient(palette: palette.rawValue,
                                                  description: palette.displayDescription)
        }
    }

    func open(_ url: URL) {
        guard url.scheme?.lowercased() == "galleryglow" else { return }
        guard let selection = Self.selection(for: url) else {
            linkError = true
            return
        }
        present(selection)
    }

    static func selection(for url: URL) -> Selection? {
        guard url.scheme?.lowercased() == "galleryglow" else { return nil }
        // URL.path has already decoded percent escapes. Decoding it again would
        // break legitimate identifiers that contain a percent sign.
        let identifier = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return selection(kind: url.host ?? "", identifier: identifier)
    }

    static func selection(kind: String, identifier: String) -> Selection? {
        switch kind {
        case "painting":
            return PaintingData.shared.allPaintings.first { $0.imageName == identifier }.map(Selection.painting)
        case "gradient":
            return GradientPalette(rawValue: identifier).map(Selection.gradient)
        default: return nil
        }
    }
}

struct ScreensaverPresentation: View {
    let selection: GallerySession.Selection

    var body: some View {
        switch selection {
        case .painting(let painting): ScreensaverView(painting: painting)
        case .gradient(let palette): GradientScreensaverView(palette: palette)
        }
    }
}
