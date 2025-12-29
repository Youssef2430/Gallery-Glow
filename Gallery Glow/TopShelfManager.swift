//
//  TopShelfManager.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import TVServices

/// Manages Top Shelf content refresh when the painting of the day changes
class TopShelfManager {
    static let shared = TopShelfManager()
    
    private let lastRefreshDateKey = "TopShelfLastRefreshDate"
    
    private init() {}
    
    /// Refresh the top shelf if the day has changed since the last refresh
    func refreshIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the last refresh date
        if let lastRefreshDate = UserDefaults.standard.object(forKey: lastRefreshDateKey) as? Date {
            let lastRefreshDay = calendar.startOfDay(for: lastRefreshDate)
            
            // Only refresh if the day has changed
            if today > lastRefreshDay {
                refresh()
            }
        } else {
            // First launch, refresh to ensure top shelf is populated
            refresh()
        }
    }
    
    /// Force refresh the top shelf content
    func refresh() {
        // Store the current date as last refresh
        UserDefaults.standard.set(Date(), forKey: lastRefreshDateKey)
        
        // Notify tvOS that the top shelf content has changed
        TVTopShelfContentProvider.topShelfContentDidChange()
    }
}
