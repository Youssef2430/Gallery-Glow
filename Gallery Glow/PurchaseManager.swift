//
//  PurchaseManager.swift
//  Gallery Glow
//
//  Created by Codex on 2026-06-06.
//

import Combine
import Foundation
import OSLog
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
    /// True once the local entitlement check has completed at least once.
    /// Views use this to avoid flashing purchase UI at owners on launch.
    @Published private(set) var hasCheckedEntitlements = false
    @Published var statusMessage: String?

    private let productIDs: Set<String>
    private var productLoadTask: Task<[Product], Error>?
    private var transactionUpdatesTask: Task<Void, Never>?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "GalleryGlow",
        category: "purchases"
    )

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeProductID }
    }

    /// The localized price from the App Store, or nil until the product loads.
    /// Never substitute a hardcoded price: it would be wrong in most storefronts.
    var lifetimeDisplayPrice: String? {
        lifetimeProduct?.displayPrice
    }

    var isUnlocked: Bool {
        purchasedProductIDs.contains(Self.lifetimeProductID)
    }

    var shouldOfferPurchase: Bool {
        hasCheckedEntitlements && !isUnlocked
    }

    init(
        productIDs: Set<String> = [PurchaseManager.lifetimeProductID],
        startsTransactionListener: Bool = true
    ) {
        self.productIDs = productIDs

        if startsTransactionListener {
            transactionUpdatesTask = listenForTransactionUpdates()
            Task { await refreshPurchasedProducts() }
        } else {
            // Previews and tests never talk to StoreKit; report the check as
            // done so locked-state UI renders immediately.
            hasCheckedEntitlements = true
        }
    }

    deinit {
        productLoadTask?.cancel()
        transactionUpdatesTask?.cancel()
    }

    func prepareForStore() async {
        // The entitlement check is local and fast; never queue it behind the
        // network product fetch, or owners see purchase UI while it loads.
        async let entitlements: Void = refreshPurchasedProducts()
        async let productLoad: Void = loadProducts()
        _ = await (entitlements, productLoad)
    }

    func loadProducts() async {
        if let productLoadTask {
            await applyLoadedProducts(from: productLoadTask)
            return
        }

        isLoadingProducts = true
        let productIDs = Array(productIDs)
        let productLoadTask = Task {
            try await Product.products(for: productIDs)
        }
        self.productLoadTask = productLoadTask
        defer {
            self.productLoadTask = nil
            isLoadingProducts = false
        }

        await applyLoadedProducts(from: productLoadTask)
    }

    private func applyLoadedProducts(from productLoadTask: Task<[Product], Error>) async {
        do {
            let storeProducts = try await productLoadTask.value
            products = storeProducts.sorted { $0.displayName < $1.displayName }

            if lifetimeProduct == nil {
                logger.error("Product request succeeded but \(Self.lifetimeProductID) was not returned")
                statusMessage = "Lifetime unlock is temporarily unavailable. Please try again later."
            } else {
                statusMessage = nil
            }
        } catch {
            logger.error("Product request failed: \(error, privacy: .public)")
            statusMessage = Self.userFacingMessage(
                for: error,
                fallback: "Could not load the lifetime unlock. Please try again."
            )
        }
    }

    func purchaseLifetime() async -> PurchaseOutcome {
        if lifetimeProduct == nil {
            await loadProducts()
        }

        guard let product = lifetimeProduct else {
            let message = statusMessage ?? "Lifetime unlock is temporarily unavailable. Please try again later."
            statusMessage = message
            return .failed(message)
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(.verified(let transaction)):
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                await refreshPurchasedProducts()
                statusMessage = nil
                logger.info("Lifetime purchase completed")
                return .success

            case .success(.unverified(_, let error)):
                // Deliberately not finished: StoreKit redelivers the
                // transaction via Transaction.updates once it verifies.
                logger.error("Purchase succeeded but failed verification: \(error, privacy: .public)")
                let message = "Your purchase went through but couldn't be verified yet. It will unlock automatically."
                statusMessage = message
                return .failed(message)

            case .pending:
                logger.info("Purchase is pending (Ask to Buy / SCA)")
                let message = "Purchase is awaiting approval. Everything unlocks automatically once it's approved."
                statusMessage = message
                return .pending

            case .userCancelled:
                statusMessage = nil
                return .cancelled

            @unknown default:
                let message = "Purchase did not complete. Please try again."
                statusMessage = message
                return .failed(message)
            }
        } catch StoreKitError.userCancelled {
            statusMessage = nil
            return .cancelled
        } catch {
            logger.error("Purchase failed: \(error, privacy: .public)")
            let message = Self.userFacingMessage(
                for: error,
                fallback: "Purchase failed. Please try again."
            )
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
                logger.info("Restore completed and unlocked the app")
                return .restored
            }

            let message = "No lifetime purchase was found for this Apple Account."
            statusMessage = message
            return .failed(message)
        } catch StoreKitError.userCancelled {
            // The user backed out of the App Store sign-in; not an error.
            return .cancelled
        } catch {
            logger.error("Restore failed: \(error, privacy: .public)")
            let message = Self.userFacingMessage(
                for: error,
                fallback: "Restore failed. Please try again."
            )
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
        hasCheckedEntitlements = true
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    private func handle(transactionResult result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            let wasUnlocked = isUnlocked
            await refreshPurchasedProducts()
            await transaction.finish()

            if !wasUnlocked && isUnlocked {
                // An Ask to Buy approval or a purchase on another device just
                // unlocked the app; clear any stale prompt.
                statusMessage = nil
                logger.info("Transaction update unlocked the app")
            }
        case .unverified(_, let error):
            // Leave it unfinished; StoreKit retries delivery after it verifies.
            logger.error("Ignoring unverified transaction update: \(error, privacy: .public)")
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

    private static func userFacingMessage(for error: Error, fallback: String) -> String {
        switch error {
        case StoreKitError.networkError:
            return "The App Store couldn't be reached. Check the network connection and try again."
        case StoreKitError.notAvailableInStorefront:
            return "The lifetime unlock isn't available in your region's App Store."
        case StoreKitError.notEntitled:
            return fallback
        case Product.PurchaseError.purchaseNotAllowed:
            return "Purchases aren't allowed on this Apple TV. Check Screen Time & Restrictions, then try again."
        default:
            return fallback
        }
    }
}
