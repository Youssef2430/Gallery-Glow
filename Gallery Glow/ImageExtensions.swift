//
//  ImageExtensions.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import ImageIO

// MARK: - Image Downsampling

/// Efficiently downsample an image to a target size without loading the full resolution into memory
func downsampleImage(named imageName: String, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
    // Try to get the image URL from the asset catalog
    guard let url = imageURL(for: imageName) else {
        // Fallback: try loading from asset catalog directly with downsampling
        return downsampleFromAssetCatalog(named: imageName, to: pointSize, scale: scale)
    }

    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

    let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ]

    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
        return nil
    }

    return UIImage(cgImage: cgImage)
}

/// Get the file URL for an image in the asset catalog
private func imageURL(for imageName: String) -> URL? {
    // For asset catalog images, we need to find the actual file
    // Check common locations
    if let url = Bundle.main.url(forResource: imageName, withExtension: "jpg") {
        return url
    }
    if let url = Bundle.main.url(forResource: imageName, withExtension: "jpeg") {
        return url
    }
    if let url = Bundle.main.url(forResource: imageName, withExtension: "png") {
        return url
    }
    if let url = Bundle.main.url(forResource: imageName, withExtension: "heic") {
        return url
    }
    return nil
}

/// Fallback downsampling for asset catalog images
private func downsampleFromAssetCatalog(named imageName: String, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    // For asset catalog images, we load with UIImage but render at target size
    guard let originalImage = UIImage(named: imageName) else {
        return nil
    }

    let maxDimension = max(pointSize.width, pointSize.height) * scale
    let originalMaxDimension = max(originalImage.size.width, originalImage.size.height)

    // If the image is already smaller than target, return as-is
    if originalMaxDimension <= maxDimension {
        return originalImage
    }

    // Calculate target size maintaining aspect ratio
    let scaleFactor = maxDimension / originalMaxDimension
    let targetSize = CGSize(
        width: originalImage.size.width * scaleFactor,
        height: originalImage.size.height * scaleFactor
    )

    // Render at target size using UIGraphicsImageRenderer (memory efficient)
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
        originalImage.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    return resizedImage
}

// MARK: - Image Cache

/// Simple image cache to avoid repeated downsampling
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.galleryglow.imagecache", attributes: .concurrent)

    private init() {
        // Configure cache limits
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }

    func image(forKey key: String) -> UIImage? {
        queue.sync {
            cache.object(forKey: key as NSString)
        }
    }

    func setImage(_ image: UIImage, forKey key: String) {
        queue.async(flags: .barrier) {
            let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
            self.cache.setObject(image, forKey: key as NSString, cost: cost)
        }
    }

    func cacheKey(for imageName: String, size: CGSize) -> String {
        "\(imageName)_\(Int(size.width))x\(Int(size.height))"
    }
}

// MARK: - PaintingImage View

/// A view that displays a painting image with a placeholder fallback
/// Uses downsampling to efficiently load large images at the display size
struct PaintingImage: View {
    let imageName: String
    let contentMode: ContentMode
    let targetHeight: CGFloat?

    @State private var loadedImage: UIImage?
    @State private var isLoading = true

    init(_ imageName: String, contentMode: ContentMode = .fill, targetHeight: CGFloat? = nil) {
        self.imageName = imageName
        self.contentMode = contentMode
        self.targetHeight = targetHeight
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
                // Reload if size changes significantly
                loadImageIfNeeded(for: newSize)
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
        let targetSize = CGSize(
            width: size.width > 0 ? size.width : 800,
            height: targetHeight ?? (size.height > 0 ? size.height : 600)
        )

        let cacheKey = ImageCache.shared.cacheKey(for: imageName, size: targetSize)

        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: cacheKey) {
            self.loadedImage = cachedImage
            self.isLoading = false
            return
        }

        // Load asynchronously
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let image = downsampleImage(named: imageName, to: targetSize)

            DispatchQueue.main.async {
                if let image = image {
                    ImageCache.shared.setImage(image, forKey: cacheKey)
                    self.loadedImage = image
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

// MARK: - Full Resolution Loading (for Screensaver)

/// Load full resolution image for screensaver display
/// Only use this when displaying at full screen resolution
func loadFullResolutionImage(named imageName: String) -> UIImage? {
    // For screensaver, we want good quality but still capped at screen resolution
    // tvOS screens are typically 1920x1080 or 3840x2160
    let screenSize = UIScreen.main.bounds.size
    let scale = UIScreen.main.scale
    let maxDimension = max(screenSize.width, screenSize.height) * scale

    let targetSize = CGSize(width: maxDimension, height: maxDimension)
    return downsampleImage(named: imageName, to: targetSize, scale: 1.0)
}

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

    // Fallback: load from asset catalog
    if let image = UIImage(named: imageName) {
        return image.size.width / image.size.height
    }

    return nil
}
