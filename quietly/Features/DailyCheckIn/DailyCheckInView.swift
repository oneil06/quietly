//
//  DailyCheckInView.swift
//  quietly
//
//  Daily check-in modal with rotating prompts.
//

import SwiftUI
import Combine

struct DailyCheckInView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText: String = ""
    @State private var currentPromptIndex: Int = 0
    
    // Callbacks
    var onContinue: ((String) -> Void)? = nil
    var onSkip: (() -> Void)? = nil
    
    // Rotating prompts based on day of year
    private let prompts = [
        "What's on your mind right now?",
        "What feels unresolved today?",
        "What needs clarity today?",
        "What's quietly bothering you?"
    ]
    
    private var currentPrompt: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return prompts[(dayOfYear - 1) % prompts.count]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Prompt
                VStack(spacing: 8) {
                    Text(currentPrompt)
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // Text Input
                TextField("What's on your mind?", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(QuietlyColors.cardFill)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .lineLimit(2...4)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    PrimaryButton(title: "Continue", action: {
                        onContinue?(inputText)
                        dismiss()
                    }, isDisabled: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        // Record dismissal for today
                        recordDismissal()
                        onSkip?()
                        dismiss()
                    }) {
                        Text("Skip for today")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(QuietlyColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        recordDismissal()
                        onSkip?()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func recordDismissal() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        UserDefaults.standard.set(today, forKey: "quietly.checkInDismissedDayStamp")
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
        let dismissed = UserDefaults.standard.string(forKey: dismissedKey)
        
        return dismissed != today
    }
    
    func dismissForToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        UserDefaults.standard.set(today, forKey: dismissedKey)
    }
}

#Preview {
    DailyCheckInView()
}
