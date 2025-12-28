//
//  ContentView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

struct ContentView: View {
    private let data = PaintingData.shared
    @State private var selectedPainting: Painting?
    
    private let artistColumns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 60) {
                    // Painting of the Day
                    PaintingOfTheDaySection(painting: data.paintingOfTheDay()) { painting in
                        selectedPainting = painting
                    }
                    
                    // Artists Section
                    ArtistsSection(artists: data.artists)
                }
                .padding(.vertical, 48)
            }
            .navigationTitle("Gallery Glow")
            .fullScreenCover(item: $selectedPainting) { painting in
                ScreensaverView(painting: painting)
            }
        }
    }
}

// MARK: - Painting of the Day

struct PaintingOfTheDaySection: View {
    let painting: Painting
    let onSelect: (Painting) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Painting of the Day")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 64)
            
            Button(action: { onSelect(painting) }) {
                ZStack(alignment: .bottomLeading) {
                    PaintingImage(painting.imageName)
                        .frame(height: 500)
                        .clipped()
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 200)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(painting.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(painting.artistName) · \(String(painting.year))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Text(painting.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                    .padding(32)
                }
                .cornerRadius(20)
            }
            .buttonStyle(.card)
            .focused($isFocused)
            .padding(.horizontal, 64)
        }
    }
}

// MARK: - Artists Section

struct ArtistsSection: View {
    let artists: [Artist]
    
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Artists")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 64)
            
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(artists) { artist in
                    NavigationLink(destination: ArtistView(artist: artist)) {
                        ArtistCard(artist: artist)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct ArtistCard: View {
    let artist: Artist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Show first painting as preview
            if let firstPainting = artist.paintings.first {
                PaintingImage(firstPainting.imageName)
                    .frame(height: 200)
                    .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                
                Text("\(artist.nationality) · \(artist.paintings.count) works")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    ContentView()
}
