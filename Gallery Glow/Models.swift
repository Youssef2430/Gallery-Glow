//
//  Models.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation

struct Artist: Identifiable, Hashable {
    /// Deterministic ID derived from artist name (stable across app launches)
    var id: String { name }
    let name: String
    let birthYear: Int
    let deathYear: Int?
    let nationality: String
    let paintings: [Painting]

    var lifespan: String {
        if let death = deathYear {
            return "\(birthYear) - \(death)"
        }
        return "\(birthYear) - Present"
    }
}

struct Painting: Identifiable, Hashable {
    /// Deterministic ID derived from imageName (unique per painting, stable across app launches)
    var id: String { imageName }
    let title: String
    let year: Int
    let artistName: String
    let imageName: String
    let description: String
    let forceFullScreen: Bool

    init(title: String, year: Int, artistName: String, imageName: String, description: String, forceFullScreen: Bool = false) {
        self.title = title
        self.year = year
        self.artistName = artistName
        self.imageName = imageName
        self.description = description
        self.forceFullScreen = forceFullScreen
    }
}
