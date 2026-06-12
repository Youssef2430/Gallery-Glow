//
//  ArtistView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

struct ArtistView: View {
    let artist: Artist
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var selectedPainting: Painting?
    @State private var pendingPainting: Painting?
    @State private var showPaywall = false

    private let columns = [
        GridItem(.adaptive(minimum: 400, maximum: 500), spacing: 48)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Artist header
                VStack(alignment: .leading, spacing: 8) {
                    Text(artist.nationality)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(2)

                    Text(artist.lifespan)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 64)
                .padding(.top, 20)

                // Paintings grid
                LazyVGrid(columns: columns, spacing: 48) {
                    ForEach(artist.paintings) { painting in
                        PaintingCard(painting: painting) {
                            requestPainting(painting)
                        }
                    }
                }
                .padding(.horizontal, 64)
                .padding(.bottom, 64)
            }
        }
        .navigationTitle(artist.name)
        .fullScreenCover(item: $selectedPainting) { painting in
            ScreensaverView(painting: painting)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                presentPendingPaintingIfUnlocked()
            }
            .environmentObject(purchaseManager)
        }
        .onChange(of: purchaseManager.isUnlocked) { _, unlocked in
            guard unlocked else { return }
            presentPendingPaintingIfUnlocked()
        }
    }

    private func requestPainting(_ painting: Painting) {
        guard purchaseManager.isUnlocked else {
            pendingPainting = painting
            showPaywall = true
            return
        }

        presentPainting(painting)
    }

    private func presentPendingPaintingIfUnlocked() {
        guard purchaseManager.isUnlocked, let painting = pendingPainting else { return }
        pendingPainting = nil
        showPaywall = false
        presentPainting(painting)
    }

    private func presentPainting(_ painting: Painting) {
        RecentlyUsedManager.shared.addPainting(painting)
        selectedPainting = painting
    }
}

struct PaintingCard: View {
    let painting: Painting
    let onSelect: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                PaintingImage(painting.imageName)
                    .frame(height: 280)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(painting.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(String(painting.year))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}

#Preview {
    NavigationStack {
        ArtistView(artist: PaintingData.shared.artists[0])
    }
    .environmentObject(PurchaseManager(startsTransactionListener: false))
}

#Preview("PaintingCard") {
    PaintingCard(painting: PaintingData.shared.allPaintings[0]) {}
}
