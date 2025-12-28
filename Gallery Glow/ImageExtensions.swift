//
//  ImageExtensions.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

/// A view that displays a painting image with a placeholder fallback
struct PaintingImage: View {
    let imageName: String
    let contentMode: ContentMode
    
    init(_ imageName: String, contentMode: ContentMode = .fill) {
        self.imageName = imageName
        self.contentMode = contentMode
    }
    
    private var loadedImage: UIImage? {
        // Try loading from asset catalog first
        if let image = UIImage(named: imageName) {
            return image
        }
        return nil
    }
    
    var body: some View {
        if let uiImage = loadedImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            // Placeholder for missing images
            ZStack {
                Color(white: 0.15)
                
                VStack(spacing: 12) {
                    Image(systemName: "photo.artframe")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var displayName: String {
        // Extract just the filename from path like "Van Gogh/self-portrait_1998.74.5"
        let filename = imageName.components(separatedBy: "/").last ?? imageName
        // Remove catalog numbers and clean up
        let cleaned = filename
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        // Remove trailing catalog numbers like "1998.74.5"
        let parts = cleaned.components(separatedBy: " ")
        let filtered = parts.filter { !$0.contains(".") || $0.count > 12 }
        return filtered.joined(separator: " ").capitalized
    }
}
