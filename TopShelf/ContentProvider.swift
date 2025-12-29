//
//  ContentProvider.swift
//  TopShelf
//
//  Created by Youssef Chouay on 2025-12-28.
//

import TVServices

// MARK: - Recently Used Item (must match main app's RecentlyUsedManager)

struct RecentlyUsedItem: Codable {
    enum ItemType: String, Codable {
        case painting
        case gradient
    }

    let type: ItemType
    let identifier: String
    let title: String
    let subtitle: String?
    let timestamp: Date
}

// MARK: - Content Provider

class ContentProvider: TVTopShelfContentProvider {

    /// App Group identifier for sharing data with main app
    private let appGroupIdentifier = "group.com.galleryglow.shared"
    private let recentlyUsedKey = "recentlyUsedItems"

    // Director's Cut paintings (16:9 optimized)
    private let directorsCut = [
        ("Van Gogh/Starry_Night_Over_the_Rhone", "Starry Night Over the Rhône", "Vincent van Gogh"),
        ("Monet/the_bridge_at_argenteuil_1983.1.24", "The Bridge at Argenteuil", "Claude Monet"),
        ("Raphael/School_of_Athens", "The School of Athens", "Raphael"),
        ("Hopper/Nighthawks", "Nighthawks", "Edward Hopper"),
        ("Botticelli/Birth_of_Venus", "The Birth of Venus", "Sandro Botticelli"),
        ("Hokusai/Great_Wave", "The Great Wave off Kanagawa", "Katsushika Hokusai")
    ]

    // Gradient palettes
    private let gradientPalettes = [
        ("Random", "Surprise me"),
        ("Magenta Purple", "Neon nights"),
        ("Pink Orange", "Warm sunset"),
        ("Ocean Blue", "Deep sea"),
        ("Sunrise Gold", "Golden hour"),
        ("Aurora", "Northern lights")
    ]

    /// Returns the painting of the day based on current date
    private func paintingOfTheDay() -> (String, String, String) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % directorsCut.count
        return directorsCut[index]
    }

    /// Get recently used items from shared UserDefaults
    private func getRecentlyUsedItems() -> [RecentlyUsedItem] {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = defaults.data(forKey: recentlyUsedKey),
              let items = try? JSONDecoder().decode([RecentlyUsedItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    override func loadTopShelfContent() async -> TVTopShelfContent? {
        var sections: [TVTopShelfItemCollection] = []

        // MARK: Section 1 - Painting of the Day
        let potd = paintingOfTheDay()
        let featuredItem = TVTopShelfSectionedItem(identifier: "potd_\(potd.0)")
        featuredItem.title = potd.1

        if let imageURL = imageURL(for: potd.0) {
            featuredItem.setImageURL(imageURL, for: .screenScale1x)
            featuredItem.setImageURL(imageURL, for: .screenScale2x)
        }

        if let url = URL(string: "galleryglow://painting/\(potd.0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? potd.0)") {
            featuredItem.displayAction = TVTopShelfAction(url: url)
            featuredItem.playAction = featuredItem.displayAction
        }

        let featuredSection = TVTopShelfItemCollection(items: [featuredItem])
        featuredSection.title = "Painting of the Day"
        sections.append(featuredSection)

        // MARK: Section 2 - Recently Used
        let recentItems = getRecentlyUsedItems()
        if !recentItems.isEmpty {
            var recentTopShelfItems: [TVTopShelfSectionedItem] = []

            for recentItem in recentItems.prefix(8) {
                let item = TVTopShelfSectionedItem(identifier: "recent_\(recentItem.identifier)")
                item.title = recentItem.title

                switch recentItem.type {
                case .painting:
                    if let imageURL = imageURL(for: recentItem.identifier) {
                        item.setImageURL(imageURL, for: .screenScale1x)
                        item.setImageURL(imageURL, for: .screenScale2x)
                    }
                    if let url = URL(string: "galleryglow://painting/\(recentItem.identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? recentItem.identifier)") {
                        item.displayAction = TVTopShelfAction(url: url)
                        item.playAction = item.displayAction
                    }

                case .gradient:
                    if let imageURL = gradientImageURL(for: recentItem.identifier) {
                        item.setImageURL(imageURL, for: .screenScale1x)
                        item.setImageURL(imageURL, for: .screenScale2x)
                    }
                    if let url = URL(string: "galleryglow://gradient/\(recentItem.identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? recentItem.identifier)") {
                        item.displayAction = TVTopShelfAction(url: url)
                        item.playAction = item.displayAction
                    }
                }

                recentTopShelfItems.append(item)
            }

            if !recentTopShelfItems.isEmpty {
                let recentSection = TVTopShelfItemCollection(items: recentTopShelfItems)
                recentSection.title = "Recently Used"
                sections.append(recentSection)
            }
        }

        // MARK: Section 3 - Director's Cut
        var directorsCutItems: [TVTopShelfSectionedItem] = []

        for (imageName, title, _) in directorsCut {
            // Skip if it's the painting of the day (already featured)
            if imageName == potd.0 { continue }

            let item = TVTopShelfSectionedItem(identifier: "dc_\(imageName)")
            item.title = title

            if let imageURL = imageURL(for: imageName) {
                item.setImageURL(imageURL, for: .screenScale1x)
                item.setImageURL(imageURL, for: .screenScale2x)
            }

            if let url = URL(string: "galleryglow://painting/\(imageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imageName)") {
                item.displayAction = TVTopShelfAction(url: url)
                item.playAction = item.displayAction
            }

            directorsCutItems.append(item)
        }

        if !directorsCutItems.isEmpty {
            let directorsCutSection = TVTopShelfItemCollection(items: directorsCutItems)
            directorsCutSection.title = "Director's Cut"
            sections.append(directorsCutSection)
        }

        return TVTopShelfSectionedContent(sections: sections)
    }

    // MARK: - Image URL Helpers

    private func imageURL(for imageName: String) -> URL? {
        // Top Shelf extensions have tight memory budgets.
        // Use pre-rendered small JPEGs from TopShelfImages folder.
        let resourceName = imageName.replacingOccurrences(of: "/", with: "_")

        return Bundle.main.url(forResource: resourceName, withExtension: "jpg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpeg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpg")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpeg")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png")
    }

    private func gradientImageURL(for paletteName: String) -> URL? {
        // Look for pre-rendered gradient preview images
        let resourceName = "gradient_\(paletteName.lowercased().replacingOccurrences(of: " ", with: "_"))"

        return Bundle.main.url(forResource: resourceName, withExtension: "jpg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpg")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png")
    }
}
