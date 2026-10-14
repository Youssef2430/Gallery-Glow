import AppKit

// Deterministic marketing layouts around screenshots of the actual app.
// Run: swift Tools/Release/render-assets.swift /tmp/gallery-glow-release-6
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "/tmp/gallery-glow-release-6")
let output = root.appendingPathComponent("app-store-assets/release-1.0-6")
let web = root.appendingPathComponent("docs/assets")
let previews = root.appendingPathComponent("artifacts/release-2026-10/previews")
try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let paper = NSColor(srgbRed: 0.965, green: 0.961, blue: 0.937, alpha: 1)
let ink = NSColor(srgbRed: 0.075, green: 0.082, blue: 0.071, alpha: 1)
let secondary = NSColor(srgbRed: 0.37, green: 0.38, blue: 0.34, alpha: 1)
let gold = NSColor(srgbRed: 0.94, green: 0.73, blue: 0.17, alpha: 1)
func text(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular, color: NSColor = ink) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 1
    let font = NSFont(name: weight == .bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular", size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
    (value as NSString).draw(in: CGRect(x: x, y: y, width: width, height: size * 3), withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
}
func canvas(width: Int, height: Int, draw: () -> Void) -> NSBitmapImageRep {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    NSGraphicsContext.saveGraphicsState()
    context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return NSBitmapImageRep(cgImage: context.makeImage()!)
}

func image(_ image: NSImage, in rect: CGRect) {
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
}
let cards = [
    ("01-gallery-home", "Your own private gallery.", "A daily masterpiece. A whole collection to explore.", "01-living-gallery"),
    ("04-birth-of-venus", "Give great art a bigger stage.", "Timeless paintings, beautifully at home on Apple TV.", "02-great-art"),
    ("06-artist-klimt", "A closer look at the masters.", "Explore nine artists, one quiet moment at a time.", "03-the-artists"),
    ("05-nighthawks", "Set the scene. Stay a while.", "From Hopper’s city nights to Monet’s summer light.", "04-nighthawks"),
    ("07-gradient-aurora", "A little color. A different mood.", "Five animated ambient scenes for the space around you.", "05-ambient-scenes"),
    ("02-creation-of-adam", "A room with a different view.", "Art that fills your screen. Details worth slowing down for.", "06-masterpieces"),
    ("03-linde-frieze", "Make time for something beautiful.", "Classic art, without accounts, ads, or distractions.", "07-quiet-moments"),
    ("08-lifetime-pass", "One purchase. Yours to keep.", "Every painting. Every ambient scene. No subscription.", "08-lifetime")
]
for (index, card) in cards.enumerated() {
    let shot = NSImage(contentsOf: source.appendingPathComponent(card.0 + ".png"))!
    let bitmap = canvas(width: 3840, height: 2160) {
        paper.setFill(); CGRect(x: 0, y: 0, width: 3840, height: 2160).fill()
        text("GALLERY GLOW", x: 170, y: 90, width: 1300, size: 48, weight: .bold)
        text("APPLE TV  /  THE COLLECTION", x: 2790, y: 102, width: 900, size: 28, color: secondary)
        text(card.1, x: 170, y: 210, width: 3500, size: 126, weight: .bold)
        text(card.2, x: 174, y: 382, width: 3400, size: 43, color: secondary)
        ink.setFill()
        NSBezierPath(roundedRect: CGRect(x: 575, y: 540, width: 2690, height: 1525), xRadius: 36, yRadius: 36).fill()
        image(shot, in: CGRect(x: 590, y: 555, width: 2660, height: 1496.25))
        gold.setFill(); NSBezierPath(ovalIn: CGRect(x: 170, y: 1980, width: 16, height: 16)).fill()
        text("ART, AT HOME.", x: 208, y: 1970, width: 420, size: 23, weight: .bold)
        text(String(format: "%02d / 08", index + 1), x: 3450, y: 1970, width: 230, size: 23, color: secondary)
    }
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(card.3 + ".png"))
    let small = canvas(width: 1200, height: 675) { image(NSImage(cgImage: bitmap.cgImage!, size: .zero), in: CGRect(x: 0, y: 0, width: 1200, height: 675)) }
    try small.representation(using: .jpeg, properties: [.compressionFactor: 0.85])!.write(to: previews.appendingPathComponent(card.3 + ".jpg"))
}
// Website screenshots remain unadorned, so the native UI can be inspected.
for (input, name) in [("01-gallery-home", "gallery-home"), ("06-artist-klimt", "gallery-artist"), ("07-gradient-aurora", "gallery-ambient"), ("08-lifetime-pass", "gallery-lifetime")] {
    let shot = NSImage(contentsOf: source.appendingPathComponent(input + ".png"))!
    let bitmap = canvas(width: 1600, height: 900) { image(shot, in: CGRect(x: 0, y: 0, width: 1600, height: 900)) }
    try bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.86])!.write(to: web.appendingPathComponent(name + ".jpg"))
}
let social = canvas(width: 1200, height: 630) {
    paper.setFill(); CGRect(x: 0, y: 0, width: 1200, height: 630).fill()
    text("GALLERY GLOW", x: 62, y: 52, width: 1080, size: 54, weight: .bold)
    text("Great art.\nRight at home.", x: 62, y: 180, width: 450, size: 60, weight: .bold)
    text("Classic paintings & ambient scenes\nfor Apple TV.", x: 65, y: 385, width: 430, size: 23, color: secondary)
    text("A daily painting, free. A lifetime of looking.", x: 65, y: 552, width: 1050, size: 21, color: secondary)
    let venus = NSImage(contentsOf: root.appendingPathComponent("docs/assets/birth-of-venus-1600.jpg"))!
    ink.setFill(); NSBezierPath(roundedRect: CGRect(x: 545, y: 165, width: 590, height: 363), xRadius: 18, yRadius: 18).fill()
    image(venus, in: CGRect(x: 560, y: 180, width: 560, height: 333))
}
try social.representation(using: .jpeg, properties: [.compressionFactor: 0.92])!.write(to: web.appendingPathComponent("gallery-glow-social.jpg"))
try Data(contentsOf: source.appendingPathComponent("08-lifetime-pass.png")).write(to: root.appendingPathComponent("app-store-assets/iap-review-screenshot.png"))
print("Rendered eight 4K App Store cards, four web screenshots, and a social preview.")
