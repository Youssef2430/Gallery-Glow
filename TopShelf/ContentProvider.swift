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
    
    // Sample paintings for Top Shelf display
    private let paintings: [TopShelfPainting] = [
        TopShelfPainting(id: "starry_night", title: "Starry Night", artistName: "Vincent van Gogh", year: 1889, imageName: "starry_night"),
        TopShelfPainting(id: "water_lilies", title: "Water Lilies", artistName: "Claude Monet", year: 1906, imageName: "water_lilies"),
        TopShelfPainting(id: "mona_lisa", title: "Mona Lisa", artistName: "Leonardo da Vinci", year: 1503, imageName: "mona_lisa"),
        TopShelfPainting(id: "pearl_earring", title: "Girl with a Pearl Earring", artistName: "Johannes Vermeer", year: 1665, imageName: "pearl_earring"),
        TopShelfPainting(id: "the_kiss", title: "The Kiss", artistName: "Gustav Klimt", year: 1908, imageName: "the_kiss"),
        TopShelfPainting(id: "the_scream", title: "The Scream", artistName: "Edvard Munch", year: 1893, imageName: "the_scream"),
        TopShelfPainting(id: "persistence_memory", title: "The Persistence of Memory", artistName: "Salvador Dalí", year: 1931, imageName: "persistence_memory"),
        TopShelfPainting(id: "night_watch", title: "The Night Watch", artistName: "Rembrandt van Rijn", year: 1642, imageName: "night_watch")
    ]
    
    /// Returns the painting of the day based on the current date
    private func paintingOfTheDay() -> TopShelfPainting {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % paintings.count
        return paintings[index]
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
        
        // Gallery section - Recent/Popular paintings
        var galleryItems: [TVTopShelfSectionedItem] = []
        for painting in paintings where painting.id != featuredPainting.id {
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
