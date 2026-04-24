//
//  DailyCheckInView.swift
//  quietly
//
//  Daily check-in modal with rotating prompts.
//

import SwiftUI
import UIKit
import Combine

struct DailyCheckInView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputText: String = ""
    @State private var appeared: Bool = false
    @FocusState private var isFocused: Bool

    var onContinue: ((String) -> Void)? = nil
    var onSkip: (() -> Void)? = nil

    private let prompts = [
        "What feels\nunresolved today?",
        "What's quietly\nbothering you?",
        "What needs\nclarity today?",
        "What's on\nyour mind?"
    ]

    private var currentPrompt: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return prompts[(dayOfYear - 1) % prompts.count]
    }

    private var canContinue: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            QuietlyColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button row
                HStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        recordDismissal()
                        onSkip?()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 2)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(QuietlyColors.mutedText)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.05), value: appeared)

                Spacer()

                // Prompt
                VStack(spacing: 20) {
                    Text(currentPrompt)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(QuietlyColors.darkText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1), value: appeared)

                    // Input field
                    ZStack(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text("What's on your mind?")
                                .font(.system(size: 16))
                                .foregroundColor(QuietlyColors.mutedText.opacity(0.6))
                                .padding(.horizontal, 18)
                                .padding(.top, 16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $inputText)
                            .font(.system(size: 16))
                            .foregroundColor(QuietlyColors.darkText)
                            .focused($isFocused)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(minHeight: 110, maxHeight: 180)
                    }
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.18), value: appeared)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom actions
                VStack(spacing: 14) {
                    Button(action: {
                        guard canContinue else { return }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onContinue?(inputText)
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(canContinue ? QuietlyColors.primaryBlue : QuietlyColors.mutedText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canContinue ? QuietlyColors.green : Color.gray.opacity(0.15))
                            .cornerRadius(28)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canContinue)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canContinue)

                    Button(action: {
                        recordDismissal()
                        onSkip?()
                        dismiss()
                    }) {
                        Text("Skip for today")
                            .font(.system(size: 15))
                            .foregroundColor(QuietlyColors.mutedText)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
                .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.25), value: appeared)
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isFocused = true
            }
        }
    }

    private func recordDismissal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: "quietly.checkInDismissedDayStamp")
    }
}

// MARK: - Check In Manager
class CheckInManager: ObservableObject {
    static let shared = CheckInManager()

    private let dismissedKey = "quietly.checkInDismissedDayStamp"

    var shouldShowCheckIn: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return UserDefaults.standard.string(forKey: dismissedKey) != today
    }

    func dismissForToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        UserDefaults.standard.set(formatter.string(from: Date()), forKey: dismissedKey)
    }
}

#Preview {
    DailyCheckInView()
}
