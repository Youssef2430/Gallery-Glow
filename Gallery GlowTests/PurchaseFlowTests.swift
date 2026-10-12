import Testing
import StoreKit
@testable import Gallery_Glow

@MainActor
struct PurchaseFlowTests {
    @Test func missingProductNeverStartsAPurchase() async {
        let store = TestLifetimeStore()
        store.offer = nil
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        await manager.purchase()
        #expect(manager.offerError != nil)
        #expect(!manager.canPurchase)
        #expect(store.purchaseCalls == 0)
        store.offer = .init(displayPrice: "12,99 €", familyShareable: false)
        await manager.loadOffer()
        #expect(manager.offer?.displayPrice == "12,99 €")
        #expect(manager.offerError == nil)
    }

    @Test func ownerAccessDoesNotDependOnProductAvailability() async {
        let store = TestLifetimeStore()
        store.access = .unlocked
        store.offer = nil
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        #expect(manager.isUnlocked)
        #expect(!manager.canPurchase)
    }

    @Test func purchaseResumesTheMostRecentRequestedArtwork() async {
        let store = TestLifetimeStore()
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        session.present(.gradient(.aurora))
        #expect(session.selection == nil)
        #expect(session.isStorePresented)
        let painting = PaintingData.shared.allPaintings.first { $0.id != session.freePainting.id }!
        session.open(URL(string: "galleryglow://painting/\(painting.imageName)")!)
        #expect(session.pendingSelection == .painting(painting))
        await manager.purchase()
        session.reconcileAccess()
        #expect(session.selection == .painting(painting))
        #expect(session.pendingSelection == nil)
        #expect(!session.isStorePresented)
    }

    @Test func cancellingDoesNotUnlockOrShowAnError() async {
        let store = TestLifetimeStore()
        store.result = .cancelled
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        await manager.purchase()
        #expect(!manager.isUnlocked)
        #expect(manager.message == nil)
        #expect(manager.canPurchase)
    }

    @Test func pendingApprovalArrivesThroughListener() async {
        let store = TestLifetimeStore()
        store.result = .pending
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        session.present(.gradient(.oceanBlue))
        await manager.purchase()
        #expect(manager.isPending)
        #expect(!manager.canPurchase)
        #expect(session.selection == nil)
        store.continuation.yield(.unlocked)
        for _ in 0..<100 where !manager.isUnlocked { await Task.yield() }
        session.reconcileAccess()
        #expect(manager.isUnlocked)
        #expect(!manager.isPending)
        #expect(manager.message == nil)
        #expect(session.selection == .gradient(.oceanBlue))
    }

    @Test func dismissedPaywallCannotOpenAbandonedArtworkAfterApproval() async {
        let store = TestLifetimeStore()
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        session.present(.gradient(.aurora))
        session.dismissPresentation()
        store.continuation.yield(.unlocked)
        for _ in 0..<100 where !manager.isUnlocked { await Task.yield() }
        session.reconcileAccess()
        #expect(manager.isUnlocked)
        #expect(!session.isPresenting)
    }

    @Test func restoredOwnershipResumesTheSelection() async {
        let store = TestLifetimeStore()
        store.restoreAccess = .unlocked
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        session.present(.gradient(.aurora))
        await manager.restore()
        session.reconcileAccess()
        #expect(session.selection == .gradient(.aurora))
        #expect(manager.operation == .idle)
    }

    @Test func restoreWithNoPurchaseExplainsWhatToDo() async {
        let store = TestLifetimeStore()
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        await manager.restore()
        #expect(!manager.isUnlocked)
        #expect(manager.message?.contains("No lifetime purchase") == true)
    }

    @Test func unverifiedPurchaseNeverGrantsAccessOrInvitesASecondCharge() async {
        let store = TestLifetimeStore()
        store.purchaseError = StoreKitLifetimeStore.Failure.verification
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        await manager.purchase()
        #expect(manager.entitlement == .unverified)
        #expect(!manager.canPurchase)
        #expect(manager.message?.contains("Restore Purchase") == true)
    }

    @Test func failedPurchaseCanBeRetried() async {
        let store = TestLifetimeStore()
        store.purchaseError = StoreKitError.networkError(URLError(.notConnectedToInternet))
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        await manager.purchase()
        #expect(!manager.isUnlocked)
        #expect(manager.canPurchase)
        #expect(manager.message?.contains("connection") == true)
        store.purchaseError = nil
        await manager.purchase()
        #expect(manager.isUnlocked)
        #expect(manager.message == nil)
    }

    @Test func operationsAreMutuallyExclusive() async {
        let store = TestLifetimeStore()
        store.suspendPurchase = true
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let first = Task { await manager.purchase() }
        for _ in 0..<100 where store.purchaseContinuation == nil { await Task.yield() }
        await manager.purchase()
        await manager.restore()
        #expect(store.purchaseCalls == 1)
        #expect(store.restoreCalls == 0)
        #expect(manager.isBusy)
        store.purchaseContinuation?.resume()
        await first.value
        #expect(manager.isUnlocked)
        #expect(!manager.isBusy)
    }

    @Test func oldEntitlementReadCannotOverwriteANewPurchase() async {
        let store = TestLifetimeStore()
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        store.suspendEntitlement = true
        let refresh = Task { await manager.refreshEntitlement() }
        for _ in 0..<100 where store.entitlementContinuation == nil { await Task.yield() }
        await manager.purchase()
        store.entitlementContinuation?.resume(returning: .locked)
        await refresh.value
        #expect(manager.isUnlocked)
    }

    @Test func revocationClosesAnOpenViewer() async {
        let store = TestLifetimeStore()
        store.access = .unlocked
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        session.present(.gradient(.aurora))
        store.continuation.yield(.locked)
        for _ in 0..<100 where manager.isUnlocked { await Task.yield() }
        session.reconcileAccess()
        #expect(session.selection == nil)
        #expect(session.isStorePresented)
    }

    @Test func dailyArtworkIsFreeBeforeAndAfterAnUnavailableStoreCheck() async {
        let store = TestLifetimeStore()
        store.offer = nil
        let manager = PurchaseManager(store: store)
        let session = GallerySession(purchases: manager)
        let daily = session.freePainting
        #expect(manager.entitlement == .checking)
        session.present(.painting(daily))
        #expect(session.selection == .painting(daily))
        #expect(!session.isStorePresented)
        await manager.prepare()
        session.reconcileAccess()
        #expect(session.selection == .painting(daily))
        #expect(session.pendingSelection == nil)
        #expect(!session.isStorePresented)
        #expect(!manager.isUnlocked)
        #expect(store.purchaseCalls == 0)
    }

    @Test func onlyTheDailyArtworkIsFreeThroughEveryPaintingLink() async {
        let manager = PurchaseManager(store: TestLifetimeStore())
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        for painting in PaintingData.shared.allPaintings {
            session.open(URL(string: "galleryglow://painting/\(painting.imageName)")!)
            if painting == session.freePainting {
                #expect(session.selection == .painting(painting))
                #expect(!session.isStorePresented)
            } else {
                #expect(session.selection == nil)
                #expect(session.pendingSelection == .painting(painting))
                #expect(session.isStorePresented)
            }
            session.dismissPresentation()
        }
        for palette in GradientPalette.allCases {
            session.present(.gradient(palette))
            #expect(session.selection == nil)
            #expect(session.isStorePresented)
            session.dismissPresentation()
        }
    }

    @Test func dailyAccessRotatesWithoutInterruptingTheOpenArtwork() async throws {
        let manager = PurchaseManager(store: TestLifetimeStore())
        await manager.prepare()
        var now = Date()
        let session = GallerySession(purchases: manager, now: { now })
        let yesterday = session.freePainting
        session.present(.painting(yesterday))
        now = try #require(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let today = session.freePainting
        #expect(today != yesterday)
        session.reconcileAccess()
        #expect(session.selection == .painting(yesterday))
        session.dismissPresentation()
        session.present(.painting(yesterday))
        #expect(session.selection == nil)
        #expect(session.isStorePresented)
        session.present(.painting(today))
        #expect(session.selection == .painting(today))
        #expect(session.pendingSelection == nil)
        #expect(!session.isStorePresented)
        // Switching away from the free session cannot grant access to paid art.
        session.present(.gradient(.aurora))
        #expect(session.selection == nil)
        #expect(session.isStorePresented)
    }

    @Test func aPendingArtworkBecomingDailyNoLongerRequiresPurchase() async throws {
        let store = TestLifetimeStore()
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        var now = Date()
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let session = GallerySession(purchases: manager, now: { now })
        let painting = PaintingData.shared.paintingOfTheDay(on: tomorrow)
        session.present(.painting(painting))
        #expect(session.isStorePresented)
        now = tomorrow
        session.reconcileAccess()
        #expect(session.selection == .painting(painting))
        #expect(session.pendingSelection == nil)
        #expect(!session.isStorePresented)
        #expect(store.purchaseCalls == 0)
    }

    @Test func revocationDoesNotCloseTheFreeDailyArtwork() async {
        let store = TestLifetimeStore()
        store.access = .unlocked
        let manager = PurchaseManager(store: store)
        await manager.prepare()
        let session = GallerySession(purchases: manager)
        let daily = session.freePainting
        session.present(.painting(daily))
        store.continuation.yield(.locked)
        for _ in 0..<100 where manager.isUnlocked { await Task.yield() }
        session.reconcileAccess()
        #expect(!manager.isUnlocked)
        #expect(session.selection == .painting(daily))
        #expect(!session.isStorePresented)
    }
}

@MainActor
private final class TestLifetimeStore: LifetimeStore {
    let updates: AsyncStream<GalleryEntitlement>
    let continuation: AsyncStream<GalleryEntitlement>.Continuation
    var offer: LifetimeOffer? = .init(displayPrice: "$9.99", familyShareable: true)
    var access: GalleryEntitlement = .locked
    var restoreAccess: GalleryEntitlement = .locked
    var result: StorePurchaseResult = .purchased
    var purchaseError: Error?
    var purchaseCalls = 0
    var restoreCalls = 0
    var suspendPurchase = false
    var suspendEntitlement = false
    var purchaseContinuation: CheckedContinuation<Void, Never>?
    var entitlementContinuation: CheckedContinuation<GalleryEntitlement, Never>?
    init() { (updates, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1)) }
    func loadOffer() async throws -> LifetimeOffer? { offer }
    func entitlement() async -> GalleryEntitlement {
        if suspendEntitlement { return await withCheckedContinuation { entitlementContinuation = $0 } }
        return access
    }
    func purchase() async throws -> StorePurchaseResult {
        purchaseCalls += 1
        if suspendPurchase { await withCheckedContinuation { purchaseContinuation = $0 } }
        if let purchaseError { throw purchaseError }
        return result
    }
    func restore() async throws {
        restoreCalls += 1
        access = restoreAccess
    }
}
