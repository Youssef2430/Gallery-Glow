import AppKit
import ImageIO
import UniformTypeIdentifiers

// Vector artwork exported for tvOS depth layers, Top Shelf, in-app use and the web.
// Run from the repository root: swift Tools/Release/render-brand.swift
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("Gallery Glow/Assets.xcassets")
let brand = assets.appendingPathComponent("App Icon & Top Shelf Image.brandassets")
let previews = root.appendingPathComponent("artifacts/release-2026-10/previews")
try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255,
            blue: CGFloat(hex & 255)/255, alpha: 1)
}
let paper = color(0xF5F2E8), ink = color(0x252D26), gold = color(0xDDB350)
let sage = color(0xA4AE86), forest = color(0x485D46), sand = color(0xD4C7A6)
func rect(_ r: CGRect, _ c: NSColor, radius: CGFloat = 0) {
    c.setFill(); NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
}
func canvas(_ w: Int, _ h: Int, alpha: Bool = false, _ draw: () -> Void) -> NSBitmapImageRep {
    let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : .noneSkipLast).rawValue)!
    NSGraphicsContext.saveGraphicsState()
    context.translateBy(x: 0, y: CGFloat(h)); context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return NSBitmapImageRep(cgImage: context.makeImage()!)
}
func save(_ bitmap: NSBitmapImageRep, _ url: URL) throws {
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
}
// Normalized 100 × 70 framed landscape; front and middle retain genuine alpha.
func mark(_ frame: CGRect, layer: String? = nil) {
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.translateBy(x: frame.minX, y: frame.minY)
    ctx.scaleBy(x: frame.width/100, y: frame.height/70)
    if layer == nil || layer == "Middle" {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: CGRect(x: 5, y: 5, width: 90, height: 60), xRadius: 4, yRadius: 4).addClip()
        rect(CGRect(x: 5, y: 5, width: 90, height: 60), color(0xEBE4CD))
        gold.setFill(); NSBezierPath(ovalIn: CGRect(x: 62, y: 13, width: 17, height: 17)).fill()
        let far = NSBezierPath()
        far.move(to: CGPoint(x: 5, y: 47))
        far.curve(to: CGPoint(x: 95, y: 37), controlPoint1: CGPoint(x: 42, y: 7), controlPoint2: CGPoint(x: 49, y: 54))
        far.line(to: CGPoint(x: 95, y: 65)); far.line(to: CGPoint(x: 5, y: 65)); far.close()
        sage.setFill(); far.fill()
        let near = NSBezierPath()
        near.move(to: CGPoint(x: 5, y: 37))
        near.curve(to: CGPoint(x: 95, y: 56), controlPoint1: CGPoint(x: 39, y: 31), controlPoint2: CGPoint(x: 47, y: 72))
        near.line(to: CGPoint(x: 95, y: 65)); near.line(to: CGPoint(x: 5, y: 65)); near.close()
        forest.setFill(); near.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
    if layer == nil || layer == "Front" {
        let rim = NSBezierPath(roundedRect: CGRect(x: 2.5, y: 2.5, width: 95, height: 65), xRadius: 7, yRadius: 7)
        rim.lineWidth = 5; ink.setStroke(); rim.stroke()
        let inner = NSBezierPath(roundedRect: CGRect(x: 6, y: 6, width: 88, height: 58), xRadius: 3, yRadius: 3)
        inner.lineWidth = 1.4; gold.setStroke(); inner.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
}
func icon(_ w: Int, _ h: Int, layer: String? = nil) -> NSBitmapImageRep {
    canvas(w, h, alpha: layer == "Front" || layer == "Middle") {
        if layer == nil || layer == "Back" {
            NSGradient(starting: color(0xFFFCF4), ending: color(0xDED8C6))!
                .draw(in: CGRect(x: 0, y: 0, width: w, height: h), angle: 75)
        }
        if layer != "Back" {
            let width = min(CGFloat(w)*0.70, CGFloat(h)*1.02), height = min(CGFloat(w)*0.70, CGFloat(h)*1.02)*0.70
            mark(CGRect(x: (CGFloat(w)-width)/2, y: (CGFloat(h)-height)/2, width: width, height: height), layer: layer)
        }
    }
}
// Browser favicons need their own alpha mask; tvOS backgrounds stay opaque.
func favicon(_ size: Int) -> NSBitmapImageRep {
    canvas(size, size, alpha: true) {
        let side = CGFloat(size)
        rect(CGRect(x: 0, y: 0, width: side, height: side), paper, radius: side * 0.26)
        mark(CGRect(x: side * 0.11, y: side * 0.227, width: side * 0.78, height: side * 0.546))
    }
}
let ico = root.appendingPathComponent("docs/favicon.ico")
let destination = CGImageDestinationCreateWithURL(ico as CFURL, UTType.ico.identifier as CFString, 3, nil)!
for size in [16,32,48] { CGImageDestinationAddImage(destination, favicon(size).cgImage!, nil) }
precondition(CGImageDestinationFinalize(destination))
try save(favicon(32), root.appendingPathComponent("docs/favicon-32.png"))
if CommandLine.arguments.contains("--web-only") {
    print("Rendered rounded browser favicons with transparent corners.")
    exit(0)
}

for (stack, w, h, suffix) in [("App Icon",400,240,"@1x"), ("App Icon",800,480,"@2x"), ("App Icon - App Store",1280,768,"")] {
    let base = stack == "App Icon" ? "400x240" : "1280x768"
    for layer in ["Back", "Middle", "Front"] {
        let filename = "\(layer.lowercased())-\(base)\(suffix).png"
        try save(icon(w,h,layer:layer), brand.appendingPathComponent("\(stack).imagestack/\(layer).imagestacklayer/Content.imageset/\(filename)"))
    }
}
try save(icon(1280,768), previews.appendingPathComponent("app-icon.png"))
try save(icon(1024,1024), assets.appendingPathComponent("GalleryBrandIcon.imageset/gallery-brand-icon.png"))
try save(icon(180,180), root.appendingPathComponent("docs/apple-touch-icon.png"))

func text(_ value: String, _ r: CGRect, size: CGFloat, serif: Bool = false, color: NSColor = ink) {
    let font = NSFont(name: serif ? "Baskerville" : "AvenirNext-Medium", size: size) ?? .systemFont(ofSize: size)
    (value as NSString).draw(in: r, withAttributes: [.font: font, .foregroundColor: color])
}
func framedArt(_ path: String, in frame: CGRect) {
    let image = NSImage(contentsOf: assets.appendingPathComponent(path))!
    rect(frame, ink); rect(frame.insetBy(dx: 5, dy: 5), color(0xFFFCF4))
    let available = frame.insetBy(dx: 22, dy: 22), ratio = image.size.width/image.size.height
    let w = min(available.width, available.height*ratio), h = min(available.width, available.height*ratio)/ratio
    image.draw(in: CGRect(x: available.midX-w/2, y: available.midY-h/2, width: w, height: h),
               from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation:NSImageInterpolation.high])
}
for width in [1920,2320] {
    for scale in [1,2] {
        let bitmap = canvas(width*scale,720*scale) {
            NSGraphicsContext.current!.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            rect(CGRect(x: 0,y: 0,width: width,height: 720),paper)
            let inset = CGFloat(width-1920)/2
            mark(CGRect(x: 140+inset,y: 135,width: 100,height: 70))
            text("GALLERY GLOW",CGRect(x: 140+inset,y: 239,width: 680,height: 45),size: 26)
            text("Art, at home.",CGRect(x: 135+inset,y: 300,width: 740,height: 105),size: 90,serif: true)
            text("A space for art. A moment for you.",CGRect(x: 140+inset,y: 435,width: 690,height: 60),size: 28,color: forest)
            framedArt("Monet/Stacks_of_Wheat_End_of_Summer.imageset/Stacks_of_Wheat_End_of_Summer.jpg",in:CGRect(x: 920+inset,y: 170,width: 390,height: 340))
            framedArt("Church/Heart_of_the_Andes.imageset/Heart_of_the_Andes.jpg",in:CGRect(x: 1340+inset,y: 210,width: 440,height: 340))
            rect(CGRect(x: 140+inset,y: 571,width: 1640,height: 1),sand)
            text("THE COLLECTION  /  APPLE TV",CGRect(x: 140+inset,y: 597,width: 1640,height: 40),size: 18,color: forest)
        }
        let wide = width == 2320
        let dir = wide ? "Top Shelf Image Wide.imageset" : "Top Shelf Image.imageset"
        let name = wide ? "top-shelf-wide-2320x720" : "top-shelf-1920x720"
        try save(bitmap, brand.appendingPathComponent("\(dir)/\(name)@\(scale)x.png"))
        if scale == 1 { try save(bitmap, previews.appendingPathComponent("\(name).png")) }
    }
}
print("Rendered layered tvOS icons, both Top Shelf formats, in-app mark, touch icon and favicon.")
