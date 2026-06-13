//
//  GradientScreensaverView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import UIKit

// MARK: - Gradient Palette

enum GradientPalette: String, CaseIterable, Identifiable {
    case magentaPurple = "Magenta Purple"
    case pinkOrange = "Pink Orange"
    case oceanBlue = "Ocean Blue"
    case sunriseGold = "Sunrise Gold"
    case aurora = "Aurora"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .magentaPurple:
            return GradientColorGenerator.allPalettes[0]
        case .pinkOrange:
            return GradientColorGenerator.allPalettes[1]
        case .oceanBlue:
            return GradientColorGenerator.allPalettes[2]
        case .sunriseGold:
            return GradientColorGenerator.allPalettes[3]
        case .aurora:
            return GradientColorGenerator.allPalettes[4]
        }
    }

    var previewColors: [Color] { colors }

    /// Description for display in cards and Top Shelf
    var displayDescription: String {
        switch self {
        case .magentaPurple:
            return "Neon nights"
        case .pinkOrange:
            return "Warm sunset"
        case .oceanBlue:
            return "Deep sea"
        case .sunriseGold:
            return "Golden hour"
        case .aurora:
            return "Northern lights"
        }
    }
}

// MARK: - Fluid Gradient View

struct GradientScreensaverView: View {
    let palette: GradientPalette

    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()

    // Current and next colors stored as HSBA components so transitions
    // interpolate through hue space instead of muddying through grey.
    @State private var colorComponents: [SIMD4<Double>] = []
    @State private var nextColorComponents: [SIMD4<Double>] = []

    // Transition timing is driven outside the render loop so the mesh stays pure.
    @State private var transitionStartDate: Date?
    private let transitionDuration: Double = 8.0
    private let colorChangeInterval: Double = 60.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30.0)) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)
            let base = baseColors(at: timeline.date)

            MeshGradient(
                width: 4,
                height: 4,
                points: meshPoints(time: time),
                colors: meshColors(from: base),
                smoothsColors: true
            )
            .ignoresSafeArea()
        }
        .background(Color.black)
        .ignoresSafeArea(.all)
        .onAppear {
            startDate = Date()
            resetColors()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .task(id: palette) {
            await runColorCycle()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onExitCommand {
            dismiss()
        }
    }

    // MARK: - Mesh geometry

    /// 4×4 control-point grid. Edge points stay pinned to their edges so the
    /// gradient always covers the screen; the four interior points drift on
    /// independent sine/cosine paths for an organic, fluid motion.
    private func meshPoints(time: Double) -> [SIMD2<Float>] {
        func p(_ x: Double, _ y: Double) -> SIMD2<Float> {
            SIMD2(Float(x), Float(y))
        }
        let amp = 0.07 // small enough that interior points never cross or reach an edge
        func drift(_ baseX: Double, _ baseY: Double, _ fx: Double, _ fy: Double, _ phase: Double) -> SIMD2<Float> {
            p(baseX + amp * sin(time * fx + phase),
              baseY + amp * cos(time * fy + phase))
        }
        let t1 = 1.0 / 3.0
        let t2 = 2.0 / 3.0
        return [
            p(0, 0),  p(t1, 0),                         p(t2, 0),                         p(1, 0),
            p(0, t1), drift(t1, t1, 0.12, 0.10, 0.0),   drift(t2, t1, 0.10, 0.13, 1.0),   p(1, t1),
            p(0, t2), drift(t1, t2, 0.11, 0.12, 2.0),   drift(t2, t2, 0.13, 0.09, 3.0),   p(1, t2),
            p(0, 1),  p(t1, 1),                         p(t2, 1),                         p(1, 1),
        ]
    }

    /// Tile the 4 palette colors diagonally across the 4×4 grid so every color
    /// appears and they flow in smooth diagonal bands.
    private func meshColors(from base: [Color]) -> [Color] {
        var out: [Color] = []
        out.reserveCapacity(16)
        for row in 0..<4 {
            for col in 0..<4 {
                out.append(base[(row + col) % base.count])
            }
        }
        return out
    }

    // MARK: - Color interpolation

    /// Compute transition progress from elapsed time (replaces 121 GCD timers)
    private func transitionProgress(at date: Date) -> Double {
        guard let start = transitionStartDate else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        guard elapsed > 0 else { return 0 }
        if elapsed >= transitionDuration { return 1.0 }
        let linear = elapsed / transitionDuration
        // Ease in-out curve
        return linear < 0.5
            ? 2 * linear * linear
            : 1 - pow(-2 * linear + 2, 2) / 2
    }

    /// The 4 base colors for the current frame, ready to feed the mesh.
    private func baseColors(at date: Date) -> [Color] {
        let components = interpolatedColors(at: date)
        guard components.count >= 4 else { return palette.colors }
        return components.map { hsbToColor($0) }
    }

    private func interpolatedColors(at date: Date) -> [SIMD4<Double>] {
        let progress = transitionProgress(at: date)
        if progress <= 0 { return colorComponents }
        if progress >= 1.0 { return nextColorComponents }

        return zip(colorComponents, nextColorComponents).map { current, next in
            lerpHSB(current, next, progress)
        }
    }

    /// Interpolate two HSBA colors, taking the shortest path around the hue circle.
    private func lerpHSB(_ a: SIMD4<Double>, _ b: SIMD4<Double>, _ t: Double) -> SIMD4<Double> {
        var dh = b.x - a.x
        if dh > 0.5 { dh -= 1 } else if dh < -0.5 { dh += 1 }
        var h = a.x + dh * t
        if h < 0 { h += 1 } else if h >= 1 { h -= 1 }
        return SIMD4(
            h,
            a.y + (b.y - a.y) * t,
            a.z + (b.z - a.z) * t,
            a.w + (b.w - a.w) * t
        )
    }

    private func resetColors() {
        let initialColors = GradientColorGenerator.generateColors(for: palette)
        colorComponents = initialColors.map { colorToSIMD($0) }
        nextColorComponents = colorComponents
        transitionStartDate = nil
    }

    private func runColorCycle() async {
        while !Task.isCancelled {
            guard await sleep(seconds: colorChangeInterval) else { return }

            await MainActor.run {
                beginColorTransition(at: Date())
            }

            guard await sleep(seconds: transitionDuration) else { return }

            await MainActor.run {
                finishColorTransition()
            }
        }
    }

    private func beginColorTransition(at date: Date) {
        if transitionStartDate != nil {
            colorComponents = nextColorComponents
        }

        let newColors = GradientColorGenerator.generateColors(for: palette)
        nextColorComponents = newColors.map { colorToSIMD($0) }
        transitionStartDate = date
    }

    private func finishColorTransition() {
        colorComponents = nextColorComponents
        transitionStartDate = nil
    }

    private func sleep(seconds: Double) async -> Bool {
        do {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return !Task.isCancelled
        } catch {
            return false
        }
    }

    // MARK: - HSB Color Helpers

    /// Convert a Color to HSBA components. `getHue` always returns 4 values, so
    /// this is safe for greyscale colors (raw `cgColor.components` is not).
    private func colorToSIMD(_ color: Color) -> SIMD4<Double> {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return SIMD4<Double>(Double(h), Double(s), Double(b), Double(a))
    }

    private func hsbToColor(_ v: SIMD4<Double>) -> Color {
        Color(hue: v.x, saturation: v.y, brightness: v.z, opacity: v.w)
    }
}

// MARK: - Color Generator

struct GradientColorGenerator {
    static let allPalettes: [[Color]] = [
        // Magenta-Purple - vibrant neon purples and magentas
        [
            Color(red: 1.0, green: 0.0, blue: 0.8),      // Bright magenta
            Color(red: 0.7, green: 0.0, blue: 1.0),      // Violet
            Color(red: 0.5, green: 0.0, blue: 0.9),      // Deep purple
            Color(red: 0.9, green: 0.2, blue: 1.0),      // Light purple
        ],
        // Pink-Orange - warm sunset vibes
        [
            Color(red: 1.0, green: 0.2, blue: 0.5),      // Hot pink
            Color(red: 1.0, green: 0.4, blue: 0.1),      // Orange
            Color(red: 1.0, green: 0.6, blue: 0.2),      // Golden orange
            Color(red: 1.0, green: 0.1, blue: 0.3),      // Red-pink
        ],
        // Ocean Blue - deep sea to cyan
        [
            Color(red: 0.0, green: 0.8, blue: 1.0),      // Cyan
            Color(red: 0.0, green: 0.4, blue: 0.9),      // Ocean blue
            Color(red: 0.2, green: 0.6, blue: 1.0),      // Sky blue
            Color(red: 0.0, green: 0.9, blue: 0.8),      // Turquoise
        ],
        // Sunrise Gold - warm yellows and oranges
        [
            Color(red: 1.0, green: 0.85, blue: 0.0),     // Golden yellow
            Color(red: 1.0, green: 0.6, blue: 0.0),      // Orange
            Color(red: 1.0, green: 0.9, blue: 0.3),      // Light yellow
            Color(red: 1.0, green: 0.5, blue: 0.1),      // Deep orange
        ],
        // Aurora - northern lights inspired
        [
            Color(red: 0.0, green: 1.0, blue: 0.6),      // Green
            Color(red: 0.3, green: 0.8, blue: 1.0),      // Cyan
            Color(red: 0.6, green: 0.2, blue: 1.0),      // Purple
            Color(red: 0.0, green: 0.9, blue: 0.5),      // Teal
        ],
    ]

    static func generateColors(for palette: GradientPalette) -> [Color] {
        let basePalette = palette.colors

        return basePalette.map { color in
            adjustColor(color)
        }.shuffled()
    }

    /// Jitter in HSB space: nudge hue and brightness while keeping saturation
    /// high. This preserves each palette's neon character instead of
    /// desaturating toward grey the way independent per-RGB-channel noise does.
    private static func adjustColor(_ color: Color) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // ±0.03 of the hue circle ≈ ±11°
        var hue = Double(h) + Double.random(in: -0.03...0.03)
        if hue < 0 { hue += 1 } else if hue >= 1 { hue -= 1 }

        let sat = clamp(Double(s) + Double.random(in: -0.08...0.08), min: 0.6, max: 1.0)
        let bright = clamp(Double(b) + Double.random(in: -0.1...0.1), min: 0.35, max: 1.0)

        return Color(hue: hue, saturation: sat, brightness: bright, opacity: Double(a))
    }

    private static func clamp(_ value: Double, min lower: Double, max upper: Double) -> Double {
        Swift.max(lower, Swift.min(upper, value))
    }
}

#Preview {
    GradientScreensaverView(palette: .aurora)
}
