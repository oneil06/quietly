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
            VStack(spacing: QuietlySpacing.sectionSpacing) {
                // Question Section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Question")
                    
                    Text(decision.question ?? "Untitled")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(QuietlyColors.cardTextDark)
                        .padding(QuietlySpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(QuietlyColors.cardBackground)
                        .cornerRadius(12)
                }
                
                // Analysis Section (Pro locked for free users)
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "What seems to matter")
                    
                    if decision.isLockedPreview && !entitlements.isPro {
                        lockedContentView
                    } else {
                        analysisContent
                    }
                }
                
                // Option A
                if let optionA = decision.optionA, !optionA.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Option A")
                        
                        Text(optionA)
                            .font(QuietlyTypography.body)
                            .foregroundColor(QuietlyColors.cardTextDark)
                            .padding(QuietlySpacing.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(QuietlyColors.cardBackground)
                            .cornerRadius(12)
                    }
                }
                
                // Option B
                if let optionB = decision.optionB, !optionB.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Option B")
                        
                        Text(optionB)
                            .font(QuietlyTypography.body)
                            .foregroundColor(QuietlyColors.cardTextDark)
                            .padding(QuietlySpacing.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(QuietlyColors.cardBackground)
                            .cornerRadius(12)
                    }
                }
                
                // Suggested Next Step (Pro)
                if entitlements.isPro {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Suggested Next Step")
                        
                        Text(decision.suggestedNextStep ?? "No suggestion available")
                            .font(QuietlyTypography.body)
                            .foregroundColor(QuietlyColors.cardTextDark)
                            .padding(QuietlySpacing.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(QuietlyColors.cardBackground)
                            .cornerRadius(12)
                    }
                }
                
                // Resolution Message
                if showResolutionMessage {
                    rememberMessageCard
                }
                
                // Mark as Resolved Button
                if decision.status == "active" {
                    Button(action: markAsResolved) {
                        Text("Mark as Resolved")
                            .font(.headline)
                            .foregroundColor(QuietlyColors.headingWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(QuietlyColors.appBlue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                
                // Reopen Button (for archived)
                if decision.status == "archived" {
                    Button(action: reopenDecision) {
                        Text("Reopen Decision")
                            .font(.headline)
                            .foregroundColor(QuietlyColors.cardTextDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(QuietlyColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, QuietlySpacing.outerPadding)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(QuietlyColors.quietPageBackground)
        .navigationTitle("Decision")
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Analysis Content
    private var analysisContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sample analysis - in production this would come from extraction
            Text("• Consider the long-term implications")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.cardTextDark)
            Text("• Think about your current priorities")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.cardTextDark)
            Text("• Trust your gut feeling")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.cardTextDark)
        }
        .padding(QuietlySpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(QuietlyColors.cardBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Locked Content
    private var lockedContentView: some View {
        ZStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text("• Consider the trade-offs")
                    .font(QuietlyTypography.body)
                    .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                Text("• Think about timing")
                    .font(QuietlyTypography.body)
                    .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
            }
            .blur(radius: 3)
            .padding(QuietlySpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
            
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(QuietlyColors.cardTextDark)
                Text("Unlock Pro to see analysis")
                    .font(.callout)
                    .foregroundColor(QuietlyColors.cardTextDark)
                Button("Unlock Pro") {
                    showPaywall = true
                }
                .font(.callout)
                .foregroundColor(QuietlyColors.appBlue)
            }
            .padding(24)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Remember Message
    private var rememberMessageCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.title2)
                .foregroundColor(QuietlyColors.cardTextDark)
            
            Text("Remember…")
                .font(.headline)
                .foregroundColor(QuietlyColors.cardTextDark)
            
            Text("Most decisions aren't permanent. You can adjust your path as you learn more.")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.cardTextDark.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Actions
    private func markAsResolved() {
        withAnimation {
            decision.status = "archived"
            decision.resolvedAt = Date()
            
            try? viewContext.save()
            
            withAnimation {
                showResolutionMessage = true
            }
            
            // Delay then dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }
    
    private func reopenDecision() {
        withAnimation {
            decision.status = "active"
            decision.resolvedAt = nil
            
            try? viewContext.save()
        }
    }
}

#Preview {
    NavigationStack {
        DecisionDetailView(decision: Decision())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
