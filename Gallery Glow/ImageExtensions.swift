//
//  ImageExtensions.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import ImageIO

// MARK: - Image Downsampling

/// Decode an image at its display size instead of full resolution.
///
/// The target is computed from the frame the image will occupy *and* the content
/// mode: with `.fill`, an image whose aspect ratio differs from the frame must be
/// decoded large enough that its short side covers the frame — sizing by the long
/// side alone produces an undersized bitmap that gets upscaled on screen (blurry
/// thumbnails). The decoded size is capped at the image's native resolution.
func downsampleImage(
    named imageName: String,
    to pointSize: CGSize,
    contentMode: ContentMode = .fill,
    scale: CGFloat = 1.0
) -> UIImage? {
    let targetPixelSize = CGSize(
        width: pointSize.width * scale,
        height: pointSize.height * scale
    )

    if let url = imageURL(for: imageName) {
        return downsampleFromFile(url: url, targetPixelSize: targetPixelSize, contentMode: contentMode)
    }
    return downsampleFromAssetCatalog(named: imageName, targetPixelSize: targetPixelSize, contentMode: contentMode)
}

/// How much the image must be scaled so it covers (`.fill`) or fits (`.fit`) the
/// target. Never returns more than 1 — decoding above native resolution wastes
/// memory without adding detail.
private func downsampleScaleFactor(
    imagePixelSize: CGSize,
    targetPixelSize: CGSize,
    contentMode: ContentMode
) -> CGFloat {
    guard imagePixelSize.width > 0, imagePixelSize.height > 0,
          targetPixelSize.width > 0, targetPixelSize.height > 0 else {
        return 1
    }
    let widthRatio = targetPixelSize.width / imagePixelSize.width
    let heightRatio = targetPixelSize.height / imagePixelSize.height
    let factor = contentMode == .fill
        ? max(widthRatio, heightRatio)
        : min(widthRatio, heightRatio)
    return min(factor, 1)
}

/// Get the file URL for an image bundled as a loose resource (not asset catalog)
private func imageURL(for imageName: String) -> URL? {
    for ext in ["jpg", "jpeg", "png", "heic"] {
        if let url = Bundle.main.url(forResource: imageName, withExtension: ext) {
            return url
        }
    }
    return nil
}

/// ImageIO downsampling for file-backed images: decodes directly at thumbnail
/// size without ever materializing the full-resolution bitmap.
private func downsampleFromFile(url: URL, targetPixelSize: CGSize, contentMode: ContentMode) -> UIImage? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }

    var maxPixelSize = max(targetPixelSize.width, targetPixelSize.height)
    if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
       let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
       let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
        let factor = downsampleScaleFactor(
            imagePixelSize: CGSize(width: width, height: height),
            targetPixelSize: targetPixelSize,
            contentMode: contentMode
        )
        maxPixelSize = (max(width, height) * factor).rounded(.up)
    }

    let options: [CFString: Any] = [
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
    ]

    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}

/// Downsampling for asset catalog images, which have no file URL.
private func downsampleFromAssetCatalog(named imageName: String, targetPixelSize: CGSize, contentMode: ContentMode) -> UIImage? {
    guard let original = UIImage(named: imageName) else {
        return nil
    }

    let imagePixelSize = CGSize(
        width: original.size.width * original.scale,
        height: original.size.height * original.scale
    )
    let factor = downsampleScaleFactor(
        imagePixelSize: imagePixelSize,
        targetPixelSize: targetPixelSize,
        contentMode: contentMode
    )

    // Already at or below target size: just force-decode off the main thread so
    // display doesn't hitch on first draw.
    if factor >= 1 {
        return original.preparingForDisplay() ?? original
    }

    let thumbnailSize = CGSize(
        width: (imagePixelSize.width * factor).rounded(),
        height: (imagePixelSize.height * factor).rounded()
    )

    // preparingThumbnail decodes via ImageIO and returns a ready-to-display
    // bitmap without a full-resolution intermediate.
    if let thumbnail = original.preparingThumbnail(of: thumbnailSize) {
        return thumbnail
    }

    // Fallback: explicit redraw at 1x (the default renderer scale would multiply
    // the pixel count by the screen scale).
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: thumbnailSize, format: format)
    return renderer.image { context in
        context.cgContext.interpolationQuality = .high
        original.draw(in: CGRect(origin: .zero, size: thumbnailSize))
    }
}

// MARK: - Image Cache

/// Simple image cache to avoid repeated downsampling.
/// NSCache is thread-safe — no additional synchronization needed.
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        // Use pixel dimensions (not point dimensions) for accurate memory cost
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let cost = Int(pixelWidth * pixelHeight * 4) // 4 bytes per pixel (RGBA)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func cacheKey(for imageName: String, size: CGSize, contentMode: ContentMode) -> String {
        "\(imageName)_\(Int(size.width))x\(Int(size.height))_\(contentMode == .fill ? "fill" : "fit")"
    }
}

// MARK: - PaintingImage View

/// A view that displays a painting image with a placeholder fallback.
/// Uses downsampling to efficiently load large images at the display size.
struct PaintingImage: View {
    let imageName: String
    let contentMode: ContentMode
    /// Optional explicit decode size (in points). Use when the on-screen frame is
    /// much larger than the detail actually needed — e.g. a heavily blurred
    /// backdrop can decode at a fraction of full screen size.
    let targetSize: CGSize?

    @Environment(\.displayScale) private var displayScale

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?
    @State private var loadedForSize: CGSize = .zero

    init(_ imageName: String, contentMode: ContentMode = .fill, targetSize: CGSize? = nil) {
        self.imageName = imageName
        self.contentMode = contentMode
        self.targetSize = targetSize
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let uiImage = loadedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    // Placeholder while loading or for missing images
                    placeholderView
                }
            }
            .onAppear {
                loadImageIfNeeded(for: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                // Only reload if size changed significantly (>10% in either dimension)
                guard loadedForSize.width > 0, loadedForSize.height > 0 else {
                    loadImageIfNeeded(for: newSize)
                    return
                }
                let widthDelta = abs(newSize.width - loadedForSize.width) / loadedForSize.width
                let heightDelta = abs(newSize.height - loadedForSize.height) / loadedForSize.height
                if widthDelta > 0.1 || heightDelta > 0.1 {
                    loadImageIfNeeded(for: newSize)
                }
            }
            .onDisappear {
                loadTask?.cancel()
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color(white: 0.15)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
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

    private func loadImageIfNeeded(for size: CGSize) {
        let resolvedSize = targetSize ?? size
        let loadSize = CGSize(
            width: resolvedSize.width > 0 ? resolvedSize.width : 800,
            height: resolvedSize.height > 0 ? resolvedSize.height : 600
        )

        let cacheKey = ImageCache.shared.cacheKey(for: imageName, size: loadSize, contentMode: contentMode)

        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            self.loadedImage = cachedImage
            self.loadedForSize = loadSize
            self.isLoading = false
            return
        }

        // Cancel any previous in-flight load
        loadTask?.cancel()

        // Load asynchronously with structured concurrency
        isLoading = true
        let name = imageName
        let mode = contentMode
        let scale = displayScale
        loadTask = Task {
            let image = await Task.detached(priority: .userInitiated) {
                downsampleImage(named: name, to: loadSize, contentMode: mode, scale: scale)
            }.value

            guard !Task.isCancelled else { return }

            await MainActor.run {
                if let image = image {
                    ImageCache.shared.setImage(image, forKey: cacheKey)
                    withAnimation(.easeIn(duration: 0.15)) {
                        self.loadedImage = image
                    }
                    self.loadedForSize = loadSize
                }
                self.isLoading = false
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

// MARK: - Aspect Ratio Helper

/// Get the aspect ratio of an image without loading the full image
func getImageAspectRatio(for imageName: String) -> CGFloat? {
    // Try to get image properties without loading full image
    if let url = imageURL(for: imageName),
       let source = CGImageSourceCreateWithURL(url as CFURL, nil),
       let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
       let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
       let height = properties[kCGImagePropertyPixelHeight] as? CGFloat,
       height > 0 {
        return width / height
    }

    // Asset catalog: UIImage(named:) reads dimensions from metadata without
    // decoding pixels, so this stays cheap.
    if let image = UIImage(named: imageName) {
        return image.size.width / image.size.height
    }

    return nil
}
