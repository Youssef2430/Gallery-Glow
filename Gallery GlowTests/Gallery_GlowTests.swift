//
//  Gallery_GlowTests.swift
//  Gallery GlowTests
//
//  Created by Youssef Chouay on 2025-12-28.
//

import Testing
import Foundation
import UIKit
@testable import Gallery_Glow

struct Gallery_GlowTests {

    @Test("Painting data is internally consistent")
    func paintingDataIsInternallyConsistent() {
        let data = PaintingData.shared

        #expect(!data.artists.isEmpty)
        #expect(!data.allPaintings.isEmpty)
        #expect(!data.directorsCut.isEmpty)
        #expect(data.directorsCut.allSatisfy { $0.forceFullScreen })
        #expect(Set(data.allPaintings.map { $0.id }).count == data.allPaintings.count)
        #expect(data.allPaintings.allSatisfy { !$0.title.isEmpty && !$0.imageName.isEmpty })
    }

    @Test("All painting assets referenced by data exist")
    @MainActor
    func allPaintingAssetsExist() {
        for painting in PaintingData.shared.allPaintings {
            #expect(UIImage(named: painting.imageName) != nil, "Missing asset: \(painting.imageName)")
        }
    }
}
