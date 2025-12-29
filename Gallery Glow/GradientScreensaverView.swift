//
//  GradientScreensaverView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI
import Combine

// MARK: - Gradient Palette

enum GradientPalette: String, CaseIterable, Identifiable {
    case random = "Random"
    case magentaPurple = "Magenta Purple"
    case pinkOrange = "Pink Orange"
    case oceanBlue = "Ocean Blue"
    case sunriseGold = "Sunrise Gold"
    case aurora = "Aurora"
    
    var id: String { rawValue }
    
    var colors: [Color] {
        switch self {
        case .random:
            return GradientColorGenerator.allPalettes.randomElement()!
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
    
    var previewColors: [Color] {
        colors
    }
}

// MARK: - Fluid Gradient View

struct GradientScreensaverView: View {
    let palette: GradientPalette
    
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()
    @State private var colors: [Color] = []
    @State private var nextColors: [Color] = []
    @State private var colorTransition: Double = 0
    
    let colorTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Solid background to prevent any bleed-through
            Color(currentColors.first ?? .black)
                .ignoresSafeArea()
            
            TimelineView(.animation(minimumInterval: 1.0/60.0)) { timeline in
                let time = timeline.date.timeIntervalSince(startDate)
                
                GeometryReader { geo in
                    let blurRadius = min(geo.size.width, geo.size.height) * 0.04
                    let padding = blurRadius * 3
                    
                    Canvas { context, size in
                        drawFluidGradient(context: context, size: size, time: time)
                    }
                    .frame(
                        width: geo.size.width + padding * 2,
                        height: geo.size.height + padding * 2
                    )
                    .blur(radius: blurRadius)
                    .offset(x: -padding, y: -padding)
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            startDate = Date()
            colors = GradientColorGenerator.generateColors(for: palette)
            nextColors = colors
        }
        .onReceive(colorTimer) { _ in
            transitionToNewColors()
        }
        .onExitCommand {
            dismiss()
        }
    }
    
    private var currentColors: [Color] {
        if colors.isEmpty { return palette.colors }
        if colorTransition <= 0 { return colors }
        
        return zip(colors, nextColors).map { current, next in
            interpolateColor(from: current, to: next, progress: colorTransition)
        }
    }
    
    private func drawFluidGradient(context: GraphicsContext, size: CGSize, time: Double) {
        let cols = currentColors
        guard cols.count >= 4 else { return }
        
        // Fill entire background with blended color to prevent dark corners
        let bgGradient = Gradient(colors: [cols[0], cols[1], cols[2], cols[3]])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(
                bgGradient,
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            )
        )
        
        // Animated blob positions - 8 blobs for full coverage including corners
        let blobs: [(baseX: Double, baseY: Double, freqX: Double, freqY: Double, phase: Double, colorIdx: Int, radius: Double)] = [
            // Corner blobs - fixed positions with slight movement
            (0.0, 0.0, 0.08, 0.10, 0.0, 0, 0.8),      // Top-left
            (1.0, 0.0, 0.10, 0.08, 1.0, 1, 0.8),      // Top-right
            (0.0, 1.0, 0.09, 0.11, 2.0, 2, 0.8),      // Bottom-left
            (1.0, 1.0, 0.11, 0.09, 3.0, 3, 0.8),      // Bottom-right
            // Center blobs - more movement
            (0.5, 0.5, 0.12, 0.14, 1.5, 0, 1.0),      // Center
            (0.3, 0.5, 0.14, 0.12, 2.5, 1, 0.7),      // Left-center
            (0.7, 0.5, 0.13, 0.15, 0.5, 2, 0.7),      // Right-center
            (0.5, 0.7, 0.15, 0.13, 3.5, 3, 0.7),      // Bottom-center
        ]
        
        for blob in blobs {
            let x = blob.baseX + 0.15 * sin(time * blob.freqX + blob.phase)
            let y = blob.baseY + 0.15 * cos(time * blob.freqY + blob.phase * 0.7)
            
            let center = CGPoint(x: x * size.width, y: y * size.height)
            let radius = max(size.width, size.height) * blob.radius
            
            let color = cols[blob.colorIdx % cols.count]
            let nextColor = cols[(blob.colorIdx + 1) % cols.count]
            
            let gradient = Gradient(colors: [
                color.opacity(0.9),
                color.opacity(0.6),
                nextColor.opacity(0.3),
                nextColor.opacity(0.1)
            ])
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )),
                with: .radialGradient(
                    gradient,
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
        }
    }
    
    private func interpolateColor(from: Color, to: Color, progress: Double) -> Color {
        let fromC = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toC = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        return Color(
            red: fromC[0] + (toC[0] - fromC[0]) * progress,
            green: fromC[1] + (toC[1] - fromC[1]) * progress,
            blue: fromC[2] + (toC[2] - fromC[2]) * progress
        )
    }
    
    private func transitionToNewColors() {
        nextColors = GradientColorGenerator.generateColors(for: palette)
        
        // Smooth 8-second transition
        let duration = 8.0
        let steps = 120 // More steps = smoother
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [self] in
                let progress = Double(i) / Double(steps)
                // Ease in-out curve
                let eased = progress < 0.5 
                    ? 2 * progress * progress 
                    : 1 - pow(-2 * progress + 2, 2) / 2
                colorTransition = eased
                
                if i == steps {
                    colors = nextColors
                    colorTransition = 0
                }
            }
        }
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
    
    static func generateColors(for palette: GradientPalette = .random) -> [Color] {
        let basePalette: [Color]
        
        switch palette {
        case .random:
            basePalette = allPalettes.randomElement()!
        default:
            basePalette = palette.colors
        }
        
        return basePalette.map { color in
            adjustColor(color)
        }.shuffled()
    }
    
    private static func adjustColor(_ color: Color) -> Color {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        let variation = 0.12
        return Color(
            red: clamp(components[0] + Double.random(in: -variation...variation)),
            green: clamp(components[1] + Double.random(in: -variation...variation)),
            blue: clamp(components[2] + Double.random(in: -variation...variation))
        )
    }
    
    private static func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }
}

#Preview {
    GradientScreensaverView(palette: .random)
}
