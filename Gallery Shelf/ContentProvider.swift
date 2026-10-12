import Foundation
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> TVTopShelfContent? {
        let data = PaintingData.shared
        let now = Date()
        let today = data.paintingOfTheDay(on: now)
        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        let featured = paintingItem(for: today, idPrefix: "potd", featured: true)
        if let featured {
            let section = TVTopShelfItemCollection(items: [featured])
            section.title = "Painting of the Day"
            sections.append(section)
        }

        // Resolve persisted entries against the current catalog, just as the
        // in-app recents row does. Removed works must not leave empty cards.
        let recents = await RecentlyUsedManager.shared.getRecentItems()
        var seen = Set<String>()
        let recentItems = recents.compactMap { recent -> TVTopShelfSectionedItem? in
            let key = "\(recent.type.rawValue)_\(recent.identifier)"
            guard seen.insert(key).inserted else { return nil }
            switch recent.type {
            case .painting:
                guard let painting = data.allPaintings.first(where: { $0.imageName == recent.identifier }) else { return nil }
                return paintingItem(for: painting, idPrefix: "recent_painting")
            case .gradient:
                guard let palette = GradientPalette(rawValue: recent.identifier) else { return nil }
                let resource = "gradient_" + palette.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
                return item(identifier: "recent_\(key)", title: palette.rawValue,
                            resource: resource, kind: "gradient", route: palette.rawValue)
            }
        }
        if !recentItems.isEmpty {
            let section = TVTopShelfItemCollection(items: Array(recentItems.prefix(8)))
            section.title = "Recently Viewed"
            sections.append(section)
        }

        let selectedWorks = data.directorsCut.filter { $0.id != today.id }
            .compactMap { paintingItem(for: $0, idPrefix: "dc") }
        if !selectedWorks.isEmpty {
            let section = TVTopShelfItemCollection(items: selectedWorks)
            section.title = "Director’s Cut"
            sections.append(section)
        }
        return sections.isEmpty ? nil : TVTopShelfSectionedContent(sections: sections)
    }

    private func paintingItem(for painting: Painting, idPrefix: String, featured: Bool = false) -> TVTopShelfSectionedItem? {
        let resource = painting.imageName.replacingOccurrences(of: "/", with: "_")
        return item(identifier: "\(idPrefix)_\(painting.imageName)", title: painting.title,
                    resource: (featured ? "featured_" : "") + resource,
                    kind: "painting", route: painting.imageName)
    }

    private func item(identifier: String, title: String, resource: String,
                      kind: String, route: String) -> TVTopShelfSectionedItem? {
        guard let imageURL = imageURL(for: resource),
              let encoded = route.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "galleryglow://\(kind)/\(encoded)") else { return nil }
        let item = TVTopShelfSectionedItem(identifier: identifier)
        // Native titles stay readable in either appearance and accessible to
        // VoiceOver. Keep painting names out of the image to avoid a duplicate title.
        item.title = title
        item.imageShape = .hdtv
        item.setImageURL(imageURL, for: .screenScale1x)
        item.setImageURL(imageURL, for: .screenScale2x)
        item.displayAction = TVTopShelfAction(url: url)
        item.playAction = item.displayAction
        return item
    }

    private func imageURL(for resource: String) -> URL? {
        // Pre-rendered 888 × 500 JPEGs keep the extension lightweight. Xcode
        // can preserve the resource folder or flatten it when bundling.
        Bundle.main.url(forResource: resource, withExtension: "jpg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resource, withExtension: "jpg")
    }
}
