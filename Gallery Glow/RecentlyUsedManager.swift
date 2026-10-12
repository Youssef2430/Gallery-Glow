//
//  RecentlyUsedManager.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import TVServices
import Observation

/// Represents a recently used item (either a painting or gradient).
/// This file is compiled into both the app and the Gallery Shelf extension targets,
/// so both sides always share the same JSON schema.
nonisolated struct RecentlyUsedItem: Codable, Equatable, Sendable {
    enum ItemType: String, Codable, Sendable {
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
@MainActor @Observable
final class RecentlyUsedManager {
    static let shared = RecentlyUsedManager()

    /// Key for storing recently used items
    private let recentlyUsedKey = "recentlyUsedItems"

    /// Maximum number of recent items to keep
    private let maxRecentItems = 10

    /// Cached UserDefaults instance for the App Group (initialized once)
    @ObservationIgnored private let sharedDefaults: UserDefaults?
    @ObservationIgnored private let notify: () -> Void
    private(set) var items: [RecentlyUsedItem]

    init(defaults: UserDefaults? = UserDefaults(suiteName: "group.com.galleryglow.shared"),
         notify: @escaping () -> Void = { TVTopShelfContentProvider.topShelfContentDidChange() }) {
        sharedDefaults = defaults
        self.notify = notify
        if let data = defaults?.data(forKey: "recentlyUsedItems"),
           let saved = try? JSONDecoder().decode([RecentlyUsedItem].self, from: data) {
            var seen = Set<String>()
            items = Array(saved.sorted { $0.timestamp > $1.timestamp }.filter {
                seen.insert("\($0.type.rawValue)/\($0.identifier)").inserted
            }.prefix(10))
        } else {
            items = []
        }
    }

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
        // The extension can stay alive while the app writes a new snapshot.
        guard let data = sharedDefaults?.data(forKey: recentlyUsedKey),
              let saved = try? JSONDecoder().decode([RecentlyUsedItem].self, from: data) else { return [] }
        return Array(saved.sorted { $0.timestamp > $1.timestamp }.prefix(maxRecentItems))
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
        guard !items.isEmpty else { return }
        items = []
        sharedDefaults?.removeObject(forKey: recentlyUsedKey)
        notifyTopShelfUpdate()
    }

    // MARK: - Private Helpers

    private func addItem(_ item: RecentlyUsedItem) {
        var items = self.items

        // Remove existing item with same identifier and type (to update timestamp)
        items.removeAll { $0 == item }

        // Add new item at the beginning
        items.insert(item, at: 0)

        // Trim to max count
        if items.count > maxRecentItems {
            items = Array(items.prefix(maxRecentItems))
        }

        // Publish immediately so the gallery reflects the selection on return.
        self.items = items
        saveItems(items)

        // Notify Top Shelf to update
        notifyTopShelfUpdate()
    }

    private func saveItems(_ items: [RecentlyUsedItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        sharedDefaults?.set(data, forKey: recentlyUsedKey)
    }

    private func notifyTopShelfUpdate() {
        notify()
    }
}
