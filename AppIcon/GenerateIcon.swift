#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Gradient palettes - vibrant colors
let palettes: [String: [(r: CGFloat, g: CGFloat, b: CGFloat)]] = [
    "magentaPurple": [
        (1.0, 0.0, 0.75),   // Bright magenta
        (0.75, 0.0, 1.0),   // Violet
        (0.55, 0.1, 0.95),  // Purple
        (0.95, 0.3, 0.9),   // Pink-purple
        (0.6, 0.0, 0.85),   // Deep violet
    ],
    "pinkOrange": [
        (1.0, 0.15, 0.45),  // Hot pink
        (1.0, 0.45, 0.15),  // Orange
        (1.0, 0.55, 0.25),  // Golden orange
        (1.0, 0.2, 0.35),   // Red-pink
        (0.95, 0.35, 0.5),  // Coral
    ],
    "oceanBlue": [
        (0.0, 0.85, 1.0),   // Cyan
        (0.1, 0.45, 0.95),  // Ocean blue
        (0.25, 0.65, 1.0),  // Sky blue
        (0.0, 0.95, 0.85),  // Turquoise
        (0.15, 0.55, 0.9),  // Deep cyan
    ],
    "aurora": [
        (0.1, 0.95, 0.55),  // Green
        (0.35, 0.85, 1.0),  // Cyan
        (0.55, 0.25, 0.95), // Purple
        (0.0, 0.85, 0.45),  // Teal
        (0.4, 0.9, 0.7),    // Mint
    ],
]

func generateGradientIcon(palette: String, size: Int, outputPath: String) {
    guard let colors = palettes[palette] else {
        print("Unknown palette: \(palette)")
        print("Available: \(palettes.keys.sorted().joined(separator: ", "))")
        return
    }
    
    let width = size
    let height = size
    
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
    
    let w = CGFloat(width)
    let h = CGFloat(height)
    
    // Blend colors for smoother base
    func blend(_ c1: (r: CGFloat, g: CGFloat, b: CGFloat), _ c2: (r: CGFloat, g: CGFloat, b: CGFloat), _ t: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        return (c1.r + (c2.r - c1.r) * t, c1.g + (c2.g - c1.g) * t, c1.b + (c2.b - c1.b) * t)
    }
    
    // Create smooth multi-stop gradient for base
    let c0 = colors[0], c1 = colors[1], c2 = colors[2], c3 = colors[3]
    let mid1 = blend(c0, c1, 0.5)
    let mid2 = blend(c1, c2, 0.5)
    let mid3 = blend(c2, c3, 0.5)
    
    let baseGradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: c0.r, green: c0.g, blue: c0.b, alpha: 1),
            CGColor(red: mid1.r, green: mid1.g, blue: mid1.b, alpha: 1),
            CGColor(red: c1.r, green: c1.g, blue: c1.b, alpha: 1),
            CGColor(red: mid2.r, green: mid2.g, blue: mid2.b, alpha: 1),
            CGColor(red: c2.r, green: c2.g, blue: c2.b, alpha: 1),
            CGColor(red: mid3.r, green: mid3.g, blue: mid3.b, alpha: 1),
            CGColor(red: c3.r, green: c3.g, blue: c3.b, alpha: 1),
        ] as CFArray,
        locations: [0, 0.15, 0.33, 0.5, 0.66, 0.82, 1]
    )!
    
    context.drawLinearGradient(
        baseGradient,
        start: CGPoint(x: 0, y: h),
        end: CGPoint(x: w, y: 0),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    
    // Draw very large, soft, overlapping blobs with low alpha
    let blobs: [(x: CGFloat, y: CGFloat, radius: CGFloat, colorIdx: Int, alpha: CGFloat)] = [
        // Huge soft blobs covering entire image
        (0.0, 1.0, 1.4, 0, 0.35),
        (1.0, 1.0, 1.4, 1, 0.35),
        (0.0, 0.0, 1.4, 2, 0.35),
        (1.0, 0.0, 1.4, 3, 0.35),
        // Large center blobs
        (0.5, 0.5, 1.2, 0, 0.3),
        (0.5, 0.5, 1.0, 2, 0.25),
        // Soft accent blobs
        (0.25, 0.75, 0.9, 0, 0.25),
        (0.75, 0.75, 0.9, 1, 0.25),
        (0.25, 0.25, 0.9, 2, 0.25),
        (0.75, 0.25, 0.9, 3, 0.25),
        // Additional blending blobs
        (0.5, 0.75, 0.8, 1, 0.2),
        (0.5, 0.25, 0.8, 3, 0.2),
        (0.25, 0.5, 0.8, 0, 0.2),
        (0.75, 0.5, 0.8, 2, 0.2),
    ]
    
    for blob in blobs {
        let centerX = blob.x * w
        let centerY = blob.y * h
        let radius = blob.radius * min(w, h)
        let color = colors[blob.colorIdx]
        
        // Very gradual falloff for smooth blending
        let blobGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [
                CGColor(red: color.r, green: color.g, blue: color.b, alpha: blob.alpha),
                CGColor(red: color.r, green: color.g, blue: color.b, alpha: blob.alpha * 0.7),
                CGColor(red: color.r, green: color.g, blue: color.b, alpha: blob.alpha * 0.4),
                CGColor(red: color.r, green: color.g, blue: color.b, alpha: blob.alpha * 0.15),
                CGColor(red: color.r, green: color.g, blue: color.b, alpha: 0),
            ] as CFArray,
            locations: [0, 0.25, 0.5, 0.75, 1]
        )!
        
        context.drawRadialGradient(
            blobGradient,
            startCenter: CGPoint(x: centerX, y: centerY),
            startRadius: 0,
            endCenter: CGPoint(x: centerX, y: centerY),
            endRadius: radius,
            options: []
        )
    }
    
    // Get image
    guard let image = context.makeImage() else {
        print("Failed to create image")
        return
    }
    
    // Save as PNG
    let url = URL(fileURLWithPath: outputPath)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        print("Failed to create destination")
        return
    }
    
    CGImageDestinationAddImage(destination, image, nil)
    
    if CGImageDestinationFinalize(destination) {
        print("✅ Saved: \(outputPath)")
        print("   Size: \(size)x\(size)")
        print("   Palette: \(palette)")
    } else {
        print("Failed to save image")
    }
}

// Main
let palette = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "magentaPurple"
let size = CommandLine.arguments.count > 2 ? Int(CommandLine.arguments[2]) ?? 1280 : 1280
let output = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "AppIcon_\(palette).png"

print("Generating gradient icon...")
generateGradientIcon(palette: palette, size: size, outputPath: output)
