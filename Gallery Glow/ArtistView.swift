import SwiftUI

struct ArtistView: View {
    let artist: Artist
    let onSelect: (Painting) -> Void
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 480, maximum: 760), spacing: 48)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 38) {
                HStack {
                    GalleryEyebrow("The artists / \(artist.nationality)")
                    Spacer()
                    Text("GALLERY GLOW").font(GalleryTheme.wordmark(30)).tracking(-0.6)
                }
                HStack(alignment: .bottom, spacing: 60) {
                    Text(artist.name).font(GalleryTheme.display(86)).tracking(-3)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {
                        Text(artist.lifespan).font(GalleryTheme.display(30))
                        GalleryEyebrow("\(artist.paintings.count) \(artist.paintings.count == 1 ? "work" : "works") in the collection")
                    }
                    .padding(.bottom, 14)
                }
                if artist.paintings.count == 1, let painting = artist.paintings.first {
                    PaintingCard(painting: painting, featured: true) { onSelect(painting) }
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 48) {
                        ForEach(artist.paintings) { painting in
                            PaintingCard(painting: painting) { onSelect(painting) }
                        }
                    }
                }
                Button { dismiss() } label: {
                    Label("Back to the collection", systemImage: "arrow.left")
                        .font(.system(size: 21, weight: .medium))
                }
                .buttonStyle(GalleryButtonStyle())
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 35)
        }
        .foregroundStyle(GalleryTheme.ink)
        .background(GalleryTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onExitCommand { dismiss() }
    }
}

struct PaintingCard: View {
    let painting: Painting
    var featured = false
    let onSelect: () -> Void
    @FocusState private var isFocused: Bool
    var body: some View {
        Button(action: onSelect) {
            Group {
                if featured {
                    HStack(alignment: .center, spacing: 60) {
                        artwork.frame(maxWidth: .infinity)
                        caption.frame(width: 440)
                    }
                    .frame(height: 490)
                } else {
                    VStack(alignment: .leading, spacing: 28) {
                        artwork.frame(height: 340)
                        caption
                    }
                    .padding(20)
                }
            }
            .foregroundStyle(GalleryTheme.ink)
        }
        .buttonStyle(GalleryArtworkButtonStyle())
        .focused($isFocused)
        .defaultFocus($isFocused, true)
        .accessibilityIdentifier("artist-painting-\(painting.imageName)")
        .accessibilityLabel("\(painting.title), \(painting.year)")
        .accessibilityHint("Open painting full screen")
    }

    private var artwork: some View {
        FramedPainting(painting: painting, inset: 24, isFocused: isFocused)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(String(painting.year))
                .font(.system(size: 20, weight: .medium))
                .padding(.horizontal, 19).padding(.vertical, 10)
                .background(GalleryTheme.surface, in: Capsule())
            Text(painting.title).font(GalleryTheme.display(featured ? 48 : 30))
                .tracking(-1).lineLimit(3)
            Text(painting.description).font(.system(size: 23)).lineSpacing(6)
                .foregroundStyle(GalleryTheme.secondary).lineLimit(5)
            HStack {
                Text("View artwork").font(.system(size: 22, weight: .semibold))
                Spacer()
                GalleryArrow(filled: true)
            }
            .padding(.leading, 24).padding(.trailing, 8).padding(.vertical, 8)
            .background(GalleryTheme.surface, in: Capsule())
        }
    }
}
