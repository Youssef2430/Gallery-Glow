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
    
    private init() {
        // Vincent van Gogh
        let vanGoghPaintings = [
            Painting(title: "Self-Portrait", year: 1889, artistName: "Vincent van Gogh", imageName: "Van Gogh/self-portrait_1998.74.5", description: "One of van Gogh's many introspective self-portraits, revealing his intense gaze and bold brushwork."),
            Painting(title: "Farmhouse in Provence", year: 1888, artistName: "Vincent van Gogh", imageName: "Van Gogh/farmhouse_in_provence_1970.17.34", description: "A vibrant depiction of rural life in southern France during van Gogh's time in Arles."),
            Painting(title: "Flower Beds in Holland", year: 1883, artistName: "Vincent van Gogh", imageName: "Van Gogh/flower_beds_in_holland_1983.1.21", description: "An early work showing the colorful tulip fields of the Netherlands."),
            Painting(title: "Roses", year: 1890, artistName: "Vincent van Gogh", imageName: "Van Gogh/roses_1991.67.1", description: "A lush still life painted during van Gogh's final months at Saint-Rémy."),
            Painting(title: "Seascape at Port-en-Bessin", year: 1888, artistName: "Vincent van Gogh", imageName: "Van Gogh/seascape_at_port-en-bessin_normandy_1972.9.21", description: "A coastal scene capturing the movement of the sea and sky."),
            Painting(title: "Still Life of Oranges and Lemons with Blue Gloves", year: 1889, artistName: "Vincent van Gogh", imageName: "Van Gogh/still_life_of_oranges_and_lemons_with_blue_gloves_2014.18.13", description: "A colorful still life showcasing van Gogh's mastery of complementary colors."),
            Painting(title: "The Zandmennik House", year: 1879, artistName: "Vincent van Gogh", imageName: "Van Gogh/the_zandmennik_house_1991.217.66", description: "An early drawing from van Gogh's time in the Borinage mining region.")
        ]
        
        // Claude Monet
        let monetPaintings = [
            Painting(title: "The Japanese Footbridge", year: 1899, artistName: "Claude Monet", imageName: "Monet/the_japanese_footbridge_1992.9.1", description: "The iconic green footbridge over Monet's water lily pond at Giverny."),
            Painting(title: "The Artist's Garden in Argenteuil", year: 1873, artistName: "Claude Monet", imageName: "Monet/the_artist_s_garden_in_argenteuil_a_corner_of_the_garden_with_dahlias_1991.27.1", description: "A corner of Monet's garden with dahlias in full bloom."),
            Painting(title: "The Bridge at Argenteuil", year: 1874, artistName: "Claude Monet", imageName: "Monet/the_bridge_at_argenteuil_1983.1.24", description: "A sunlit view of the bridge at Argenteuil with sailboats on the Seine."),
            Painting(title: "Waterloo Bridge, London at Sunset", year: 1904, artistName: "Claude Monet", imageName: "Monet/waterloo_bridge_london_at_sunset_1983.1.28", description: "Part of Monet's London series, capturing the atmospheric effects of fog and light.")
        ]
        
        // Leonardo da Vinci
        let daVinciPaintings = [
            Painting(title: "Mona Lisa", year: 1503, artistName: "Leonardo da Vinci", imageName: "Da Vinci/Mona_Lisa", description: "The world's most famous portrait, known for her enigmatic smile."),
            Painting(title: "The Last Supper", year: 1498, artistName: "Leonardo da Vinci", imageName: "Da Vinci/Last-Supper-wall-painting-restoration-Leonardo-da-1999", description: "A mural depicting Jesus and his disciples at the moment Jesus announces betrayal."),
            Painting(title: "The Virgin and Child with Saint Anne", year: 1510, artistName: "Leonardo da Vinci", imageName: "Da Vinci/After-restoration-The-Virgin-Child-Jesus-and-Saint-Anne-Leonardo-da-Vinci-Louvre-Paris", description: "A masterwork showing three generations: Saint Anne, the Virgin Mary, and the Christ Child.")
        ]
        
        // Johannes Vermeer
        let vermeerPaintings = [
            Painting(title: "Girl with a Pearl Earring", year: 1665, artistName: "Johannes Vermeer", imageName: "Vermeer/1665_Girl_with_a_Pearl_Earring", description: "Often called the 'Mona Lisa of the North', a captivating portrait of a girl."),
            Painting(title: "View of Delft", year: 1661, artistName: "Johannes Vermeer", imageName: "Vermeer/View_of_Delft", description: "A cityscape of Vermeer's hometown, celebrated for its luminous atmosphere.")
        ]
        
        // Rembrandt van Rijn
        let rembrandtPaintings = [
            Painting(title: "The Mill", year: 1645, artistName: "Rembrandt van Rijn", imageName: "Van Rijn/the_mill_1942.9.62", description: "A dramatic landscape featuring a windmill silhouetted against a stormy sky."),
            Painting(title: "Philemon and Baucis", year: 1658, artistName: "Rembrandt van Rijn", imageName: "Van Rijn/philemon_and_baucis_1942.9.65", description: "A mythological scene depicting the hospitable elderly couple visited by the gods."),
            Painting(title: "The Circumcision", year: 1661, artistName: "Rembrandt van Rijn", imageName: "Van Rijn/the_circumcision_1942.9.60", description: "A religious scene rendered with Rembrandt's characteristic use of light and shadow.")
        ]
        
        // Gustav Klimt
        let klimtPaintings = [
            Painting(title: "Curled Up Girl on Bed", year: 1917, artistName: "Gustav Klimt", imageName: "Klimt/curled_up_girl_on_bed_1974.83.1", description: "An intimate drawing showing Klimt's mastery of the human form.")
        ]
        
        // Edvard Munch
        let munchPaintings = [
            Painting(title: "Telthusbakken with Gamle Aker Church", year: 1880, artistName: "Edvard Munch", imageName: "Munch/Edvard_Munch_-_Telthusbakken_with_Gamle_Aker_Church_(1880)", description: "An early landscape showing the old Aker church in Oslo."),
            Painting(title: "Horse and Wagon in front of Farm Buildings", year: 1882, artistName: "Edvard Munch", imageName: "Munch/Horse_and_Wagon_in_front_of_Farm_Buildings_Munch", description: "A rural scene from Munch's early naturalist period."),
            Painting(title: "Linde Frieze", year: 1904, artistName: "Edvard Munch", imageName: "Munch/Linde_Frieze", description: "Part of a decorative frieze commissioned for Dr. Max Linde's home.")
        ]
        
        // Michelangelo
        let michelangeloPaintings = [
            Painting(title: "The Creation of Adam", year: 1512, artistName: "Michelangelo", imageName: "Michelangelo/Creación_de_Adán", description: "The iconic Sistine Chapel fresco depicting God giving life to the first man.")
        ]
        
        // Create artists
        artists = [
            Artist(name: "Vincent van Gogh", birthYear: 1853, deathYear: 1890, nationality: "Dutch", paintings: vanGoghPaintings),
            Artist(name: "Claude Monet", birthYear: 1840, deathYear: 1926, nationality: "French", paintings: monetPaintings),
            Artist(name: "Leonardo da Vinci", birthYear: 1452, deathYear: 1519, nationality: "Italian", paintings: daVinciPaintings),
            Artist(name: "Johannes Vermeer", birthYear: 1632, deathYear: 1675, nationality: "Dutch", paintings: vermeerPaintings),
            Artist(name: "Rembrandt van Rijn", birthYear: 1606, deathYear: 1669, nationality: "Dutch", paintings: rembrandtPaintings),
            Artist(name: "Gustav Klimt", birthYear: 1862, deathYear: 1918, nationality: "Austrian", paintings: klimtPaintings),
            Artist(name: "Edvard Munch", birthYear: 1863, deathYear: 1944, nationality: "Norwegian", paintings: munchPaintings),
            Artist(name: "Michelangelo", birthYear: 1475, deathYear: 1564, nationality: "Italian", paintings: michelangeloPaintings)
        ]
        
        // Flatten all paintings for easy access
        allPaintings = artists.flatMap { $0.paintings }
    }
    
    /// Returns a deterministic "painting of the day" based on the current date
    func paintingOfTheDay() -> Painting {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % allPaintings.count
        return allPaintings[index]
    }
}
