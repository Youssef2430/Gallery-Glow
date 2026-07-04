//
//  PaywallView.swift
//  Gallery Glow
//
//  Created by Codex on 2026-06-06.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let onUnlocked: () -> Void

    private enum FocusTarget: Hashable {
        case purchase
        case restore
        case later
    }

    @State private var isPurchasing = false
    @State private var statusMessage: String?
    @FocusState private var focusedButton: FocusTarget?

    init(onUnlocked: @escaping () -> Void = {}) {
        self.onUnlocked = onUnlocked
    }

    private var isBusy: Bool {
        isPurchasing || purchaseManager.isRestoring
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < 700
            let horizontalPadding: CGFloat = isCompact ? 24 : 64
            let verticalPadding: CGFloat = isCompact ? 28 : 44

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.04, blue: 0.05),
                        Color(red: 0.12, green: 0.10, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: isCompact ? 18 : 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Gallery Glow Lifetime")
                                .font(isCompact ? .title : .largeTitle)
                                .fontWeight(.bold)

                            Text("Unlock every painting, animated gradient, Top Shelf deep link, and future gallery update with one purchase.")
                                .font(isCompact ? .body : .title3)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        benefits(isCompact: isCompact)

                        VStack(alignment: .leading, spacing: 14) {
                            Button(action: purchase) {
                                HStack(spacing: 16) {
                                    if isPurchasing || purchaseManager.isLoadingProducts {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "sparkles")
                                    }

                                    Text(primaryButtonTitle)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.78)
                                        .contentTransition(.opacity)

                                    Spacer(minLength: 12)

                                    Image(systemName: "chevron.right")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(isBusy)
                            .focused($focusedButton, equals: .purchase)
                            .accessibilityIdentifier("unlockLifetimeButton")

                            Button(action: restore) {
                                HStack(spacing: 16) {
                                    if purchaseManager.isRestoring {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }

                                    Text("Restore Purchase")
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .disabled(isBusy)
                            .focused($focusedButton, equals: .restore)

                            Button("Maybe Later") {
                                dismiss()
                            }
                            .disabled(isBusy)
                            .focused($focusedButton, equals: .later)
                        }
                        .buttonStyle(.borderedProminent)

                        // Reserves two lines so the card never resizes when a
                        // status message appears or grows.
                        Text(statusMessage ?? purchaseManager.statusMessage ?? "")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .lineLimit(2, reservesSpace: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("paywallStatusLabel")
                    }
                    .frame(maxWidth: 920, alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPurchasing)
            .animation(.easeInOut(duration: 0.2), value: purchaseManager.isLoadingProducts)
        }
        // Keep the tvOS card stable, while still allowing compact touch
        // presentations to fit and scroll instead of clipping the CTA.
        .frame(minWidth: 320, idealWidth: 1100, maxWidth: 1100, minHeight: 480, idealHeight: 840, maxHeight: 840)
        .defaultFocus($focusedButton, .purchase)
        .task {
            await purchaseManager.prepareForStore()
        }
    }

    private var primaryButtonTitle: String {
        if isPurchasing {
            return "Unlocking…"
        }

        if let price = purchaseManager.lifetimeDisplayPrice {
            return "Unlock Lifetime – \(price)"
        }

        return purchaseManager.isLoadingProducts ? "Loading Price…" : "Unlock Lifetime"
    }

    @ViewBuilder
    private func benefits(isCompact: Bool) -> some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 10) {
                benefitLabel("One-time purchase", systemImage: "checkmark.seal.fill")
                benefitLabel("Family Sharing", systemImage: "person.2.fill")
                benefitLabel("Restore anytime", systemImage: "arrow.clockwise")
            }
            .font(.callout)
            .foregroundColor(.secondary)
        } else {
            HStack(spacing: 18) {
                benefitLabel("One-time purchase", systemImage: "checkmark.seal.fill")
                benefitLabel("Family Sharing", systemImage: "person.2.fill")
                benefitLabel("Restore anytime", systemImage: "arrow.clockwise")
            }
            .font(.callout)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundColor(.secondary)
        }
    }

    private func benefitLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
    }

    private func purchase() {
        guard !isPurchasing else { return }

        isPurchasing = true
        statusMessage = nil

        Task {
            let outcome = await purchaseManager.purchaseLifetime()
            isPurchasing = false

            switch outcome {
            case .success, .restored:
                onUnlocked()
                dismiss()
            case .pending:
                statusMessage = "Purchase is awaiting approval. Everything unlocks automatically once it's approved."
            case .cancelled:
                statusMessage = nil
            case .failed(let message):
                statusMessage = message
            }
        }
    }

    private func restore() {
        statusMessage = nil

        Task {
            let outcome = await purchaseManager.restorePurchases()

            switch outcome {
            case .success, .restored:
                onUnlocked()
                dismiss()
            case .pending:
                statusMessage = "Restore is already in progress."
            case .cancelled:
                statusMessage = nil
            case .failed(let message):
                statusMessage = message
            }
        }
    }
}

struct PurchaseBanner: View {
    let price: String?
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Gallery Glow Lifetime")
                        .font(.headline)

                    Text("Full-screen art, animated gradients, and Top Shelf playback.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else if let price {
                    Text(price)
                        .font(.headline)
                        .monospacedDigit()
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.card)
        .accessibilityIdentifier("purchaseBannerButton")
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager(startsTransactionListener: false))
}
