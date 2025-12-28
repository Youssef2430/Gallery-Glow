//
//  ScreensaverView.swift
//  Gallery Glow
//
//  Created by Youssef Chouay on 2025-12-28.
//

import SwiftUI

struct ScreensaverView: View {
    let painting: Painting
    @Environment(\.dismiss) private var dismiss
    @State private var showInfo = false
    @State private var infoOpacity: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Painting image - centered and maximized
                PaintingImage(painting.imageName, contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            
            // Info overlay
            VStack {
                Spacer()
                
                if showInfo {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(painting.title)
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("\(painting.artistName), \(String(painting.year))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.bottom, 60)
                    .opacity(infoOpacity)
                }
            }
        }
        }
        .ignoresSafeArea()
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.3)) {
                showInfo.toggle()
                infoOpacity = showInfo ? 1 : 0
            }
        }
        .onExitCommand {
            dismiss()
        }
    }
}

#Preview {
    ScreensaverView(painting: PaintingData.shared.allPaintings[0])
}
