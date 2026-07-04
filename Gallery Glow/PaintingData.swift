//
//  PaintingData.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation

class PaintingData {
    static let shared = PaintingData()

    let artists: [Artist]
    let allPaintings: [Painting]
    let directorsCut: [Painting]

    private init() {
        // Gustav Klimt
        let klimtPaintings = [
            Painting(title: "Curled Up Girl on Bed", year: 1917, artistName: "Gustav Klimt", imageName: "Klimt/curled_up_girl_on_bed_1974.83.1", description: "An intimate drawing showing Klimt's mastery of the human form.", forceFullScreen: true)
        ]

        // Edvard Munch
        let munchPaintings = [
            Painting(title: "Linde Frieze", year: 1904, artistName: "Edvard Munch", imageName: "Munch/Linde_Frieze", description: "Part of a decorative frieze commissioned for Dr. Max Linde's home.", forceFullScreen: true)
        ]

        // Michelangelo
        let michelangeloPaintings = [
            Painting(title: "The Creation of Adam", year: 1512, artistName: "Michelangelo", imageName: "Michelangelo/Creation_of_Adam", description: "The iconic Sistine Chapel fresco depicting God giving life to the first man.", forceFullScreen: true)
        ]

        // Edward Hopper
        let hopperPaintings = [
            Painting(title: "Nighthawks", year: 1942, artistName: "Edward Hopper", imageName: "Hopper/Nighthawks", description: "An iconic depiction of urban isolation, showing customers in a late-night diner in New York City.", forceFullScreen: true)
        ]

        // Sandro Botticelli
        let botticelliPaintings = [
            Painting(title: "The Birth of Venus", year: 1485, artistName: "Sandro Botticelli", imageName: "Botticelli/Birth_of_Venus", description: "A mythological masterpiece depicting the goddess Venus emerging from the sea as a fully grown woman.", forceFullScreen: true)
        ]

        // Create artists
        artists = [
            Artist(name: "Gustav Klimt", birthYear: 1862, deathYear: 1918, nationality: "Austrian", paintings: klimtPaintings),
            Artist(name: "Edvard Munch", birthYear: 1863, deathYear: 1944, nationality: "Norwegian", paintings: munchPaintings),
            Artist(name: "Michelangelo", birthYear: 1475, deathYear: 1564, nationality: "Italian", paintings: michelangeloPaintings),
            Artist(name: "Edward Hopper", birthYear: 1882, deathYear: 1967, nationality: "American", paintings: hopperPaintings),
            Artist(name: "Sandro Botticelli", birthYear: 1445, deathYear: 1510, nationality: "Italian", paintings: botticelliPaintings)
        ]

        // Flatten all paintings for easy access
        allPaintings = artists.flatMap { $0.paintings }

        // Director's Cut - curated selection of fullscreen-optimized paintings
        directorsCut = allPaintings.filter { $0.forceFullScreen }
    }

    /// Returns a deterministic "painting of the day" based on the current date
    /// Only selects from Director's Cut paintings (16:9 ratio optimized)
    func paintingOfTheDay() -> Painting {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % directorsCut.count
        return directorsCut[index]
    }
}
