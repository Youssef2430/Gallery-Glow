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

        // Claude Monet
        let monetPaintings = [
            Painting(title: "Stacks of Wheat (End of Summer)", year: 1891, artistName: "Claude Monet", imageName: "Monet/Stacks_of_Wheat_End_of_Summer", description: "A wide view from Monet's Stacks of Wheat series, capturing the late-season fields near Giverny through layered color and light.", forceFullScreen: true)
        ]

        // Frederic Edwin Church
        let churchPaintings = [
            Painting(title: "Heart of the Andes", year: 1859, artistName: "Frederic Edwin Church", imageName: "Church/Heart_of_the_Andes", description: "A sweeping South American landscape that layers mountain, forest, water, and sky into a dramatic panoramic view.", forceFullScreen: true)
        ]

        // Emanuel Leutze
        let leutzePaintings = [
            Painting(title: "Washington Crossing the Delaware", year: 1851, artistName: "Emanuel Leutze", imageName: "Leutze/Washington_Crossing_the_Delaware", description: "A monumental history painting of George Washington and the Continental Army crossing the Delaware River.", forceFullScreen: true)
        ]

        // Frans Post
        let postPaintings = [
            Painting(title: "A Brazilian Landscape", year: 1650, artistName: "Frans Post", imageName: "Post/A_Brazilian_Landscape", description: "An early Dutch view of Brazil, composed as a wide tropical landscape with figures, trees, and distant settlement.", forceFullScreen: true)
        ]

        // Create artists
        artists = [
            Artist(name: "Gustav Klimt", birthYear: 1862, deathYear: 1918, nationality: "Austrian", paintings: klimtPaintings),
            Artist(name: "Edvard Munch", birthYear: 1863, deathYear: 1944, nationality: "Norwegian", paintings: munchPaintings),
            Artist(name: "Michelangelo", birthYear: 1475, deathYear: 1564, nationality: "Italian", paintings: michelangeloPaintings),
            Artist(name: "Edward Hopper", birthYear: 1882, deathYear: 1967, nationality: "American", paintings: hopperPaintings),
            Artist(name: "Sandro Botticelli", birthYear: 1445, deathYear: 1510, nationality: "Italian", paintings: botticelliPaintings),
            Artist(name: "Claude Monet", birthYear: 1840, deathYear: 1926, nationality: "French", paintings: monetPaintings),
            Artist(name: "Frederic Edwin Church", birthYear: 1826, deathYear: 1900, nationality: "American", paintings: churchPaintings),
            Artist(name: "Emanuel Leutze", birthYear: 1816, deathYear: 1868, nationality: "German-American", paintings: leutzePaintings),
            Artist(name: "Frans Post", birthYear: 1612, deathYear: 1680, nationality: "Dutch", paintings: postPaintings)
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
