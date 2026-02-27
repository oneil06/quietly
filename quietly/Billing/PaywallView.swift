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
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Go Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "brain.head.profile", text: "Unlimited clears")
                    FeatureRow(icon: "questionmark.bubble", text: "Decision breakdowns")
                    FeatureRow(icon: "chart.bar", text: "Full insights")
                    FeatureRow(icon: "icloud", text: "Optional cloud sync")
                    FeatureRow(icon: "square.and.arrow.up", text: "Export your data")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        entitlements.unlockPro()
                        onUnlock?()
                        dismiss()
                    }) {
                        Text("Start Pro")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Not now")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(QuietlyColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
}
