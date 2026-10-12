import Foundation
import Observation
import StoreKit
import UIKit

nonisolated enum GalleryEntitlement: Equatable, Sendable {
    case checking, locked, unlocked, unverified
}

nonisolated struct LifetimeOffer: Equatable, Sendable {
    let displayPrice: String
    let familyShareable: Bool
}

nonisolated enum StorePurchaseResult: Sendable {
    case purchased, pending, cancelled
}

@MainActor
protocol LifetimeStore: AnyObject {
    var updates: AsyncStream<GalleryEntitlement> { get }
    func loadOffer() async throws -> LifetimeOffer?
    func entitlement() async -> GalleryEntitlement
    func purchase() async throws -> StorePurchaseResult
    func restore() async throws
}

/// The App Store is the source of truth. No UserDefaults flag can grant access.
@MainActor @Observable
final class PurchaseManager {
    nonisolated static let lifetimeProductID = "galleryglow.lifetime.v2"
    // Apple reserved the previous, removed product ID. Continue honoring any
    // verified historical ownership while offering the replacement product.
    nonisolated static let legacyProductID = "galleryglow.lifetime"
    enum Operation { case idle, purchasing, restoring }

    private(set) var entitlement: GalleryEntitlement = .checking
    private(set) var offer: LifetimeOffer?
    private(set) var isLoadingOffer = false
    private(set) var operation: Operation = .idle
    private(set) var isPending = false
    private(set) var message: String?
    private(set) var offerError: String?
    var isUnlocked: Bool { entitlement == .unlocked }
    var isBusy: Bool { operation != .idle }
    var canPurchase: Bool { offer != nil && !isBusy && !isPending && entitlement == .locked }

    @ObservationIgnored private let store: any LifetimeStore
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    @ObservationIgnored private var entitlementRevision = 0

    init(store: (any LifetimeStore)? = nil) {
        let store = store ?? StoreKitLifetimeStore()
        self.store = store
        let updates = store.updates
        updatesTask = Task { [weak self] in
            for await entitlement in updates {
                guard !Task.isCancelled else { return }
                self?.apply(entitlement)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    func prepare() async {
        // Local entitlement verification must never wait for a network price lookup.
        async let access: Void = refreshEntitlement()
        async let price: Void = loadOffer()
        _ = await (access, price)
    }

    func refreshEntitlement() async {
        entitlementRevision += 1
        let revision = entitlementRevision
        let result = await store.entitlement()
        guard revision == entitlementRevision else { return }
        apply(result)
    }

    func loadOffer() async {
        guard !isLoadingOffer, offer == nil else { return }
        isLoadingOffer = true
        offerError = nil
        defer { isLoadingOffer = false }
        do {
            offer = try await store.loadOffer()
            if offer == nil {
                offerError = "The lifetime pass is temporarily unavailable. Try again, or restore an existing purchase."
            }
        } catch is CancellationError {
            return
        } catch {
            offerError = Self.message(for: error, fallback: "Couldn’t load the price. Check your connection and try again.")
        }
    }

    func purchase() async {
        // Take the operation lock before the first suspension: double-clicks and
        // restore cannot start a second StoreKit flow.
        guard canPurchase else { return }
        operation = .purchasing
        message = nil
        defer { operation = .idle }
        do {
            switch try await store.purchase() {
            case .purchased:
                apply(.unlocked)
            case .pending:
                if !isUnlocked {
                    isPending = true
                    message = "Awaiting approval. Your gallery opens automatically when Apple confirms the purchase. You can keep browsing."
                }
            case .cancelled:
                break
            }
        } catch StoreKitError.userCancelled {
            // Cancelling the Apple confirmation is a normal exit, not a failure.
        } catch StoreKitLifetimeStore.Failure.verification {
            apply(.unverified)
        } catch {
            message = Self.message(for: error, fallback: "The purchase couldn’t be completed. Please try again.")
        }
    }

    func restore() async {
        guard !isBusy else { return }
        operation = .restoring
        message = nil
        defer { operation = .idle }
        do {
            try await store.restore()
            await refreshEntitlement()
            if entitlement == .locked {
                message = "No lifetime purchase was found. Use the Apple Account that originally purchased Gallery Glow."
            }
        } catch StoreKitError.userCancelled {
        } catch {
            message = Self.message(for: error, fallback: "Couldn’t restore your purchase. Check your connection and try again.")
        }
    }

    private func apply(_ value: GalleryEntitlement) {
        entitlementRevision += 1
        entitlement = value
        if value == .unlocked {
            isPending = false
            message = nil
        } else if value == .unverified {
            message = "Apple couldn’t verify your purchase. Try Restore Purchase. You won’t be asked to buy it again."
        }
    }

    private static func message(for error: Error, fallback: String) -> String {
        switch error {
        case StoreKitLifetimeStore.Failure.verification:
            "Apple couldn’t verify this purchase. Try Restore Purchase before buying again."
        case StoreKitLifetimeStore.Failure.noScene:
            "Return to the gallery and try again to open Apple’s purchase confirmation."
        case StoreKitError.networkError:
            "The App Store couldn’t be reached. Check your connection and try again."
        case StoreKitError.notAvailableInStorefront:
            "The lifetime pass isn’t available in your App Store region."
        case Product.PurchaseError.purchaseNotAllowed:
            "Purchases are restricted on this Apple TV. Check your purchase restrictions in Settings."
        default: fallback
        }
    }
}

@MainActor
final class StoreKitLifetimeStore: LifetimeStore {
    enum Failure: Error { case verification, noScene, unavailable }
    let updates: AsyncStream<GalleryEntitlement>
    private let productID: String
    private let entitlementIDs: Set<String>
    private var product: Product?
    private var listener: Task<Void, Never>?

    init(productID: String = PurchaseManager.lifetimeProductID,
         legacyProductIDs: Set<String> = [PurchaseManager.legacyProductID]) {
        self.productID = productID
        let entitlementIDs = legacyProductIDs.union([productID])
        self.entitlementIDs = entitlementIDs
        let (stream, continuation) = AsyncStream<GalleryEntitlement>.makeStream(bufferingPolicy: .bufferingNewest(1))
        updates = stream
        // Subscribe immediately so unfinished and Ask to Buy transactions cannot
        // fall into a gap between launch and the first paywall presentation.
        listener = Task {
            for await result in Transaction.updates {
                guard !Task.isCancelled else { break }
                switch result {
                case .verified(let transaction) where entitlementIDs.contains(transaction.productID):
                    // A refund of the historical product must not revoke a
                    // separate, valid replacement purchase (and vice versa).
                    let access = Self.access(for: transaction) == .unlocked
                        ? GalleryEntitlement.unlocked : await Self.currentAccess(for: entitlementIDs)
                    continuation.yield(access)
                    await transaction.finish()
                case .unverified(let transaction, _) where entitlementIDs.contains(transaction.productID):
                    let access = await Self.currentAccess(for: entitlementIDs)
                    continuation.yield(access == .unlocked ? .unlocked : .unverified)
                default: break
                }
            }
            continuation.finish()
        }
    }

    deinit { listener?.cancel() }

    func loadOffer() async throws -> LifetimeOffer? {
        let products = try await Product.products(for: [productID])
        product = products.first { $0.id == productID && $0.type == .nonConsumable }
        return product.map { LifetimeOffer(displayPrice: $0.displayPrice, familyShareable: $0.isFamilyShareable) }
    }

    func entitlement() async -> GalleryEntitlement {
        await Self.currentAccess(for: entitlementIDs)
    }

    private static func currentAccess(for productIDs: Set<String>) async -> GalleryEntitlement {
        var access: GalleryEntitlement = .locked
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction) where productIDs.contains(transaction.productID):
                if Self.access(for: transaction) == .unlocked { return .unlocked }
            case .unverified(let transaction, _) where productIDs.contains(transaction.productID):
                access = .unverified
            default: break
            }
        }
        return access
    }

    func purchase() async throws -> StorePurchaseResult {
        guard let product else { throw Failure.unavailable }
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { throw Failure.noScene }
        // Explicit presentation context fixes confirmation failing over a tvOS modal.
        let result = try await product.purchase(confirmIn: scene)
        switch result {
        case .success(.verified(let transaction)):
            guard transaction.productID == productID, Self.access(for: transaction) == .unlocked else {
                throw Failure.verification
            }
            await transaction.finish()
            return .purchased
        case .success(.unverified): throw Failure.verification
        case .pending: return .pending
        case .userCancelled: return .cancelled
        @unknown default: throw Failure.unavailable
        }
    }

    func restore() async throws { try await AppStore.sync() }

    private static func access(for transaction: Transaction) -> GalleryEntitlement {
        transaction.productType == .nonConsumable && transaction.revocationDate == nil && !transaction.isUpgraded
            ? .unlocked : .locked
    }
}
