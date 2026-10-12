#!/usr/bin/env swift

// Run from anywhere: swift AppIcon/ExportGlowFrame.swift
// Packages the original artwork and vector favicon using macOS system frameworks.
import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let output = root.appendingPathComponent("AppIcon/GlowFrame")
let catalog = root.appendingPathComponent("Gallery Glow/Assets.xcassets/App Icon & Top Shelf Image.brandassets")
let docs = root.appendingPathComponent("docs")
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [
        CGFloat((hex >> 16) & 255) / 255,
        CGFloat((hex >> 8) & 255) / 255,
        CGFloat(hex & 255) / 255, alpha
    ])!
}

func bitmap(_ width: Int, _ height: Int, opaque: Bool = false) -> CGContext {
    let alpha = opaque ? CGImageAlphaInfo.noneSkipLast : .premultipliedLast
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: colorSpace, bitmapInfo: alpha.rawValue)!
    context.interpolationQuality = .high
    return context
}

func png(_ image: CGImage, at url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "GlowFrame", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot write \(url.path)"])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "GlowFrame", code: 2, userInfo: [NSLocalizedDescriptionKey: "PNG export failed: \(url.path)"])
    }
}

func gradient(_ colors: [CGColor], locations: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)!
}

let sourceURL = output.appendingPathComponent("artwork.png")
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let original = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("Missing source artwork: \(sourceURL.path)")
}

// Remove transparent export padding while retaining the actual artwork and edge alpha.
let pixels = NSBitmapImageRep(cgImage: original)
guard let bytes = pixels.bitmapData, pixels.hasAlpha, pixels.bitsPerSample == 8,
      pixels.samplesPerPixel == 4, !pixels.isPlanar else {
    fatalError("Expected 8-bit RGBA source artwork")
}
let alphaIndex = pixels.bitmapFormat.contains(.alphaFirst) ? 0 : 3
var minX = original.width, minY = original.height, maxX = 0, maxY = 0
for y in 0..<original.height {
    for x in 0..<original.width where bytes[y * pixels.bytesPerRow + x * 4 + alphaIndex] > 8 {
        minX = min(minX, x); minY = min(minY, y)
        maxX = max(maxX, x); maxY = max(maxY, y)
    }
}
guard minX < maxX, minY < maxY else { fatalError("Source artwork is empty") }
let crop = CGRect(x: max(0, minX - 4), y: max(0, minY - 4),
                  width: min(original.width - max(0, minX - 4), maxX - minX + 9),
                  height: min(original.height - max(0, minY - 4), maxY - minY + 9))
let artwork = original.cropping(to: crop)!

func layers(width: Int, height: Int, square: Bool = false) -> [CGImage] {
    let w = CGFloat(width), h = CGFloat(height)
    let bounds = CGRect(x: 0, y: 0, width: w, height: h)
    let back = bitmap(width, height, opaque: true)
    back.drawLinearGradient(gradient([color(0x140F20), color(0x302037)], locations: [0, 1]),
                            start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
    back.drawRadialGradient(gradient([color(0x744757, alpha: 0.28), color(0x744757, alpha: 0)], locations: [0, 1]),
                            startCenter: CGPoint(x: w * 0.5, y: h * 0.48), startRadius: 0,
                            endCenter: CGPoint(x: w * 0.5, y: h * 0.48), endRadius: w * 0.62, options: [])

    let middle = bitmap(width, height)
    middle.drawRadialGradient(gradient([color(0xD79262, alpha: 0.19), color(0x8F55A1, alpha: 0.10), color(0x8F55A1, alpha: 0)],
                                        locations: [0, 0.5, 1]),
                              startCenter: CGPoint(x: w * 0.5, y: h * 0.45), startRadius: 0,
                              endCenter: CGPoint(x: w * 0.5, y: h * 0.45), endRadius: h * 0.65, options: [])

    let front = bitmap(width, height)
    let available = bounds.insetBy(dx: w * (square ? 0.085 : 0.14), dy: h * (square ? 0.15 : 0.12))
    let scale = min(available.width / CGFloat(artwork.width), available.height / CGFloat(artwork.height))
    let size = CGSize(width: CGFloat(artwork.width) * scale, height: CGFloat(artwork.height) * scale)
    front.draw(artwork, in: CGRect(x: (w - size.width) / 2, y: (h - size.height) / 2, width: size.width, height: size.height))
    return [back.makeImage()!, middle.makeImage()!, front.makeImage()!]
}

func composite(_ layers: [CGImage]) -> CGImage {
    let first = layers[0]
    let context = bitmap(first.width, first.height, opaque: true)
    for layer in layers {
        context.draw(layer, in: CGRect(x: 0, y: 0, width: first.width, height: first.height))
    }
    return context.makeImage()!
}

let variants = [(400, 240, "400x240@1x", "App Icon.imagestack"),
                (800, 480, "400x240@2x", "App Icon.imagestack"),
                (1280, 768, "1280x768", "App Icon - App Store.imagestack")]
for (width, height, suffix, stack) in variants {
    let images = layers(width: width, height: height)
    for (index, name) in ["Back", "Middle", "Front"].enumerated() {
        let url = catalog.appendingPathComponent("\(stack)/\(name).imagestacklayer/Content.imageset/\(name.lowercased())-\(suffix).png")
        try png(images[index], at: url)
    }
    if width == 1280 { try png(composite(images), at: output.appendingPathComponent("icon-tvos.png")) }
}

// Populate the previously empty middle layer in both image stacks.
for (stack, suffixes) in [("App Icon.imagestack", ["400x240@1x", "400x240@2x"]),
                           ("App Icon - App Store.imagestack", ["1280x768"])] {
    let images = suffixes.enumerated().map { index, suffix in
        ["filename": "middle-\(suffix).png", "idiom": "tv", "scale": "\(index + 1)x"]
    }
    let json: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
    var data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
    data.append(10)
    try data.write(to: catalog.appendingPathComponent("\(stack)/Middle.imagestacklayer/Content.imageset/Contents.json"))
}
try png(composite(layers(width: 1024, height: 1024, square: true)), at: output.appendingPathComponent("icon-square.png"))
try png(composite(layers(width: 180, height: 180, square: true)), at: docs.appendingPathComponent("apple-touch-icon.png"))

// AppKit rasterizes the canonical SVG; PNG and ICO exports share its exact geometry.
guard let favicon = NSImage(contentsOf: docs.appendingPathComponent("favicon.svg")) else {
    fatalError("Cannot read docs/favicon.svg")
}
for size in [16, 32, 48] {
    let context = bitmap(size, size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    favicon.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero,
                 operation: .copy, fraction: 1, respectFlipped: false,
                 hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    try png(context.makeImage()!, at: docs.appendingPathComponent("favicon-\(size)x\(size).png"))
}

// ICO permits PNG image entries. Keep all three browser fallback sizes in one file.
let sizes = [16, 32, 48]
let pngs = try sizes.map { try Data(contentsOf: docs.appendingPathComponent("favicon-\($0)x\($0).png")) }
var ico = Data()
func appendLE<T: FixedWidthInteger>(_ value: T) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { ico.append(contentsOf: $0) }
}
appendLE(UInt16(0)); appendLE(UInt16(1)); appendLE(UInt16(sizes.count))
var offset = 6 + sizes.count * 16
for (size, data) in zip(sizes, pngs) {
    ico.append(contentsOf: [UInt8(size), UInt8(size), 0, 0])
    appendLE(UInt16(1)); appendLE(UInt16(32))
    appendLE(UInt32(data.count)); appendLE(UInt32(offset))
    offset += data.count
}
pngs.forEach { ico.append($0) }
try ico.write(to: docs.appendingPathComponent("favicon.ico"))
print("Exported three tvOS icon layers at 400×240, 800×480, and 1280×768; square icon; touch icon; and SVG-derived PNG/ICO favicons.")
