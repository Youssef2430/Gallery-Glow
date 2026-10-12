import SwiftUI

enum GalleryTheme {
    // Asset variants resolve against the current system appearance, including
    // changes while the gallery or checkout is already on screen.
    static let paper = Color("GalleryBackground")
    static let ink = Color("GalleryForeground")
    static let secondary = Color("GallerySecondary")
    static let accent = Color(red: 0.94, green: 0.73, blue: 0.17)
    static let onAccent = Color(red: 0.075, green: 0.075, blue: 0.067)
    static let mat = Color("GalleryMount")
    static let surface = Color("GallerySurface")
    static let rule = ink.opacity(0.14)
    static func display(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }
    static func wordmark(_ size: CGFloat) -> Font { .custom("HelveticaNeue-Bold", size: size) }
    static func label(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .medium) }
}

struct GalleryBrandIcon: View {
    var size: CGFloat = 42
    var body: some View {
        Image("GalleryBrandIcon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct GalleryRule: View {
    var body: some View { Rectangle().fill(GalleryTheme.rule).frame(height: 1) }
}

struct GalleryEyebrow: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(GalleryTheme.label(16)).tracking(2)
            .foregroundStyle(GalleryTheme.secondary)
    }
}

struct GallerySectionHeading: View {
    let number: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 22) {
                Text(title).font(GalleryTheme.display(42))
                Spacer()
                GalleryEyebrow(detail)
            }
        }
        .foregroundStyle(GalleryTheme.ink)
        .padding(.horizontal, 64)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A rounded lacquered frame, an inset mount, and a soft wall shadow.
/// The image remains fitted inside the mount; the frame never crops the work.
struct GalleryFrame<Content: View>: View {
    var inset: CGFloat = 20
    @ViewBuilder let content: Content
    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(inset)
            .background(GalleryTheme.mat)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(.black.opacity(0.16), lineWidth: 1))
            .padding(9)
            .background(LinearGradient(colors: [Color(white: 0.25), Color(white: 0.075), Color(white: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 13)
    }
}

struct GalleryArrow: View {
    var filled = false
    var body: some View {
        Image(systemName: "arrow.up.right")
            .font(.system(size: 22, weight: .medium))
            .frame(width: 56, height: 56)
            .foregroundStyle(filled ? GalleryTheme.onAccent : GalleryTheme.ink)
            .background(filled ? GalleryTheme.accent : GalleryTheme.paper, in: Circle())
    }
}

struct FramedPainting: View {
    let painting: Painting
    var inset: CGFloat = 22
    var isFocused = false
    var body: some View {
        GeometryReader { geometry in
            let ratio = getImageAspectRatio(for: painting.imageName) ?? 1.6
            let mount = (inset + 9) * 2
            let imageWidth = max(1, min(geometry.size.width - mount, (geometry.size.height - mount) * ratio))
            GalleryFrame(inset: inset) {
                PaintingImage(painting.imageName, contentMode: .fit)
                    .frame(width: imageWidth, height: imageWidth / ratio)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 39, style: .continuous)
                    .strokeBorder(isFocused ? GalleryTheme.accent : .clear, lineWidth: 4)
                    .padding(-7)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// Frame focus is drawn around the artwork itself, without tvOS's default
/// lifted white background around the entire image-and-caption layout.
struct GalleryArtworkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

/// A restrained focus treatment that remains obvious from across the room.
struct GalleryButtonStyle: ButtonStyle {
    var prominent = false
    var card = false
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, prominent: prominent, card: card)
    }
    private struct Surface: View {
        let configuration: Configuration
        let prominent: Bool
        let card: Bool
        @Environment(\.isFocused) private var isFocused
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            configuration.label
                .foregroundStyle(prominent ? GalleryTheme.onAccent : GalleryTheme.ink)
                .padding(.horizontal, card ? 0 : 26)
                .padding(.vertical, card ? 0 : 19)
                .background(prominent ? GalleryTheme.accent : (card ? Color.clear : GalleryTheme.surface))
                .clipShape(RoundedRectangle(cornerRadius: card ? 34 : 30, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: card ? 40 : 36, style: .continuous)
                        .strokeBorder(isFocused ? GalleryTheme.ink : Color.clear, lineWidth: 3)
                        .padding(-7)
                }
                .shadow(color: .black.opacity(isFocused ? 0.12 : 0), radius: 18, y: 8)
                .scaleEffect(configuration.isPressed ? 0.99 : (isFocused ? 1.018 : 1))
                .opacity(isEnabled ? 1 : 0.55)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isFocused)
        }
    }
}
