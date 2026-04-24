//
//  DecisionsView.swift
//  quietly
//
//  Tab 2: Decisions - Active and archived decisions.
//

import SwiftUI
import CoreData

struct DecisionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entitlements = EntitlementsManager.shared

    @State private var selectedSegment: DecisionSegment = .active
    @State private var showScenarioCreator: Bool = false
    @State private var showPaywall: Bool = false
    @State private var selectedDecision: Decision?
    @State private var decisionToDelete: Decision?
    @State private var showDeleteConfirmation: Bool = false

    enum DecisionSegment: String, CaseIterable {
        case active = "Active"
        case archived = "Archived"
    }

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Decision.createdAt, ascending: false)],
        predicate: NSPredicate(format: "status == %@", "active"),
        animation: .default
    ) private var activeDecisions: FetchedResults<Decision>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Decision.resolvedAt, ascending: false)],
        predicate: NSPredicate(format: "status == %@", "archived"),
        animation: .default
    ) private var archivedDecisions: FetchedResults<Decision>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Fixed header area
                VStack(spacing: 0) {
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    segmentedPicker
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
                .background(QuietlyColors.background)

                if !entitlements.isPro {
                    paywallCard
                } else {
                    decisionList
                }
            }
            .background(QuietlyColors.background.ignoresSafeArea())
            .sheet(isPresented: $showScenarioCreator) { ScenarioCreatorView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .navigationDestination(item: $selectedDecision) { DecisionDetailView(decision: $0) }
            .alert("Delete Decision?", isPresented: $showDeleteConfirmation, presenting: decisionToDelete) { decision in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteDecision(decision) }
            } message: { decision in
                Text("\"\(decision.question ?? "This decision")\" will be permanently deleted.")
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Decisions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                Text("Close the loops.")
                    .font(.system(size: 15))
                    .foregroundColor(QuietlyColors.mutedText)
            }
            Spacer()
            Button(action: { showScenarioCreator = true }) {
                ZStack {
                    Circle()
                        .fill(QuietlyColors.green)
                        .frame(width: 42, height: 42)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Segment Picker
    private var segmentedPicker: some View {
        HStack(spacing: 0) {
            ForEach(DecisionSegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSegment = segment }
                } label: {
                    VStack(spacing: 6) {
                        Text(segment.rawValue)
                            .font(.system(size: 15, weight: selectedSegment == segment ? .bold : .regular))
                            .foregroundColor(QuietlyColors.primaryBlue)
                        Rectangle()
                            .fill(selectedSegment == segment
                                  ? QuietlyColors.primaryBlue
                                  : QuietlyColors.primaryBlue.opacity(0.15))
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Decision List
    private var decisionList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                let decisions = selectedSegment == .active
                    ? Array(activeDecisions)
                    : Array(archivedDecisions)

                if decisions.isEmpty {
                    emptyState
                } else {
                    ForEach(decisions) { decision in
                        if selectedSegment == .active {
                            activeDecisionCard(decision)
                        } else {
                            archivedDecisionCard(decision)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Active Decision Card
    private func activeDecisionCard(_ decision: Decision) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Question — tappable for detail
            HStack(alignment: .top, spacing: 0) {
                Button(action: { selectedDecision = decision }) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(decision.question ?? "Untitled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(QuietlyColors.darkText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)

                        if decision.isLockedPreview && !entitlements.isPro {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text("Pro analysis available")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(QuietlyColors.primaryBlue)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(QuietlyColors.primaryBlue.opacity(0.08))
                            .cornerRadius(8)
                        }
                    }
                }
                .buttonStyle(.plain)

                Button(action: { decisionToDelete = decision; showDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(Color.red.opacity(0.5))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Options
            let hasA = !(decision.optionA ?? "").isEmpty
            let hasB = !(decision.optionB ?? "").isEmpty

            if hasA || hasB {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    if hasA {
                        optionRow(text: decision.optionA!) {
                            resolveDecision(decision, chosenOption: decision.optionA!)
                        }
                    }

                    if hasA && hasB {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 1)
                            Text("OR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(QuietlyColors.mutedText)
                                .fixedSize()
                            Rectangle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 16)
                    }

                    if hasB {
                        optionRow(text: decision.optionB!) {
                            resolveDecision(decision, chosenOption: decision.optionB!)
                        }
                    }
                }
            }

            // Footer hint
            HStack {
                Image(systemName: "hand.tap")
                    .font(.system(size: 10))
                Text("Tap question to view details")
                    .font(.system(size: 11))
            }
            .foregroundColor(QuietlyColors.mutedText.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
        .accessibilityLabel("Decision: \(decision.question ?? "Untitled")")
    }

    private func optionRow(text: String, onDecide: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Archived Decision Card
    private func archivedDecisionCard(_ decision: Decision) -> some View {
        HStack(spacing: 14) {
            Button(action: { selectedDecision = decision }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(QuietlyColors.green.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(QuietlyColors.green)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(decision.question ?? "Untitled")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(QuietlyColors.darkText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if let resolvedAt = decision.resolvedAt {
                            Text("Resolved \(resolvedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 12))
                                .foregroundColor(QuietlyColors.mutedText)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(QuietlyColors.mutedText)
                }
            }
            .buttonStyle(.plain)

            Button(action: { decisionToDelete = decision; showDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(Color.red.opacity(0.5))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.primaryBlue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "scale.3d")
                    .font(.system(size: 32))
                    .foregroundColor(QuietlyColors.primaryBlue.opacity(0.5))
            }
            Text(selectedSegment == .active ? "No active decisions" : "No archived decisions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(QuietlyColors.primaryBlue)
            Text(selectedSegment == .active
                 ? "Decisions extracted from your brain dumps will appear here."
                 : "Decisions you've resolved will show up here.")
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.mutedText)
                .multilineTextAlignment(.center)
            if selectedSegment == .active {
                Button(action: { showScenarioCreator = true }) {
                    Text("Create a decision")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(QuietlyColors.green)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
    }

    // MARK: - Paywall Card (free users)
    private var paywallCard: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Unlock Decisions with Pro")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Text("Only Pro subscribers have access to Decisions. Upgrade to continue.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 10) {
                        Button(action: { showPaywall = true }) {
                            Text("Upgrade to Pro")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(QuietlyColors.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(QuietlyColors.green)
                                .cornerRadius(26)
                        }
                        .buttonStyle(.plain)

                        Button(action: {}) {
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
                        .buttonStyle(.plain)
                    }
                }
                .padding(28)
                .background(QuietlyColors.primaryBlue)
                .cornerRadius(24)
                .shadow(color: QuietlyColors.primaryBlue.opacity(0.3), radius: 20, x: 0, y: 8)
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Delete Decision
    private func deleteDecision(_ decision: Decision) {
        withAnimation {
            viewContext.delete(decision)
            try? viewContext.save()
        }
    }

    // MARK: - Resolve Decision
    private func resolveDecision(_ decision: Decision, chosenOption: String) {
        withAnimation {
            decision.status = "archived"
            decision.resolvedAt = Date()
            decision.analysis = "Decided: \(chosenOption)"
            try? viewContext.save()
        }
    }
}

#Preview {
    DecisionsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
