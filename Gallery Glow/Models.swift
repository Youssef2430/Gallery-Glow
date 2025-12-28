//
//  Models.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation

struct Artist: Identifiable, Hashable {
    let id = UUID()
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
    let id = UUID()
    let title: String
    let year: Int
    let artistName: String
    let imageName: String
    let description: String
}
