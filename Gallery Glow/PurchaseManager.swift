//
//  PurchaseManager.swift
//  Gallery Glow
//
//  Created by Codex on 2026-06-06.
//

import Combine
import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    nonisolated static let lifetimeProductID = "galleryglow.lifetime"

    enum PurchaseOutcome: Equatable {
        case success
        case restored
        case pending
        case cancelled
        case failed(String)
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isRestoring = false
    @Published var statusMessage: String?

    private let productIDs: Set<String>
    private var transactionUpdatesTask: Task<Void, Never>?

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    var lifetimeDisplayPrice: String {
        lifetimeProduct?.displayPrice ?? "$9.99"
    }

    var isUnlocked: Bool {
        purchasedProductIDs.contains(Self.lifetimeProductID)
    }

    init(
        productIDs: Set<String> = [PurchaseManager.lifetimeProductID],
        startsTransactionListener: Bool = true
    ) {
        self.productIDs = productIDs

        if startsTransactionListener {
            transactionUpdatesTask = listenForTransactionUpdates()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func prepareForStore() async {
        await loadProducts()
        await refreshPurchasedProducts()
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let storeProducts = try await Product.products(for: Array(productIDs))
            products = storeProducts.sorted { $0.displayName < $1.displayName }

            if lifetimeProduct == nil {
                statusMessage = "Lifetime unlock is temporarily unavailable. Please try again later."
            } else {
                statusMessage = nil
            }
        } catch {
            statusMessage = "Could not load the lifetime unlock. Please try again."
        }
    }

    func purchaseLifetime() async -> PurchaseOutcome {
        if lifetimeProduct == nil {
            await loadProducts()
        }

        guard let product = lifetimeProduct else {
            let message = "Lifetime unlock is temporarily unavailable. Please try again later."
            statusMessage = message
            return .failed(message)
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                await refreshPurchasedProducts()
                statusMessage = nil
                return .success

            case .pending:
                let message = "Purchase is pending approval."
                statusMessage = message
                return .pending

            case .userCancelled:
                return .cancelled

            @unknown default:
                let message = "Purchase did not complete. Please try again."
                statusMessage = message
                return .failed(message)
            }
        } catch {
            let message = "Purchase failed. Please try again."
            statusMessage = message
            return .failed(message)
        }
    }

    func restorePurchases() async -> PurchaseOutcome {
        guard !isRestoring else { return .pending }

        isRestoring = true
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()

            if isUnlocked {
                statusMessage = nil
                return .restored
            }

            let message = "No lifetime purchase was found for this Apple ID."
            statusMessage = message
            return .failed(message)
        } catch {
            let message = "Restore failed. Please try again."
            statusMessage = message
            return .failed(message)
        }
    }

    func refreshPurchasedProducts() async {
        var activePurchases: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result),
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }

            activePurchases.insert(transaction.productID)
        }

        purchasedProductIDs = activePurchases
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    private func handle(transactionResult result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            await refreshPurchasedProducts()
            await transaction.finish()
            statusMessage = nil
        } catch {
            statusMessage = "Could not verify the latest purchase update."
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}
