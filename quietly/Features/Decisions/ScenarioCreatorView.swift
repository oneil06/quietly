//
//  ScenarioCreatorView.swift
//  quietly
//
//  Create new decisions with Split or Explain modes.
//

import SwiftUI
import CoreData

struct ScenarioCreatorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entitlements = EntitlementsManager.shared
    
    @State private var mode: CreatorMode = .split
    @State private var optionA: String = ""
    @State private var optionB: String = ""
    @State private var explanation: String = ""
    @State private var showPaywall: Bool = false
    
    enum CreatorMode: String, CaseIterable {
        case split = "Split"
        case explain = "Explain"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                QuietlyColors.appBlue
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Mode Picker
                    Picker("Mode", selection: $mode) {
                        ForEach(CreatorMode.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                                .foregroundColor(QuietlyColors.cardTextDark)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, QuietlySpacing.outerPadding)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Content Card Container
                            VStack(spacing: 16) {
                                if mode == .split {
                                    splitModeView
                                } else {
                                    explainModeView
                                }
                            }
                            .padding(QuietlySpacing.cardPadding)
                            .background(QuietlyColors.cardBackground)
                            .cornerRadius(20)
                            
                            // Analyze Button
                            Button(action: createDecision) {
                                Text("Analyze")
                                    .font(.headline)
                                    .foregroundColor(QuietlyColors.headingWhite)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(canCreate ? QuietlyColors.appBlue : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!canCreate)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, QuietlySpacing.outerPadding)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("New Decision")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(QuietlyColors.headingWhite)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Split Mode
    private var splitModeView: some View {
        VStack(spacing: 12) {
            TextField("Option A", text: $optionA, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(10)
                .foregroundColor(QuietlyColors.cardTextDark)
                .lineLimit(3...6)
                .minimumScaleFactor(0.8)
            
            Text("OR")
                .font(.headline)
                .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                .padding(.vertical, 8)
            
            TextField("Option B", text: $optionB, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(10)
                .foregroundColor(QuietlyColors.cardTextDark)
                .lineLimit(3...6)
                .minimumScaleFactor(0.8)
        }
    }
    
    // MARK: - Explain Mode
    private var explainModeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Describe your situation")
                .font(QuietlyTypography.sectionHeader)
                .foregroundColor(QuietlyColors.cardTextDark)
            
            TextField("What's on your mind?", text: $explanation, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(10)
                .foregroundColor(QuietlyColors.cardTextDark)
                .lineLimit(6...12)
                .minimumScaleFactor(0.7)
        }
    }
    
    // MARK: - Computed
    private var canCreate: Bool {
        if mode == .split {
            return !optionA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !optionB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // MARK: - Actions
    private func createDecision() {
        let decision = PersistenceController.shared.createDecision(
            question: mode == .split ? "\(optionA) OR \(optionB)" : explanation,
            optionA: mode == .split ? optionA : nil,
            optionB: mode == .split ? optionB : nil
        )
        
        // For free users, lock the analysis
        if !entitlements.isPro {
            decision.isLockedPreview = true
        } else {
            // Pro gets unlocked analysis
            decision.isLockedPreview = false
            decision.analysis = "Based on your input, consider the pros and cons carefully."
            decision.suggestedNextStep = "Take a day to reflect before deciding."
        }
        
        try? viewContext.save()
        
        dismiss()
    }
}

#Preview {
    ScenarioCreatorView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
