//
//  ScenarioCreatorView.swift
//  quietly
//
//  Create new decisions manually.
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

    @FocusState private var focusedField: Field?

    enum CreatorMode: String, CaseIterable {
        case split = "Two Options"
        case explain = "Describe it"
    }

    enum Field { case optionA, optionB, explanation }

    private var canCreate: Bool {
        if mode == .split {
            return !optionA.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   !optionB.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QuietlyColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Mode toggle
                        HStack(spacing: 0) {
                            ForEach(CreatorMode.allCases, id: \.self) { m in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(m.rawValue)
                                            .font(.system(size: 14, weight: mode == m ? .bold : .regular))
                                            .foregroundColor(QuietlyColors.primaryBlue)
                                        Rectangle()
                                            .fill(mode == m ? QuietlyColors.primaryBlue : QuietlyColors.primaryBlue.opacity(0.15))
                                            .frame(height: 2)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)

                        // Form
                        if mode == .split {
                            splitForm
                        } else {
                            explainForm
                        }

                        // Create button
                        Button(action: createDecision) {
                            Text("Create Decision")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(QuietlyColors.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(canCreate ? QuietlyColors.green : Color.gray.opacity(0.2))
                                .cornerRadius(27)
                        }
                        .disabled(!canCreate)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = mode == .split ? .optionA : .explanation
                }
            }
        }
    }

    // MARK: - Split Form
    private var splitForm: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("Option A", icon: "circle.fill", color: QuietlyColors.primaryBlue)
                TextField("e.g. Stay at current job", text: $optionA, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(QuietlyColors.darkText)
                    .focused($focusedField, equals: .optionA)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .optionB }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    .lineLimit(2...5)
            }

            HStack(spacing: 8) {
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
                Text("OR")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(QuietlyColors.mutedText)
                    .fixedSize()
                Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                fieldLabel("Option B", icon: "circle", color: QuietlyColors.primaryBlue)
                TextField("e.g. Take the new opportunity", text: $optionB, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(QuietlyColors.darkText)
                    .focused($focusedField, equals: .optionB)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    .lineLimit(2...5)
            }
        }
    }

    // MARK: - Explain Form
    private var explainForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Describe your situation", icon: "text.alignleft", color: QuietlyColors.primaryBlue)
            TextField("What decision are you wrestling with?", text: $explanation, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(QuietlyColors.darkText)
                .focused($focusedField, equals: .explanation)
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                .lineLimit(4...10)
        }
    }

    private func fieldLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuietlyColors.mutedText)
        }
        .padding(.leading, 2)
    }

    // MARK: - Create
    private func createDecision() {
        let question = mode == .split
            ? [optionA, optionB].filter { !$0.isEmpty }.joined(separator: " OR ")
            : explanation

        let decision = PersistenceController.shared.createDecision(
            question: question,
            optionA: mode == .split ? optionA : nil,
            optionB: mode == .split ? optionB : nil
        )

        decision.isLockedPreview = !entitlements.isPro
        if entitlements.isPro {
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
