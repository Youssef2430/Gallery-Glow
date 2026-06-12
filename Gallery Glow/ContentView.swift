//
//  ContentView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

struct ContentView: View {
    private let data = PaintingData.shared
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var selectedPainting: Painting?
    @State private var selectedGradient: GradientPalette?
    @State private var pendingPainting: Painting?
    @State private var pendingGradient: GradientPalette?
    @State private var showPaywall = false

    // Cache painting of the day — deterministic per day, no need to recompute on every body evaluation
    @State private var paintingOfTheDay: Painting = PaintingData.shared.paintingOfTheDay()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 60) {
                    if !purchaseManager.isUnlocked {
                        PurchaseBanner(
                            price: purchaseManager.lifetimeDisplayPrice,
                            isLoading: purchaseManager.isLoadingProducts
                        ) {
                            showPaywall = true
                        }
                        .padding(.horizontal, 64)
                    }

                    // Painting of the Day
                    PaintingOfTheDaySection(painting: paintingOfTheDay) { painting in
                        requestPainting(painting)
                    }

                    // Director's Cut Section
                    DirectorsCutSection(paintings: data.directorsCut) { painting in
                        requestPainting(painting)
                    }

                    // Artists Section
                    ArtistsSection(artists: data.artists)

                    // Gradients Section
                    GradientsSection { palette in
                        requestGradient(palette)
                    }
                }
                .padding(.vertical, 48)
            }
            .navigationTitle("Gallery Glow")
            .fullScreenCover(item: $selectedPainting) { painting in
                ScreensaverView(painting: painting)
            }
            .fullScreenCover(item: $selectedGradient) { palette in
                GradientScreensaverView(palette: palette)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView {
                    presentPendingSelectionIfUnlocked()
                }
                .environmentObject(purchaseManager)
            }
            .onChange(of: purchaseManager.isUnlocked) { _, unlocked in
                guard unlocked else { return }
                presentPendingSelectionIfUnlocked()
            }
        }
    }

    private func requestPainting(_ painting: Painting) {
        guard purchaseManager.isUnlocked else {
            pendingPainting = painting
            pendingGradient = nil
            showPaywall = true
            return
        }

        presentPainting(painting)
    }

    private func requestGradient(_ palette: GradientPalette) {
        guard purchaseManager.isUnlocked else {
            pendingPainting = nil
            pendingGradient = palette
            showPaywall = true
            return
        }

        presentGradient(palette)
    }

    private func presentPendingSelectionIfUnlocked() {
        guard purchaseManager.isUnlocked else { return }

        if let painting = pendingPainting {
            pendingPainting = nil
            presentPainting(painting)
        } else if let palette = pendingGradient {
            pendingGradient = nil
            presentGradient(palette)
        }

        showPaywall = false
    }

    private func presentPainting(_ painting: Painting) {
        RecentlyUsedManager.shared.addPainting(painting)
        selectedPainting = painting
    }

    private func presentGradient(_ palette: GradientPalette) {
        RecentlyUsedManager.shared.addGradient(
            palette: palette.rawValue,
            description: palette.displayDescription
        )
        selectedGradient = palette
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

// MARK: - Director's Cut Section

struct DirectorsCutSection: View {
    let paintings: [Painting]
    let onSelect: (Painting) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 40)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Director's Cut")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 64)

            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(paintings) { painting in
                    Button(action: { onSelect(painting) }) {
                        DirectorsCutCard(painting: painting)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct DirectorsCutCard: View {
    let painting: Painting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaintingImage(painting.imageName)
                .aspectRatio(16/9, contentMode: .fill)
                .frame(height: 225)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(painting.title)
                    .font(.headline)

                Text("\(painting.artistName) · \(String(painting.year))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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

// MARK: - Gradients Section

struct GradientsSection: View {
    let onSelect: (GradientPalette) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Gradients")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 64)

            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(GradientPalette.allCases) { palette in
                    Button(action: { onSelect(palette) }) {
                        GradientCard(palette: palette)
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(.horizontal, 64)
        }
    }
}

struct GradientCard: View {
    let palette: GradientPalette

    private var colors: [Color] {
        palette.previewColors
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient preview - fluid blob style
            GeometryReader { geo in
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Blob 1 - top left
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [colors[0], colors[0].opacity(0.5), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.5
                            )
                        )
                        .frame(width: geo.size.width * 0.9)
                        .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.15)

                    // Blob 2 - bottom right
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [colors.count > 1 ? colors[1] : colors[0], colors.last?.opacity(0.5) ?? .clear, .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.5
                            )
                        )
                        .frame(width: geo.size.width * 0.8)
                        .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.25)

                    // Blob 3 - center
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [colors.count > 2 ? colors[2] : colors[0], .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geo.size.width * 0.4
                            )
                        )
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: geo.size.width * 0.1, y: geo.size.height * 0.1)
                }
            }
            .frame(height: 200)
            .blur(radius: 12)
            // Rasterize the blurred blobs once instead of re-evaluating the
            // gradient + blur filter chain every frame the card is on screen
            .drawingGroup()
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(palette.rawValue)
                    .font(.headline)

                Text(palette.displayDescription)
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
        .environmentObject(PurchaseManager(startsTransactionListener: false))
}
