//
//  DecisionDetailView.swift
//  quietly
//
//  Decision detail screen with analysis and resolution.
//

import SwiftUI
import CoreData

struct DecisionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entitlements = EntitlementsManager.shared

    @ObservedObject var decision: Decision

    @State private var showResolutionMessage: Bool = false
    @State private var showPaywall: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                questionCard
                optionsCard
                analysisCard
                if entitlements.isPro { nextStepCard }
                if showResolutionMessage { resolutionCard }
                actionButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(QuietlyColors.background.ignoresSafeArea())
        .navigationTitle("Decision")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Question Card
    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("The Question", icon: "questionmark.circle.fill", color: QuietlyColors.primaryBlue)

            Text(decision.question ?? "Untitled")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(QuietlyColors.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    // MARK: - Options Card
    @ViewBuilder
    private var optionsCard: some View {
        let hasA = !(decision.optionA ?? "").isEmpty
        let hasB = !(decision.optionB ?? "").isEmpty

        if hasA || hasB {
            VStack(alignment: .leading, spacing: 12) {
                label("Your Options", icon: "arrow.left.arrow.right", color: Color(hex: "6B7AE8"))

                if hasA {
                    optionBlock(letter: "A", text: decision.optionA!, canDecide: decision.status == "active") {
                        resolveDecision(chosenOption: decision.optionA!)
                    }
                }

                if hasA && hasB {
                    HStack(spacing: 8) {
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 1)
                        Text("OR")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(QuietlyColors.mutedText)
                            .fixedSize()
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(height: 1)
                    }
                }

                if hasB {
                    optionBlock(letter: "B", text: decision.optionB!, canDecide: decision.status == "active") {
                        resolveDecision(chosenOption: decision.optionB!)
                    }
                }
            }
            .card()
        }
    }

    private func optionBlock(letter: String, text: String, canDecide: Bool, onDecide: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.primaryBlue.opacity(0.1))
                    .frame(width: 32, height: 32)
                Text(letter)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if canDecide {
                Button(action: onDecide) {
                    Text("Decide")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(QuietlyColors.green)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(QuietlyColors.primaryBlue.opacity(0.04))
        .cornerRadius(14)
    }

    // MARK: - Analysis Card
    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("What Seems to Matter", icon: "brain.head.profile", color: Color(hex: "FF9500"))

            if decision.isLockedPreview && !entitlements.isPro {
                lockedAnalysis
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    analysisPoint("Consider the long-term implications of each path.")
                    analysisPoint("Think about what aligns with your current priorities.")
                    analysisPoint("Trust your instincts — they often carry real data.")
                }
            }
        }
        .card()
    }

    private func analysisPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(QuietlyColors.primaryBlue)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.darkText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var lockedAnalysis: some View {
        VStack(spacing: 14) {
            ZStack {
                VStack(alignment: .leading, spacing: 10) {
                    analysisPoint("Consider the trade-offs of each option.")
                    analysisPoint("Think about timing and context.")
                }
                .blur(radius: 4)
                .allowsHitTesting(false)
            }

            Button(action: { showPaywall = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill").font(.system(size: 12))
                    Text("Unlock Pro to see full analysis")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(QuietlyColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(QuietlyColors.primaryBlue.opacity(0.08))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Next Step Card
    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Suggested Next Step", icon: "arrow.right.circle.fill", color: QuietlyColors.green)

            Text(decision.suggestedNextStep ?? "Take a day to reflect before making a final call.")
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    // MARK: - Resolution Card
    private var resolutionCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.green.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(QuietlyColors.primaryBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Decision made.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(QuietlyColors.darkText)
                Text("Most decisions aren't permanent. You can always revisit.")
                    .font(.system(size: 13))
                    .foregroundColor(QuietlyColors.mutedText)
            }
        }
        .card()
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Action Button
    @ViewBuilder
    private var actionButton: some View {
        if decision.status == "active" {
            Button(action: markAsResolved) {
                Text("Mark as Resolved")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(QuietlyColors.green)
                    .cornerRadius(27)
            }
            .padding(.top, 4)
        } else {
            Button(action: reopenDecision) {
                Text("Reopen Decision")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(27)
                    .overlay(
                        RoundedRectangle(cornerRadius: 27)
                            .stroke(QuietlyColors.primaryBlue.opacity(0.3), lineWidth: 1.5)
                    )
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers
    private func label(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuietlyColors.mutedText)
        }
    }

    // MARK: - Actions
    private func markAsResolved() {
        withAnimation(.easeInOut(duration: 0.3)) {
            decision.status = "archived"
            decision.resolvedAt = Date()
            try? viewContext.save()
            showResolutionMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { dismiss() }
    }

    private func resolveDecision(chosenOption: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            decision.status = "archived"
            decision.resolvedAt = Date()
            decision.analysis = "Decided: \(chosenOption)"
            try? viewContext.save()
            showResolutionMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { dismiss() }
    }

    private func reopenDecision() {
        withAnimation {
            decision.status = "active"
            decision.resolvedAt = nil
            try? viewContext.save()
        }
    }
}

// MARK: - Card Modifier
private extension View {
    func card() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        DecisionDetailView(decision: Decision())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
