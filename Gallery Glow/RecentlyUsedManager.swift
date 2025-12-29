//
//  RecentlyUsedManager.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import TVServices

/// Represents a recently used item (either a painting or gradient)
struct RecentlyUsedItem: Codable, Equatable {
    enum ItemType: String, Codable {
        case painting
        case gradient
    }

    let type: ItemType
    let identifier: String  // For paintings: imageName, for gradients: palette rawValue
    let title: String
    let subtitle: String?   // Artist name for paintings, description for gradients
    let timestamp: Date

    static func == (lhs: RecentlyUsedItem, rhs: RecentlyUsedItem) -> Bool {
        lhs.type == rhs.type && lhs.identifier == rhs.identifier
    }
}

/// Manages recently used paintings and gradients with persistence via App Groups
class RecentlyUsedManager {
    static let shared = RecentlyUsedManager()

    /// App Group identifier for sharing data with Top Shelf extension
    private let appGroupIdentifier = "group.com.galleryglow.shared"

    /// Key for storing recently used items
    private let recentlyUsedKey = "recentlyUsedItems"

    /// Maximum number of recent items to keep
    private let maxRecentItems = 10

    /// UserDefaults with App Group for sharing with extension
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Public API

    /// Add a painting to recently used
    func addPainting(_ painting: Painting) {
        let item = RecentlyUsedItem(
            type: .painting,
            identifier: painting.imageName,
            title: painting.title,
            subtitle: painting.artistName,
            timestamp: Date()
        )
        addItem(item)
    }

    /// Add a painting by image name (for use from anywhere)
    func addPainting(imageName: String, title: String, artistName: String) {
        let item = RecentlyUsedItem(
            type: .painting,
            identifier: imageName,
            title: title,
            subtitle: artistName,
            timestamp: Date()
        )
        addItem(item)
    }

    /// Add a gradient to recently used
    func addGradient(palette: String, description: String) {
        let item = RecentlyUsedItem(
            type: .gradient,
            identifier: palette,
            title: palette,
            subtitle: description,
            timestamp: Date()
        )
        addItem(item)
    }

    /// Get all recently used items, sorted by most recent first
    func getRecentItems() -> [RecentlyUsedItem] {
        guard let data = sharedDefaults?.data(forKey: recentlyUsedKey),
              let items = try? JSONDecoder().decode([RecentlyUsedItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.timestamp > $1.timestamp }
    }

    /// Get recently used paintings only
    func getRecentPaintings() -> [RecentlyUsedItem] {
        getRecentItems().filter { $0.type == .painting }
    }

    /// Get recently used gradients only
    func getRecentGradients() -> [RecentlyUsedItem] {
        getRecentItems().filter { $0.type == .gradient }
    }

    /// Clear all recently used items
    func clearAll() {
        sharedDefaults?.removeObject(forKey: recentlyUsedKey)
        notifyTopShelfUpdate()
    }

    // MARK: - Private Helpers

    private func addItem(_ item: RecentlyUsedItem) {
        var items = getRecentItems()

        // Remove existing item with same identifier and type (to update timestamp)
        items.removeAll { $0 == item }

        // Add new item at the beginning
        items.insert(item, at: 0)

        // Trim to max count
        if items.count > maxRecentItems {
            items = Array(items.prefix(maxRecentItems))
        }

        // Save
        saveItems(items)

        // Notify Top Shelf to update
        notifyTopShelfUpdate()
    }

    private func saveItems(_ items: [RecentlyUsedItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        sharedDefaults?.set(data, forKey: recentlyUsedKey)
    }

    private func notifyTopShelfUpdate() {
        TVTopShelfContentProvider.topShelfContentDidChange()
    }
}

// MARK: - Convenience Extensions

extension RecentlyUsedManager {
    /// Gradient descriptions for display
    static func gradientDescription(for palette: String) -> String {
        switch palette {
        case "Random":
            return "Surprise me"
        case "Magenta Purple":
            return "Neon nights"
        case "Pink Orange":
            return "Warm sunset"
        case "Ocean Blue":
            return "Deep sea"
        case "Sunrise Gold":
            return "Golden hour"
        case "Aurora":
            return "Northern lights"
        default:
            return "Gradient"
        }
    }
}
