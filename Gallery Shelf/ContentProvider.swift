//
//  ContentProvider.swift
//  Gallery Shelf
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent() async -> TVTopShelfContent? {
        var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

        // MARK: Section 1 - Painting of the Day
        let potd = PaintingData.shared.paintingOfTheDay()

        let featuredSection = TVTopShelfItemCollection(items: [paintingItem(for: potd, idPrefix: "potd")])
        featuredSection.title = "Painting of the Day"
        sections.append(featuredSection)

        // MARK: Section 2 - Recently Used
        var recentTopShelfItems: [TVTopShelfSectionedItem] = []

        for recentItem in RecentlyUsedManager.shared.getRecentItems().prefix(8) {
            let item = TVTopShelfSectionedItem(identifier: "recent_\(recentItem.identifier)")
            item.title = recentItem.title
            // Pre-rendered images are 16:9; without this the system crops them
            // into squares and upscales, which looks soft
            item.imageShape = .hdtv

            switch recentItem.type {
            case .painting:
                if let imageURL = imageURL(for: recentItem.identifier) {
                    item.setImageURL(imageURL, for: .screenScale1x)
                    item.setImageURL(imageURL, for: .screenScale2x)
                }
                if let url = deepLinkURL(kind: "painting", identifier: recentItem.identifier) {
                    item.displayAction = TVTopShelfAction(url: url)
                    item.playAction = item.displayAction
                }

            case .gradient:
                if let imageURL = gradientImageURL(for: recentItem.identifier) {
                    item.setImageURL(imageURL, for: .screenScale1x)
                    item.setImageURL(imageURL, for: .screenScale2x)
                }
                if let url = deepLinkURL(kind: "gradient", identifier: recentItem.identifier) {
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

        // MARK: Section 3 - Director's Cut
        let directorsCutItems = PaintingData.shared.directorsCut
            .filter { $0.id != potd.id } // skip the painting of the day (already featured)
            .map { paintingItem(for: $0, idPrefix: "dc") }

        if !directorsCutItems.isEmpty {
            let directorsCutSection = TVTopShelfItemCollection(items: directorsCutItems)
            directorsCutSection.title = "Director's Cut"
            sections.append(directorsCutSection)
        }

        return TVTopShelfSectionedContent(sections: sections)
    }

    // MARK: - Item Builders

    private func paintingItem(for painting: Painting, idPrefix: String) -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: "\(idPrefix)_\(painting.imageName)")
        item.title = painting.title
        item.imageShape = .hdtv

        if let imageURL = imageURL(for: painting.imageName) {
            item.setImageURL(imageURL, for: .screenScale1x)
            item.setImageURL(imageURL, for: .screenScale2x)
        }

        if let url = deepLinkURL(kind: "painting", identifier: painting.imageName) {
            item.displayAction = TVTopShelfAction(url: url)
            item.playAction = item.displayAction
        }

        return item
    }

    private func deepLinkURL(kind: String, identifier: String) -> URL? {
        let encoded = identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? identifier
        return URL(string: "galleryglow://\(kind)/\(encoded)")
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
