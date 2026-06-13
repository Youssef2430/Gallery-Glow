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

    @State private var isPurchasing = false
    @State private var statusMessage: String?

    init(onUnlocked: @escaping () -> Void = {}) {
        self.onUnlocked = onUnlocked
    }

    var body: some View {
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

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Gallery Glow Lifetime")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Unlock every painting, animated gradient, Top Shelf deep link, and future gallery update with one purchase.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 18) {
                    Label("One-time purchase", systemImage: "checkmark.seal.fill")
                    Label("Family Sharing ready", systemImage: "person.2.fill")
                    Label("Restore anytime", systemImage: "arrow.clockwise")
                }
                .font(.callout)
                .lineLimit(1)
                .fixedSize()
                .foregroundColor(.secondary)

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

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isPurchasing || purchaseManager.isLoadingProducts || purchaseManager.lifetimeProduct == nil)

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
                    .disabled(isPurchasing || purchaseManager.isRestoring)

                    Button("Maybe Later") {
                        dismiss()
                    }
                    .disabled(isPurchasing || purchaseManager.isRestoring)
                }
                .buttonStyle(.borderedProminent)

                // Always present so the sheet reserves space for the status
                // line; the card does not grow once it is presented.
                Text(statusMessage ?? purchaseManager.statusMessage ?? " ")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 64)
            .padding(.vertical, 44)
        }
        // The tvOS sheet card sizes itself unreliably as async state changes
        // the content height; pin the card so the padding stays symmetric.
        .frame(width: 1100, height: 840)
        .task {
            await purchaseManager.prepareForStore()
        }
    }

    private var primaryButtonTitle: String {
        if purchaseManager.isLoadingProducts {
            return "Loading Lifetime Unlock"
        }

        return "Unlock Lifetime - \(purchaseManager.lifetimeDisplayPrice)"
    }

    private func purchase() {
        guard !isPurchasing else { return }

        isPurchasing = true
        statusMessage = nil

        Task {
            let outcome = await purchaseManager.purchaseLifetime()

            await MainActor.run {
                isPurchasing = false

                switch outcome {
                case .success, .restored:
                    onUnlocked()
                    dismiss()
                case .pending:
                    statusMessage = "Purchase is pending approval."
                case .cancelled:
                    statusMessage = nil
                case .failed(let message):
                    statusMessage = message
                }
            }
        }
    }

    private func restore() {
        statusMessage = nil

        Task {
            let outcome = await purchaseManager.restorePurchases()

            await MainActor.run {
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
}

struct PurchaseBanner: View {
    let price: String
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

                Text(isLoading ? "Loading" : price)
                    .font(.headline)
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.card)
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager(startsTransactionListener: false))
}
