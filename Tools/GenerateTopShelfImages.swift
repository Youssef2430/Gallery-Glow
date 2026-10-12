import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// Render offline so the extension only hands lightweight image URLs to tvOS.
/// Each 444 × 250pt tile ships at 2x. Its header, artwork, and footer share
/// one center line. tvOS supplies the only painting title below the card.
@main
struct GenerateTopShelfImages {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw RenderError.invalid("Usage: generate-shelf <repository path>")
        }
        let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let assets = root.appendingPathComponent("Gallery Glow/Assets.xcassets")
        let output = root.appendingPathComponent("Gallery Shelf/TopShelfImages")
        let renderer = try ShelfRenderer(assets: assets)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        for painting in PaintingData.shared.allPaintings {
            try autoreleasepool {
                let name = painting.imageName.replacingOccurrences(of: "/", with: "_")
                for featured in [false, true] {
                    let image = try renderer.painting(painting, featured: featured)
                    let filename = (featured ? "featured_" : "") + name + ".jpg"
                    try renderer.save(image, to: output.appendingPathComponent(filename))
                }
            }
        }
        for palette in GradientPalette.allCases {
            try autoreleasepool {
                let image = try renderer.gradient(palette)
                let filename = "gradient_" + palette.rawValue.lowercased().replacingOccurrences(of: " ", with: "_") + ".jpg"
                try renderer.save(image, to: output.appendingPathComponent(filename))
            }
        }
        let count = PaintingData.shared.allPaintings.count * 2 + GradientPalette.allCases.count
        print("Generated \(count) centered shelf previews at 888 × 500 in \(output.path)")
    }
}

private enum RenderError: Error {
    case invalid(String)
}

private struct ShelfRenderer {
    let assets: URL
    let mount: NSColor
    let paper: NSColor
    let ink: NSColor
    let secondary: NSColor
    let accent = NSColor(srgbRed: 0.94, green: 0.73, blue: 0.17, alpha: 1)
    let size = CGSize(width: 888, height: 500)
    let rim: CGFloat = 6
    let mat: CGFloat = 15

    init(assets: URL) throws {
        self.assets = assets
        mount = try Self.color("GalleryMount", in: assets)
        paper = try Self.color("GalleryBackground", in: assets)
        ink = try Self.color("GalleryForeground", in: assets)
        secondary = try Self.color("GallerySecondary", in: assets)
    }

    private static func color(_ name: String, in assets: URL) throws -> NSColor {
        let url = assets.appendingPathComponent("\(name).colorset/Contents.json")
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let variants = json["colors"] as? [[String: Any]],
              let color = variants.first(where: { $0["appearances"] == nil })?["color"] as? [String: Any],
              let components = color["components"] as? [String: String],
              let r = Double(components["red"] ?? ""),
              let g = Double(components["green"] ?? ""),
              let b = Double(components["blue"] ?? "") else {
            throw RenderError.invalid("Missing gallery palette: \(url.path)")
        }
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    func painting(_ painting: Painting, featured: Bool) throws -> CGImage {
        let imageset = assets.appendingPathComponent("\(painting.imageName).imageset")
        let data = try Data(contentsOf: imageset.appendingPathComponent("Contents.json"))
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let images = json["images"] as? [[String: Any]],
              let filename = images.compactMap({ $0["filename"] as? String }).first,
              let source = CGImageSourceCreateWithURL(imageset.appendingPathComponent(filename) as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2000
              ] as CFDictionary) else {
            throw RenderError.invalid("Cannot load catalog artwork: \(painting.imageName)")
        }
        return try card(aspectRatio: CGFloat(image.width) / CGFloat(image.height),
                        credit: "\(painting.artistName) · \(painting.year)", featured: featured) { context, rect in
            context.translateBy(x: rect.minX, y: rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.draw(image, in: CGRect(origin: .zero, size: rect.size))
        }
    }

    func gradient(_ palette: GradientPalette) throws -> CGImage {
        try card(aspectRatio: 16.0 / 9.0, credit: palette.displayDescription) { context, rect in
            let colors = palette.previewColors.map { NSColor($0).cgColor }
            if let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                         colors: colors as CFArray, locations: nil) {
                context.drawLinearGradient(gradient, start: rect.origin,
                                           end: CGPoint(x: rect.maxX, y: rect.maxY),
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
            for (index, point) in [CGPoint(x: 0.75, y: 0.22), CGPoint(x: 0.26, y: 0.78)].enumerated() {
                let color = colors[index + 1]
                let center = CGPoint(x: rect.minX + rect.width * point.x, y: rect.minY + rect.height * point.y)
                if let clear = color.copy(alpha: 0),
                   let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                         colors: [color, clear] as CFArray, locations: [0, 1]) {
                    context.drawRadialGradient(glow, startCenter: center, startRadius: 0,
                                               endCenter: center, endRadius: rect.width * 0.4, options: [])
                }
            }
        }
    }

    private func card(aspectRatio: CGFloat, credit: String, featured: Bool = false,
                      artwork: (CGContext, CGRect) -> Void) throws -> CGImage {
        // 28px outside margins, 20px gaps around the artwork/credit, and a
        // 16px gap before the arrow. All coordinates are 2x bitmap pixels.
        let area = CGRect(x: 28, y: featured ? 84 : 28, width: 832, height: featured ? 288 : 344)
        let inset = rim + mat
        let width = min(area.width - 2 * inset, (area.height - 2 * inset) * aspectRatio)
        let height = width / aspectRatio
        let frame = CGRect(x: area.midX - width / 2 - inset, y: area.midY - height / 2 - inset,
                           width: width + 2 * inset, height: height + 2 * inset)
        return try canvas { context in
            if featured { drawFeaturedHeader(in: CGRect(x: 28, y: 28, width: 832, height: 36)) }
            drawFrame(frame, context: context)
            let rect = frame.insetBy(dx: inset, dy: inset)
            context.saveGState()
            context.addPath(CGPath(roundedRect: rect, cornerWidth: 12, cornerHeight: 12, transform: nil))
            context.clip()
            artwork(context, rect)
            context.restoreGState()

            context.setFillColor(ink.withAlphaComponent(0.10).cgColor)
            context.fill(CGRect(x: frame.minX, y: 382, width: frame.width, height: 1))
            centeredText(credit, in: CGRect(x: 28, y: 392, width: 832, height: 28),
                         font: .systemFont(ofSize: 24), color: secondary)
            drawArrow(in: CGRect(x: (size.width - 36) / 2, y: 436, width: 36, height: 36),
                      featured: featured)
        }
    }

    private func drawFeaturedHeader(in rect: CGRect) {
        let label = NSAttributedString(string: "ON VIEW TODAY", attributes: [
            .font: NSFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: secondary, .kern: 1.8
        ])
        let labelSize = label.size()
        let gap: CGFloat = 20
        let badgeWidth: CGFloat = 140
        let left = rect.midX - (labelSize.width + gap + badgeWidth) / 2
        label.draw(at: CGPoint(x: left, y: rect.midY - labelSize.height / 2))
        let badge = CGRect(x: left + labelSize.width + gap, y: rect.minY, width: badgeWidth, height: rect.height)
        accent.setFill()
        NSBezierPath(roundedRect: badge, xRadius: 18, yRadius: 18).fill()
        centeredText("Free today", in: badge, font: .systemFont(ofSize: 22, weight: .semibold), color: ink)
    }

    private func drawArrow(in rect: CGRect, featured: Bool) {
        (featured ? accent : NSColor.white).setFill()
        NSBezierPath(ovalIn: rect).fill()
        let arrow = NSBezierPath()
        arrow.move(to: CGPoint(x: rect.midX - 7, y: rect.midY + 7))
        arrow.line(to: CGPoint(x: rect.midX + 7, y: rect.midY - 7))
        arrow.move(to: CGPoint(x: rect.midX - 7, y: rect.midY - 7))
        arrow.line(to: CGPoint(x: rect.midX + 7, y: rect.midY - 7))
        arrow.line(to: CGPoint(x: rect.midX + 7, y: rect.midY + 7))
        arrow.lineWidth = 2
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .round
        ink.setStroke()
        arrow.stroke()
    }

    private func centeredText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor) {
        let line = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
        let bounds = line.size()
        let scale = min(1, rect.width / max(1, bounds.width))
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext.current!.cgContext
        context.translateBy(x: rect.midX - bounds.width * scale / 2,
                            y: rect.midY - bounds.height * scale / 2)
        context.scaleBy(x: scale, y: scale)
        line.draw(at: .zero)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawFrame(_ rect: CGRect, context: CGContext) {
        let outer = CGPath(roundedRect: rect, cornerWidth: 32, cornerHeight: 32, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -5), blur: 12,
                          color: NSColor.black.withAlphaComponent(0.14).cgColor)
        context.addPath(outer)
        context.setFillColor(NSColor(white: 0.13, alpha: 1).cgColor)
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(outer)
        context.clip()
        let colors = [0.25, 0.075, 0.18].map { NSColor(white: $0, alpha: 1).cgColor }
        if let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                     colors: colors as CFArray, locations: [0, 0.6, 1]) {
            context.drawLinearGradient(gradient, start: rect.origin,
                                       end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])
        }

        context.restoreGState()
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: rim, dy: rim),
                              cornerWidth: 26, cornerHeight: 26, transform: nil))
        context.setFillColor(mount.cgColor)
        context.fillPath()
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: rim + 0.5, dy: rim + 0.5),
                              cornerWidth: 26, cornerHeight: 26, transform: nil))
        context.setStrokeColor(NSColor.black.withAlphaComponent(0.16).cgColor)
        context.setLineWidth(1)
        context.strokePath()
        context.addPath(CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5),
                              cornerWidth: 32, cornerHeight: 32, transform: nil))
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.2).cgColor)
        context.strokePath()
    }

    private func canvas(draw: (CGContext) -> Void) throws -> CGImage {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                      bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw RenderError.invalid("Cannot create shelf bitmap")
        }
        context.setFillColor(paper.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        context.interpolationQuality = .high
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
        draw(context)
        NSGraphicsContext.restoreGraphicsState()
        guard let image = context.makeImage() else { throw RenderError.invalid("Cannot finish shelf bitmap") }
        return image
    }

    func save(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw RenderError.invalid("Cannot write \(url.path)")
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.9] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw RenderError.invalid("Cannot encode \(url.path)") }
    }
}
