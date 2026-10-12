import SwiftUI

struct PaywallView: View {
    let purchases: PurchaseManager
    let painting: Painting
    let onClose: () -> Void
    @FocusState private var focusedAction: Action?
    private enum Action { case purchase, restore, close }

    private var primaryTitle: String {
        if purchases.operation == .purchasing { return "Confirm on the App Store…" }
        if purchases.isPending { return "Awaiting approval" }
        if purchases.entitlement == .checking { return "Checking your purchases…" }
        if purchases.entitlement == .unverified { return "Restore to verify purchase" }
        if purchases.isLoadingOffer { return "Loading price…" }
        if let offer = purchases.offer { return "Unlock lifetime  ·  \(offer.displayPrice)" }
        return "Try loading price again"
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 64) {
                artworkPanel
                    .frame(width: geometry.size.width * 0.41)
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack {
                            GalleryEyebrow("Gallery Glow / Lifetime")
                            Spacer()
                            Image(systemName: "checkmark.seal").font(.system(size: 26))
                        }
                        GalleryRule()
                        Text(purchases.isUnlocked ? "The gallery\nis yours." : "Great art.\nYours to keep.")
                            .font(GalleryTheme.display(66))
                            .tracking(-2).lineSpacing(-4)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("paywall-title")
                        Text(purchases.isUnlocked
                             ? "Your lifetime pass is active. Enjoy every work in the collection."
                             : "Every artwork, every day.\nOne purchase. No subscription.")
                            .font(.system(size: 25)).lineSpacing(5)
                            .foregroundStyle(GalleryTheme.secondary)

                        VStack(alignment: .leading, spacing: 17) {
                            benefit("Every painting, beautifully full screen", icon: "rectangle.inset.filled")
                            benefit("Five living, ambient color scenes", icon: "circle.lefthalf.filled")
                            benefit("Future additions to the collection", icon: "square.grid.2x2")
                            if purchases.offer?.familyShareable == true {
                                benefit("Share with your family through Apple", icon: "person.2")
                            }
                        }
                        .padding(.vertical, 3)
                        GalleryRule()

                        if purchases.isUnlocked {
                            Button(action: onClose) {
                                Label("Return to the gallery", systemImage: "arrow.right")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GalleryButtonStyle(prominent: true))
                            .focused($focusedAction, equals: .close)
                            .accessibilityIdentifier("paywall-done")
                        } else {
                            Button {
                                Task {
                                    if purchases.entitlement == .unverified { await purchases.restore() }
                                    else if purchases.offer == nil { await purchases.loadOffer() }
                                    else { await purchases.purchase() }
                                }
                            } label: {
                                HStack(spacing: 15) {
                                    if purchases.isBusy || purchases.isLoadingOffer || purchases.entitlement == .checking {
                                        ProgressView().tint(GalleryTheme.onAccent)
                                    }
                                    Text(primaryTitle).font(.system(size: 24, weight: .medium))
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.up.right")
                                }
                            }
                            .buttonStyle(GalleryButtonStyle(prominent: true))
                            .disabled(purchases.isBusy || purchases.isLoadingOffer || purchases.isPending || purchases.entitlement == .checking)
                            .focused($focusedAction, equals: .purchase)
                            .accessibilityIdentifier("unlockLifetimeButton")
                            HStack(spacing: 26) {
                                Button {
                                    Task { await purchases.restore() }
                                } label: {
                                    Text(purchases.operation == .restoring ? "Restoring…" : "Restore Purchase")
                                        .font(.system(size: 21))
                                }
                                .disabled(purchases.isBusy)
                                .focused($focusedAction, equals: .restore)
                                .accessibilityIdentifier("restorePurchaseButton")
                                Button("Keep browsing", action: onClose)
                                    .font(.system(size: 21))
                                    .focused($focusedAction, equals: .close)
                                    .accessibilityIdentifier("paywall-close")
                            }
                            .buttonStyle(GalleryButtonStyle())
                        }

                        Text(purchases.message ?? (purchases.isUnlocked ? "Lifetime access · Purchased with your Apple Account" : purchases.offerError ?? "Secure payment with Apple. Restore anytime with the same Apple Account."))
                            .font(.system(size: 19)).lineSpacing(4)
                            .foregroundStyle(GalleryTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 52, alignment: .topLeading)
                            .accessibilityIdentifier("paywallStatusLabel")
                    }
                    .padding(34)
                }
                .background(GalleryTheme.surface, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
                .scrollClipDisabled()
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 36)
        }
        .background(GalleryTheme.paper.ignoresSafeArea())
        .foregroundStyle(GalleryTheme.ink)
        .defaultFocus($focusedAction, .purchase)
        .task {
            await purchases.prepare()
            focusedAction = purchases.isUnlocked ? .close : (purchases.isPending ? .restore : .purchase)
        }
        .onChange(of: purchases.isUnlocked) { _, unlocked in
            if unlocked { focusedAction = .close }
        }
        .onExitCommand(perform: onClose)
    }

    private var artworkPanel: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text("GALLERY GLOW").font(GalleryTheme.wordmark(40)).tracking(-1)
                Spacer()
                GalleryBrandIcon(size: 48)
            }
            Spacer(minLength: 0)
            FramedPainting(painting: painting)
                .frame(height: 510)
                .accessibilityHidden(true)
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(painting.title).font(GalleryTheme.display(30))
                    Text(painting.artistName).font(.system(size: 20)).foregroundStyle(GalleryTheme.secondary)
                }
                Spacer()
                Text(String(painting.year)).font(.system(size: 20))
                    .padding(.horizontal, 18).padding(.vertical, 11)
                    .background(GalleryTheme.surface, in: Capsule())
            }
            Spacer(minLength: 0)
            Text("A lifetime of looking.").font(GalleryTheme.display(25))
                .foregroundStyle(GalleryTheme.secondary)
        }
    }

    private func benefit(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon).font(.system(size: 22))
    }
}
