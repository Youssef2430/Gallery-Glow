#if DEBUG
import Foundation
import StoreKit

/// Explicit, deterministic UI fixtures. Never compiled into the shipped app.
@MainActor
final class PurchaseUITestStore: LifetimeStore {
    let scenario: String
    let updates: AsyncStream<GalleryEntitlement>
    private let continuation: AsyncStream<GalleryEntitlement>.Continuation
    private var access: GalleryEntitlement
    private var loadCount = 0

    init(scenario: String) {
        self.scenario = scenario
        access = scenario == "owned" ? .unlocked : .locked
        (updates, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
    }

    func loadOffer() async throws -> LifetimeOffer? {
        loadCount += 1
        if scenario == "unavailable" || (scenario == "retry" && loadCount == 1) { return nil }
        return LifetimeOffer(displayPrice: "$9.99", familyShareable: false)
    }

    func entitlement() async -> GalleryEntitlement { access }

    func purchase() async throws -> StorePurchaseResult {
        try await Task.sleep(for: .milliseconds(250))
        switch scenario {
        case "cancelled": return .cancelled
        case "failure": throw StoreKitError.networkError(URLError(.notConnectedToInternet))
        case "unverified": throw StoreKitLifetimeStore.Failure.verification
        case "pending", "approved":
            if scenario == "approved" {
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(3))
                    self?.access = .unlocked
                    self?.continuation.yield(.unlocked)
                }
            }
            return .pending
        default:
            access = .unlocked
            return .purchased
        }
    }

    func restore() async throws {
        try await Task.sleep(for: .milliseconds(250))
        if scenario == "restore" { access = .unlocked }
    }
}
#endif
