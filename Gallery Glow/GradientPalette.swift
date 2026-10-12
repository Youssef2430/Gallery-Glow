import SwiftUI

// MARK: - Gradient Palette

nonisolated enum GradientPalette: String, CaseIterable, Identifiable {
    case magentaPurple = "Magenta Purple"
    case pinkOrange = "Pink Orange"
    case oceanBlue = "Ocean Blue"
    case sunriseGold = "Sunrise Gold"
    case aurora = "Aurora"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .magentaPurple:
            return Self.allPalettes[0]
        case .pinkOrange:
            return Self.allPalettes[1]
        case .oceanBlue:
            return Self.allPalettes[2]
        case .sunriseGold:
            return Self.allPalettes[3]
        case .aurora:
            return Self.allPalettes[4]
        }
    }

    var previewColors: [Color] { colors }

    /// Description for display in cards and Top Shelf
    var displayDescription: String {
        switch self {
        case .magentaPurple:
            return "Neon nights"
        case .pinkOrange:
            return "Warm sunset"
        case .oceanBlue:
            return "Deep sea"
        case .sunriseGold:
            return "Golden hour"
        case .aurora:
            return "Northern lights"
        }
    }

    private static let allPalettes: [[Color]] = [
        // Magenta-Purple - vibrant neon purples and magentas
        [
            Color(red: 1.0, green: 0.0, blue: 0.8),      // Bright magenta
            Color(red: 0.7, green: 0.0, blue: 1.0),      // Violet
            Color(red: 0.5, green: 0.0, blue: 0.9),      // Deep purple
            Color(red: 0.9, green: 0.2, blue: 1.0),      // Light purple
        ],
        // Pink-Orange - warm sunset vibes
        [
            Color(red: 1.0, green: 0.2, blue: 0.5),      // Hot pink
            Color(red: 1.0, green: 0.4, blue: 0.1),      // Orange
            Color(red: 1.0, green: 0.6, blue: 0.2),      // Golden orange
            Color(red: 1.0, green: 0.1, blue: 0.3),      // Red-pink
        ],
        // Ocean Blue - deep sea to cyan
        [
            Color(red: 0.0, green: 0.8, blue: 1.0),      // Cyan
            Color(red: 0.0, green: 0.4, blue: 0.9),      // Ocean blue
            Color(red: 0.2, green: 0.6, blue: 1.0),      // Sky blue
            Color(red: 0.0, green: 0.9, blue: 0.8),      // Turquoise
        ],
        // Sunrise Gold - warm yellows and oranges
        [
            Color(red: 1.0, green: 0.85, blue: 0.0),     // Golden yellow
            Color(red: 1.0, green: 0.6, blue: 0.0),      // Orange
            Color(red: 1.0, green: 0.9, blue: 0.3),      // Light yellow
            Color(red: 1.0, green: 0.5, blue: 0.1),      // Deep orange
        ],
        // Aurora - northern lights inspired
        [
            Color(red: 0.0, green: 1.0, blue: 0.6),      // Green
            Color(red: 0.3, green: 0.8, blue: 1.0),      // Cyan
            Color(red: 0.6, green: 0.2, blue: 1.0),      // Purple
            Color(red: 0.0, green: 0.9, blue: 0.5),      // Teal
        ],
    ]
}
