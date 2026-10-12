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
nonisolated func downsampleImage(
    named imageName: String,
    to pointSize: CGSize,
    contentMode: ContentMode = .fill,
    scale: CGFloat = 1.0
) -> UIImage? {
    guard pointSize.width.isFinite, pointSize.height.isFinite, scale.isFinite,
          pointSize.width > 0, pointSize.height > 0, scale > 0 else { return nil }
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
nonisolated func downsampleScaleFactor(
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
nonisolated private func imageURL(for imageName: String) -> URL? {
    for ext in ["jpg", "jpeg", "png", "heic"] {
        if let url = Bundle.main.url(forResource: imageName, withExtension: ext) {
            return url
        }
    }
    return nil
}

/// ImageIO downsampling for file-backed images: decodes directly at thumbnail
/// size without ever materializing the full-resolution bitmap.
nonisolated private func downsampleFromFile(url: URL, targetPixelSize: CGSize, contentMode: ContentMode) -> UIImage? {
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
nonisolated private func downsampleFromAssetCatalog(named imageName: String, targetPixelSize: CGSize, contentMode: ContentMode) -> UIImage? {
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

// MARK: - Requests and cache

/// Pixel dimensions are part of identity. Small layout fluctuations share one
/// decode, and Retina requests can never reuse a lower-resolution cache entry.
nonisolated struct ImageRequest: Hashable, Sendable {
    let imageName: String
    let pixelWidth: Int
    let pixelHeight: Int
    let fillsFrame: Bool

    init?(imageName: String, size: CGSize, contentMode: ContentMode, scale: CGFloat) {
        guard size.width.isFinite, size.height.isFinite, scale.isFinite,
              size.width > 0, size.height > 0, scale > 0 else { return nil }
        self.imageName = imageName
        // Bound malformed requests, while allowing native 4K output.
        pixelWidth = Int(min(8192, ceil(size.width * scale / 64) * 64))
        pixelHeight = Int(min(8192, ceil(size.height * scale / 64) * 64))
        fillsFrame = contentMode == .fill
    }

    var size: CGSize { CGSize(width: pixelWidth, height: pixelHeight) }
    var contentMode: ContentMode { fillsFrame ? .fill : .fit }
    var cacheKey: String { "\(imageName)_\(pixelWidth)x\(pixelHeight)_\(fillsFrame)" }
}

/// NSCache synchronizes access internally. Previews have their own small budget
/// so a full-screen image cannot evict every thumbnail needed for navigation.
nonisolated final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private let images = NSCache<NSString, UIImage>()
    private let previews = NSCache<NSString, UIImage>()

    init() {
        images.totalCostLimit = 64 * 1024 * 1024
        images.countLimit = 80
        previews.totalCostLimit = 12 * 1024 * 1024
        previews.countLimit = 30
    }

    func image(for request: ImageRequest) -> UIImage? {
        images.object(forKey: request.cacheKey as NSString)
    }

    func preview(for imageName: String) -> UIImage? {
        previews.object(forKey: imageName as NSString)
    }

    func insert(_ image: UIImage, for request: ImageRequest) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height }
            ?? Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        images.setObject(image, forKey: request.cacheKey as NSString, cost: cost)
        if cost <= 4 * 1024 * 1024 {
            previews.setObject(image, forKey: request.imageName as NSString, cost: cost)
        } else if preview(for: request.imageName) == nil {
            let ratio = 640 / max(image.size.width, image.size.height)
            let size = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            if let preview = image.preparingThumbnail(of: size) {
                let cost = preview.cgImage.map { $0.bytesPerRow * $0.height } ?? 640 * 640 * 4
                previews.setObject(preview, forKey: request.imageName as NSString, cost: cost)
            }
        }
    }

    func removeAll() {
        images.removeAllObjects()
        previews.removeAllObjects()
    }
}

/// Coalesces identical requests. A maximum of two decodes can run at once,
/// independently of how many lazy-grid cells SwiftUI creates. Completed work is
/// cached even if a view leaves, but cancelled consumers never update their UI.
actor PaintingImageLoader {
    static let shared = PaintingImageLoader()
    nonisolated let cache: ImageCache
    private let queue: OperationQueue
    private let decode: @Sendable (ImageRequest) -> UIImage?
    private var inFlight: [ImageRequest: (id: UUID, task: Task<UIImage?, Never>)] = [:]

    init(cache: ImageCache = .shared,
         decode: @escaping @Sendable (ImageRequest) -> UIImage? = { request in
             downsampleImage(named: request.imageName, to: request.size,
                             contentMode: request.contentMode)
         }) {
        self.cache = cache
        self.decode = decode
        queue = OperationQueue()
        queue.name = "com.galleryglow.image-decoding"
        queue.maxConcurrentOperationCount = 2
        queue.qualityOfService = .userInitiated
    }

    func image(for request: ImageRequest) async -> UIImage? {
        guard !Task.isCancelled else { return nil }
        if let image = cache.image(for: request) { return image }
        if let work = inFlight[request] { return await work.task.value }

        let id = UUID()
        let task = Task { [queue, decode, cache] in
            let image: UIImage? = await withCheckedContinuation { continuation in
                let operation = BlockOperation {
                    let image = autoreleasepool {
                        let image = decode(request)
                        if let image { cache.insert(image, for: request) }
                        return image
                    }
                    continuation.resume(returning: image)
                }
                // A selected full-screen painting should not sit behind a queue
                // of offscreen thumbnail work from rapid scrolling.
                operation.queuePriority = request.pixelWidth >= 1280 ? .veryHigh : .normal
                queue.addOperation(operation)
            }
            return image
        }
        inFlight[request] = (id, task)
        let image = await task.value
        if inFlight[request]?.id == id { inFlight[request] = nil }
        return image
    }
}

// MARK: - PaintingImage View

struct PaintingImage: View {
    let imageName: String
    let contentMode: ContentMode
    let targetSize: CGSize?
    let allowsRetry: Bool
    let loader: PaintingImageLoader
    let onFailureChange: (Bool) -> Void

    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var loadedImage: UIImage?
    @State private var loadedName: String?
    @State private var completedRequest: ImageRequest?
    @State private var failedRequest: ImageRequest?
    @State private var showProgress = false
    @State private var attempt = 0
    @FocusState private var retryHasFocus: Bool

    private struct LoadID: Equatable {
        let request: ImageRequest?
        let attempt: Int
    }

    init(_ imageName: String, contentMode: ContentMode = .fill,
         targetSize: CGSize? = nil, allowsRetry: Bool = false,
         loader: PaintingImageLoader = .shared,
         onFailureChange: @escaping (Bool) -> Void = { _ in }) {
        self.imageName = imageName
        self.contentMode = contentMode
        self.targetSize = targetSize
        self.allowsRetry = allowsRetry
        self.loader = loader
        self.onFailureChange = onFailureChange
    }

    var body: some View {
        GeometryReader { geometry in
            let request = ImageRequest(imageName: imageName, size: targetSize ?? geometry.size,
                                       contentMode: contentMode, scale: displayScale)
            let image = request.flatMap { loader.cache.image(for: $0) }
                ?? (loadedName == imageName ? loadedImage : nil)
                ?? loader.cache.preview(for: imageName)
            let failed = request != nil && failedRequest == request
            let loading = request != nil && completedRequest != request && !failed
            let loadID = LoadID(request: request, attempt: attempt)

            ZStack {
                if image == nil { Color(white: 0.12) }
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .accessibilityLabel("Artwork")
                        .accessibilityIdentifier("artwork-\(imageName)")
                        .aspectRatio(contentMode: contentMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if failed {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.artframe")
                        Text("Artwork unavailable")
                            .font(.callout)
                        if allowsRetry {
                            Button("Try Again") { attempt += 1 }
                                .focused($retryHasFocus)
                                .defaultFocus($retryHasFocus, true)
                        }
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                } else if image == nil && loading && showProgress {
                    ProgressView("Loading artwork")
                }
            }
            .onChange(of: failed) { _, failed in
                onFailureChange(failed)
                retryHasFocus = failed && allowsRetry
            }
            .task(id: loadID) {
                guard let request else { return }
                failedRequest = nil
                let image = await loader.image(for: request)
                guard !Task.isCancelled else { return }
                if let image {
                    withAnimation(reduceMotion ? nil : .easeIn(duration: 0.15)) {
                        loadedImage = image
                        loadedName = request.imageName
                        completedRequest = request
                    }
                } else {
                    failedRequest = request
                }
            }
            .task(id: loadID) {
                showProgress = false
                guard image == nil, let request else { return }
                // Avoid flashing a spinner for fast, local cache/asset loads.
                do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
                if completedRequest != request && failedRequest != request {
                    showProgress = true
                }
            }
        }
    }
}

// MARK: - Aspect Ratio Helper

/// Get the aspect ratio of an image without loading the full image
nonisolated func getImageAspectRatio(for imageName: String) -> CGFloat? {
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
