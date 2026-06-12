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
#if canImport(StoreKitTest)
import StoreKit
import StoreKitTest
#endif

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

    @Test("Lifetime StoreKit configuration is release-priced")
    func lifetimeStoreKitConfigurationIsReleasePriced() throws {
        let url = try #require(testBundle.url(forResource: "GalleryGlow", withExtension: "storekit"))
        let data = try Data(contentsOf: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let products = try #require(json["products"] as? [[String: Any]])
        let lifetime = try #require(products.first { $0["productID"] as? String == PurchaseManager.lifetimeProductID })

        #expect(lifetime["type"] as? String == "NonConsumable")
        #expect(lifetime["displayPrice"] as? String == "9.99")
        #expect(lifetime["familyShareable"] as? Bool == true)
    }

    #if canImport(StoreKitTest)
    @Test("StoreKit test session exposes lifetime product")
    func storeKitTestSessionExposesLifetimeProduct() async throws {
        let session = try SKTestSession(configurationFileNamed: "GalleryGlow")
        session.disableDialogs = true
        try session.clearTransactions()

        let products = try await Product.products(for: [PurchaseManager.lifetimeProductID])

        // SKTestSession cannot always reach the StoreKit test daemon on the tvOS
        // simulator (SKInternalErrorDomain Code=3), which yields an empty product
        // list even when the configuration is valid.
        withKnownIssue("StoreKitTest daemon is unreliable on the tvOS simulator", isIntermittent: true) {
            #expect(products.count == 1)
            #expect(products.first?.id == PurchaseManager.lifetimeProductID)
        }
    }
    #endif

    private var testBundle: Bundle {
        Bundle(for: TestBundleLocator.self)
    }
}

private final class TestBundleLocator {}
