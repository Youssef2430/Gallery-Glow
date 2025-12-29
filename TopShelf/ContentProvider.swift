//
//  ContentProvider.swift
//  TopShelf
//
//  Created by Youssef Chouay on 2025-12-28.
//

import TVServices

struct TopShelfPainting {
    let id: String
    let title: String
    let artistName: String
    let year: Int
    let imageName: String
}

class ContentProvider: TVTopShelfContentProvider {

    // All paintings for the gallery section
    private let allPaintings: [TopShelfPainting] = [
        // Vincent van Gogh
        TopShelfPainting(id: "Van Gogh/self-portrait_1998.74.5", title: "Self-Portrait", artistName: "Vincent van Gogh", year: 1889, imageName: "Van Gogh/self-portrait_1998.74.5"),
        TopShelfPainting(id: "Van Gogh/farmhouse_in_provence_1970.17.34", title: "Farmhouse in Provence", artistName: "Vincent van Gogh", year: 1888, imageName: "Van Gogh/farmhouse_in_provence_1970.17.34"),
        TopShelfPainting(id: "Van Gogh/flower_beds_in_holland_1983.1.21", title: "Flower Beds in Holland", artistName: "Vincent van Gogh", year: 1883, imageName: "Van Gogh/flower_beds_in_holland_1983.1.21"),
        TopShelfPainting(id: "Van Gogh/roses_1991.67.1", title: "Roses", artistName: "Vincent van Gogh", year: 1890, imageName: "Van Gogh/roses_1991.67.1"),
        TopShelfPainting(id: "Van Gogh/seascape_at_port-en-bessin_normandy_1972.9.21", title: "Seascape at Port-en-Bessin", artistName: "Vincent van Gogh", year: 1888, imageName: "Van Gogh/seascape_at_port-en-bessin_normandy_1972.9.21"),
        TopShelfPainting(id: "Van Gogh/still_life_of_oranges_and_lemons_with_blue_gloves_2014.18.13", title: "Still Life of Oranges and Lemons", artistName: "Vincent van Gogh", year: 1889, imageName: "Van Gogh/still_life_of_oranges_and_lemons_with_blue_gloves_2014.18.13"),
        TopShelfPainting(id: "Van Gogh/the_zandmennik_house_1991.217.66", title: "The Zandmennik House", artistName: "Vincent van Gogh", year: 1879, imageName: "Van Gogh/the_zandmennik_house_1991.217.66"),
        TopShelfPainting(id: "Van Gogh/Starry_Night_Over_the_Rhone", title: "Starry Night Over the Rhône", artistName: "Vincent van Gogh", year: 1888, imageName: "Van Gogh/Starry_Night_Over_the_Rhone"),
        // Claude Monet
        TopShelfPainting(id: "Monet/the_japanese_footbridge_1992.9.1", title: "The Japanese Footbridge", artistName: "Claude Monet", year: 1899, imageName: "Monet/the_japanese_footbridge_1992.9.1"),
        TopShelfPainting(id: "Monet/the_artist_s_garden_in_argenteuil_a_corner_of_the_garden_with_dahlias_1991.27.1", title: "The Artist's Garden in Argenteuil", artistName: "Claude Monet", year: 1873, imageName: "Monet/the_artist_s_garden_in_argenteuil_a_corner_of_the_garden_with_dahlias_1991.27.1"),
        TopShelfPainting(id: "Monet/the_bridge_at_argenteuil_1983.1.24", title: "The Bridge at Argenteuil", artistName: "Claude Monet", year: 1874, imageName: "Monet/the_bridge_at_argenteuil_1983.1.24"),
        TopShelfPainting(id: "Monet/waterloo_bridge_london_at_sunset_1983.1.28", title: "Waterloo Bridge, London at Sunset", artistName: "Claude Monet", year: 1904, imageName: "Monet/waterloo_bridge_london_at_sunset_1983.1.28"),
        // Leonardo da Vinci
        TopShelfPainting(id: "Da Vinci/Mona_Lisa", title: "Mona Lisa", artistName: "Leonardo da Vinci", year: 1503, imageName: "Da Vinci/Mona_Lisa"),
        TopShelfPainting(id: "Da Vinci/Last-Supper-wall-painting-restoration-Leonardo-da-1999", title: "The Last Supper", artistName: "Leonardo da Vinci", year: 1498, imageName: "Da Vinci/Last-Supper-wall-painting-restoration-Leonardo-da-1999"),
        TopShelfPainting(id: "Da Vinci/After-restoration-The-Virgin-Child-Jesus-and-Saint-Anne-Leonardo-da-Vinci-Louvre-Paris", title: "The Virgin and Child with Saint Anne", artistName: "Leonardo da Vinci", year: 1510, imageName: "Da Vinci/After-restoration-The-Virgin-Child-Jesus-and-Saint-Anne-Leonardo-da-Vinci-Louvre-Paris"),
        // Johannes Vermeer
        TopShelfPainting(id: "Vermeer/1665_Girl_with_a_Pearl_Earring", title: "Girl with a Pearl Earring", artistName: "Johannes Vermeer", year: 1665, imageName: "Vermeer/1665_Girl_with_a_Pearl_Earring"),
        TopShelfPainting(id: "Vermeer/View_of_Delft", title: "View of Delft", artistName: "Johannes Vermeer", year: 1661, imageName: "Vermeer/View_of_Delft"),
        // Rembrandt van Rijn
        TopShelfPainting(id: "Van Rijn/the_mill_1942.9.62", title: "The Mill", artistName: "Rembrandt van Rijn", year: 1645, imageName: "Van Rijn/the_mill_1942.9.62"),
        TopShelfPainting(id: "Van Rijn/philemon_and_baucis_1942.9.65", title: "Philemon and Baucis", artistName: "Rembrandt van Rijn", year: 1658, imageName: "Van Rijn/philemon_and_baucis_1942.9.65"),
        TopShelfPainting(id: "Van Rijn/the_circumcision_1942.9.60", title: "The Circumcision", artistName: "Rembrandt van Rijn", year: 1661, imageName: "Van Rijn/the_circumcision_1942.9.60"),
        // Gustav Klimt
        TopShelfPainting(id: "Klimt/curled_up_girl_on_bed_1974.83.1", title: "Curled Up Girl on Bed", artistName: "Gustav Klimt", year: 1917, imageName: "Klimt/curled_up_girl_on_bed_1974.83.1"),
        // Edvard Munch
        TopShelfPainting(id: "Munch/Edvard_Munch_-_Telthusbakken_with_Gamle_Aker_Church_(1880)", title: "Telthusbakken with Gamle Aker Church", artistName: "Edvard Munch", year: 1880, imageName: "Munch/Edvard_Munch_-_Telthusbakken_with_Gamle_Aker_Church_(1880)"),
        TopShelfPainting(id: "Munch/Horse_and_Wagon_in_front_of_Farm_Buildings_Munch", title: "Horse and Wagon in front of Farm Buildings", artistName: "Edvard Munch", year: 1882, imageName: "Munch/Horse_and_Wagon_in_front_of_Farm_Buildings_Munch"),
        TopShelfPainting(id: "Munch/Linde_Frieze", title: "Linde Frieze", artistName: "Edvard Munch", year: 1904, imageName: "Munch/Linde_Frieze"),
        // Michelangelo
        TopShelfPainting(id: "Michelangelo/Creación_de_Adán", title: "The Creation of Adam", artistName: "Michelangelo", year: 1512, imageName: "Michelangelo/Creación_de_Adán"),
        // Raphael
        TopShelfPainting(id: "Raphael/School_of_Athens", title: "The School of Athens", artistName: "Raphael", year: 1511, imageName: "Raphael/School_of_Athens"),
        // Edward Hopper
        TopShelfPainting(id: "Hopper/Nighthawks", title: "Nighthawks", artistName: "Edward Hopper", year: 1942, imageName: "Hopper/Nighthawks"),
        // Sandro Botticelli
        TopShelfPainting(id: "Botticelli/Birth_of_Venus", title: "The Birth of Venus", artistName: "Sandro Botticelli", year: 1485, imageName: "Botticelli/Birth_of_Venus"),
        // Katsushika Hokusai
        TopShelfPainting(id: "Hokusai/Great_Wave", title: "The Great Wave off Kanagawa", artistName: "Katsushika Hokusai", year: 1831, imageName: "Hokusai/Great_Wave")
    ]

    // Director's Cut - explicit order matching PaintingData.swift exactly
    // Order: Van Gogh artists paintings, then Monet, then Raphael, Hopper, Botticelli, Hokusai
    // This matches the order from: artists.flatMap { $0.paintings }.filter { $0.forceFullScreen }
    private let directorsCut: [TopShelfPainting] = [
        TopShelfPainting(id: "Van Gogh/Starry_Night_Over_the_Rhone", title: "Starry Night Over the Rhône", artistName: "Vincent van Gogh", year: 1888, imageName: "Van Gogh/Starry_Night_Over_the_Rhone"),
        TopShelfPainting(id: "Monet/the_bridge_at_argenteuil_1983.1.24", title: "The Bridge at Argenteuil", artistName: "Claude Monet", year: 1874, imageName: "Monet/the_bridge_at_argenteuil_1983.1.24"),
        TopShelfPainting(id: "Raphael/School_of_Athens", title: "The School of Athens", artistName: "Raphael", year: 1511, imageName: "Raphael/School_of_Athens"),
        TopShelfPainting(id: "Hopper/Nighthawks", title: "Nighthawks", artistName: "Edward Hopper", year: 1942, imageName: "Hopper/Nighthawks"),
        TopShelfPainting(id: "Botticelli/Birth_of_Venus", title: "The Birth of Venus", artistName: "Sandro Botticelli", year: 1485, imageName: "Botticelli/Birth_of_Venus"),
        TopShelfPainting(id: "Hokusai/Great_Wave", title: "The Great Wave off Kanagawa", artistName: "Katsushika Hokusai", year: 1831, imageName: "Hokusai/Great_Wave")
    ]

    /// Returns the painting of the day based on the current date (only from 16:9 paintings)
    /// Uses the same algorithm as PaintingData.paintingOfTheDay()
    private func paintingOfTheDay() -> TopShelfPainting {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % directorsCut.count
        return directorsCut[index]
    }

    override func loadTopShelfContent() async -> TVTopShelfContent? {
        // Create sectioned content with Painting of the Day and Recent
        let featuredPainting = paintingOfTheDay()

        // Featured section - Painting of the Day
        let featuredItem = TVTopShelfSectionedItem(identifier: featuredPainting.id)
        featuredItem.title = featuredPainting.title
        featuredItem.setImageURL(imageURL(for: featuredPainting.imageName), for: .screenScale1x)
        featuredItem.setImageURL(imageURL(for: featuredPainting.imageName), for: .screenScale2x)
        featuredItem.displayAction = TVTopShelfAction(url: URL(string: "galleryglow://painting/\(featuredPainting.id)")!)
        featuredItem.playAction = featuredItem.displayAction

        let featuredSection = TVTopShelfItemCollection(items: [featuredItem])
        featuredSection.title = "Painting of the Day"

        // Gallery section - All paintings except the featured one
        var galleryItems: [TVTopShelfSectionedItem] = []
        for painting in allPaintings where painting.id != featuredPainting.id {
            let item = TVTopShelfSectionedItem(identifier: painting.id)
            item.title = painting.title
            item.setImageURL(imageURL(for: painting.imageName), for: .screenScale1x)
            item.setImageURL(imageURL(for: painting.imageName), for: .screenScale2x)
            item.displayAction = TVTopShelfAction(url: URL(string: "galleryglow://painting/\(painting.id)")!)
            item.playAction = item.displayAction
            galleryItems.append(item)
        }

        let gallerySection = TVTopShelfItemCollection(items: galleryItems)
        gallerySection.title = "Gallery"

        return TVTopShelfSectionedContent(sections: [featuredSection, gallerySection])
    }

    private func imageURL(for imageName: String) -> URL? {
        // Return URL from the app bundle's assets
        // For Top Shelf, images should be in the shared asset catalog
        return Bundle.main.url(forResource: imageName, withExtension: "png")
            ?? Bundle.main.url(forResource: imageName, withExtension: "jpg")
    }
}
