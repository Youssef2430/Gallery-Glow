//
//  ContentProvider.swift
//  Gallery Shelf
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Foundation
import TVServices

class ContentProvider: TVTopShelfContentProvider {

    // All available paintings
    private let allPaintings = [
        ("Van Gogh/self-portrait_1998.74.5", "Self-Portrait", "Vincent van Gogh"),
        ("Van Gogh/farmhouse_in_provence_1970.17.34", "Farmhouse in Provence", "Vincent van Gogh"),
        ("Van Gogh/roses_1991.67.1", "Roses", "Vincent van Gogh"),
        ("Monet/the_japanese_footbridge_1992.9.1", "The Japanese Footbridge", "Claude Monet"),
        ("Monet/the_bridge_at_argenteuil_1983.1.24", "The Bridge at Argenteuil", "Claude Monet"),
        ("Da Vinci/Mona_Lisa", "Mona Lisa", "Leonardo da Vinci"),
        ("Da Vinci/Last-Supper-wall-painting-restoration-Leonardo-da-1999", "The Last Supper", "Leonardo da Vinci"),
        ("Vermeer/1665_Girl_with_a_Pearl_Earring", "Girl with a Pearl Earring", "Johannes Vermeer"),
        ("Vermeer/View_of_Delft", "View of Delft", "Johannes Vermeer"),
        ("Michelangelo/Creación_de_Adán", "The Creation of Adam", "Michelangelo"),
        ("Van Rijn/the_mill_1942.9.62", "The Mill", "Rembrandt van Rijn"),
        ("Klimt/curled_up_girl_on_bed_1974.83.1", "Curled Up Girl on Bed", "Gustav Klimt")
    ]
    
    /// Returns painting of the day based on current date
    private func paintingOfTheDay() -> (String, String, String) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % allPaintings.count
        return allPaintings[index]
    }
    
    override func loadTopShelfContent() async -> TVTopShelfContent? {
        // Painting of the Day section
        let potd = paintingOfTheDay()
        let featuredItem = TVTopShelfSectionedItem(identifier: "potd_\(potd.0)")
        featuredItem.title = potd.1
        
        if let imageURL = imageURL(for: potd.0) {
            featuredItem.setImageURL(imageURL, for: .screenScale1x)
            featuredItem.setImageURL(imageURL, for: .screenScale2x)
        }
        
        if let url = URL(string: "galleryglow://painting/\(potd.0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? potd.0)") {
            featuredItem.displayAction = TVTopShelfAction(url: url)
            featuredItem.playAction = featuredItem.displayAction
        }
        
        let featuredSection = TVTopShelfItemCollection(items: [featuredItem])
        featuredSection.title = "Painting of the Day"
        
        // Gallery section - all paintings except the featured one
        var galleryItems: [TVTopShelfSectionedItem] = []
        for (imageName, title, _) in allPaintings where imageName != potd.0 {
            let item = TVTopShelfSectionedItem(identifier: imageName)
            item.title = title
            
            if let imageURL = imageURL(for: imageName) {
                item.setImageURL(imageURL, for: .screenScale1x)
                item.setImageURL(imageURL, for: .screenScale2x)
            }
            
            if let url = URL(string: "galleryglow://painting/\(imageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imageName)") {
                item.displayAction = TVTopShelfAction(url: url)
                item.playAction = item.displayAction
            }
            
            galleryItems.append(item)
        }
        
        let gallerySection = TVTopShelfItemCollection(items: galleryItems)
        gallerySection.title = "Gallery"
        
        return TVTopShelfSectionedContent(sections: [featuredSection, gallerySection])
    }
    
    private func imageURL(for imageName: String) -> URL? {
        // IMPORTANT: Top Shelf extensions have tight memory budgets.
        // Avoid decoding/re-encoding large images at runtime (e.g. UIImage(named:) + jpegData()),
        // which can easily trigger jetsam on device.
        //
        // Instead, ship small JPEGs as regular bundle resources under Gallery Shelf/TopShelfImages
        // and return file URLs directly.
        let resourceName = imageName.replacingOccurrences(of: "/", with: "_")

        // Depending on how the files are added to the Xcode project, resources may be flattened into the
        // bundle root (Copy Bundle Resources) or preserved as a folder reference. Try both.
        return Bundle.main.url(forResource: resourceName, withExtension: "jpg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpeg", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png", subdirectory: "TopShelfImages")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpg")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "jpeg")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "png")
    }
}
