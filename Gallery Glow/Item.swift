//
//  Item.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
