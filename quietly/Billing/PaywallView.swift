//
//  PaywallView.swift
//  quietly
//
//  Pro upgrade paywall UI.
//

import SwiftUI

struct PaywallView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    @Environment(\.dismiss) private var dismiss

    var onUnlock: (() -> Void)? = nil

    var body: some View {
        ZStack {
            QuietlyColors.primaryBlue.ignoresSafeArea()

            VStack(spacing: 0) {
                // Dismiss handle
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, 32)

                Spacer()

                // Lock icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)

                // Headline
                Text("Unlock Quietly Pro")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)

                Text("Everything you need to clear your mind,\nmake decisions, and track what matters.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 36)

                // Features
                VStack(spacing: 14) {
                    ProFeatureRow(icon: "brain.head.profile", text: "Unlimited brain dumps")
                    ProFeatureRow(icon: "questionmark.bubble.fill", text: "Full decision breakdowns")
                    ProFeatureRow(icon: "chart.bar.fill", text: "Complete insights & trends")
                    ProFeatureRow(icon: "icloud.fill", text: "Optional cloud sync")
                    ProFeatureRow(icon: "square.and.arrow.up", text: "Export your data")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        entitlements.unlockPro()
                        onUnlock?()
                        dismiss()
                    }) {
                        Text("Upgrade to Pro")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(QuietlyColors.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(QuietlyColors.green)
                            .cornerRadius(27)
                    }

                    Button(action: { dismiss() }) {
                        Text("Maybe later")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
