import XCTest
import StoreKit
import StoreKitTest
@testable import Gallery_Glow

/// These use Apple's real StoreKit test service, separate from the UI fixtures.
final class StoreKitIntegrationTests: XCTestCase {
    @MainActor
    private func cleanSession() async throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "GalleryGlow")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        // StoreKit's daemon applies clear/reset asynchronously. Wait for its
        // transaction cache before beginning another independent test case.
        for _ in 0..<50 {
            var count = 0
            for await _ in Transaction.all { count += 1 }
            if count == 0 { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        return session
    }

    @MainActor
    func testRealProductPurchaseRelaunchAndRefund() async throws {
        let testSession = try await cleanSession()
        defer { testSession.clearTransactions() }
        let client = StoreKitLifetimeStore()
        let manager = PurchaseManager(store: client)
        await manager.prepare()
        XCTAssertNotNil(manager.offer)
        XCTAssertFalse(manager.isUnlocked)
        await manager.purchase()
        XCTAssertTrue(manager.isUnlocked, manager.message ?? "Purchase did not unlock")
        let relaunched = PurchaseManager(store: StoreKitLifetimeStore())
        for _ in 0..<50 {
            await relaunched.refreshEntitlement()
            if relaunched.isUnlocked { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(relaunched.isUnlocked, "Verified ownership must survive manager recreation")
        let transaction = try XCTUnwrap(testSession.allTransactions().first)
        try testSession.refundTransaction(identifier: transaction.identifier)
        for _ in 0..<50 {
            if !manager.isUnlocked && !relaunched.isUnlocked { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertFalse(manager.isUnlocked, "Refund must propagate through Transaction.updates")
        XCTAssertFalse(relaunched.isUnlocked)
    }

    @MainActor
    func testRealAskToBuyApproval() async throws {
        let testSession = try await cleanSession()
        testSession.askToBuyEnabled = true
        defer {
            testSession.askToBuyEnabled = false
            testSession.clearTransactions()
        }
        let manager = PurchaseManager(store: StoreKitLifetimeStore())
        await manager.prepare()
        await manager.purchase()
        XCTAssertTrue(manager.isPending, manager.message ?? "Expected Ask to Buy")
        XCTAssertFalse(manager.isUnlocked)
        let transaction = try XCTUnwrap(testSession.allTransactions().first)
        try testSession.approveAskToBuyTransaction(identifier: transaction.identifier)
        for _ in 0..<50 {
            if manager.isUnlocked { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(manager.isUnlocked)
        XCTAssertFalse(manager.isPending)
    }

    @MainActor
    func testHistoricalOwnershipAndIndependentRefunds() async throws {
        let testSession = try await cleanSession()
        defer { testSession.clearTransactions() }
        let old = try await testSession.buyProduct(identifier: PurchaseManager.legacyProductID)
        let manager = PurchaseManager(store: StoreKitLifetimeStore())
        for _ in 0..<50 {
            await manager.refreshEntitlement()
            if manager.isUnlocked { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(manager.isUnlocked, "Historical verified ownership must still restore")
        let current = try await testSession.buyProduct(identifier: PurchaseManager.lifetimeProductID)
        try testSession.refundTransaction(identifier: UInt(old.id))
        await manager.refreshEntitlement()
        XCTAssertTrue(manager.isUnlocked, "Refunding one product cannot revoke the other purchase")
        try testSession.refundTransaction(identifier: UInt(current.id))
        for _ in 0..<50 {
            await manager.refreshEntitlement()
            if !manager.isUnlocked { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertFalse(manager.isUnlocked)
    }
}
