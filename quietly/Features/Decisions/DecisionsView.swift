//
//  DecisionsView.swift
//  quietly
//
//  Tab 2: Decisions - Active and archived decisions.
//

import SwiftUI
import CoreData
import CoreData

struct DecisionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entitlements = EntitlementsManager.shared
    
    @State private var selectedSegment: DecisionSegment = .active
    @State private var showScenarioCreator: Bool = false
    @State private var showPaywall: Bool = false
    @State private var selectedDecision: Decision?
    
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
                // Header
                headerView
                
                // Segment Picker
                Picker("Status", selection: $selectedSegment) {
                    ForEach(DecisionSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, QuietlySpacing.outerPadding)
                .padding(.top, 8)
                
                // List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if selectedSegment == .active {
                            ForEach(activeDecisions) { decision in
                                decisionCard(decision: decision)
                            }
                        } else {
                            ForEach(archivedDecisions) { decision in
                                archivedDecisionCard(decision: decision)
                            }
                        }
                        
                        if (selectedSegment == .active && activeDecisions.isEmpty) ||
                           (selectedSegment == .archived && archivedDecisions.isEmpty) {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, QuietlySpacing.outerPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(QuietlyColors.pageBackground)
            .sheet(isPresented: $showScenarioCreator) {
                ScenarioCreatorView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .navigationDestination(item: $selectedDecision) { decision in
                DecisionDetailView(decision: decision)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Decisions")
                    .font(QuietlyTypography.title)
                
                Text("Close the loops.")
                    .font(QuietlyTypography.body)
                    .foregroundColor(QuietlyColors.secondaryText)
            }
            
            Spacer()
            
            Button(action: { showScenarioCreator = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, QuietlySpacing.outerPadding)
        .padding(.top, 8)
    }
    
    // MARK: - Decision Card
    private func decisionCard(decision: Decision) -> some View {
        Button(action: {
            if entitlements.canViewDecisionDetails() {
                selectedDecision = decision
            } else {
                showPaywall = true
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(decision.question ?? "Untitled")
                    .font(QuietlyTypography.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack {
                    if decision.optionA != nil || decision.optionB != nil {
                        Text("Has options")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if decision.isLockedPreview && !entitlements.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Needs attention")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardFill)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Decision: \(decision.question ?? "Untitled")")
    }
    
    // MARK: - Archived Decision Card
    private func archivedDecisionCard(decision: Decision) -> some View {
        Button(action: {
            selectedDecision = decision
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(decision.question ?? "Untitled")
                    .font(QuietlyTypography.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let resolvedAt = decision.resolvedAt {
                    Text("Resolved \(resolvedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(QuietlyColors.secondaryText)
                }
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardFill)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.hexagonpath")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text(selectedSegment == .active ? "No active decisions" : "No archived decisions")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.secondaryText)
            
            if selectedSegment == .active {
                Button(action: { showScenarioCreator = true }) {
                    Text("Create a decision")
                        .font(.callout)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(32)
    }
}

#Preview {
    DecisionsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
