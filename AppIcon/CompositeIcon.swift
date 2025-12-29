#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func loadImage(from path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        print("Failed to load image: \(path)")
        return nil
    }
    return image
}

func compositeIcon(backgroundPath: String, iconPath: String, outputPath: String, width: Int, height: Int) {
    guard let background = loadImage(from: backgroundPath),
          let icon = loadImage(from: iconPath) else {
        return
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        print("Failed to create context")
        return
    }
    
    // Draw background scaled to fill
    let bgRect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(background, in: bgRect)
    
    // Calculate icon size - make it ~70% of the height for good visibility
    let iconScale = 0.65
    let iconSize = Int(Double(height) * iconScale)
    let iconX = (width - iconSize) / 2
    let iconY = (height - iconSize) / 2
    let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
    
    // Draw icon centered
    context.draw(icon, in: iconRect)
    
    // Save result
    guard let result = context.makeImage() else {
        print("Failed to create result image")
        return
    }
    
    let url = URL(fileURLWithPath: outputPath)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        print("Failed to create destination")
        return
    }
    
    CGImageDestinationAddImage(destination, result, nil)
    
    if CGImageDestinationFinalize(destination) {
        print("✅ Created: \(outputPath) (\(width)x\(height))")
    } else {
        print("Failed to save: \(outputPath)")
    }
}

// Paths
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().path
let backgroundPath = "\(scriptDir)/AppIcon_MagentaPurple.png"
let iconPath = "\(scriptDir)/liquid-glass-icon/icons-96.png"

// Generate different sizes for tvOS app icon (rectangular format)
// tvOS uses 400x240 (1x), 800x480 (2x), and 1280x768 for App Store
let sizes: [(width: Int, height: Int, filename: String)] = [
    (400, 240, "AppIcon_LiquidGlass_1x.png"),
    (800, 480, "AppIcon_LiquidGlass_2x.png"),
    (1280, 768, "AppIcon_LiquidGlass.png"),  // Full size for App Store
]

print("Compositing liquid glass icon with gradient background...")
print("Background: \(backgroundPath)")
print("Icon overlay: \(iconPath)")
print("")

for size in sizes {
    let outputPath = "\(scriptDir)/\(size.filename)"
    compositeIcon(backgroundPath: backgroundPath, iconPath: iconPath, outputPath: outputPath, width: size.width, height: size.height)
}

print("\n✅ Done! Copy the generated icons to your Assets.xcassets")
