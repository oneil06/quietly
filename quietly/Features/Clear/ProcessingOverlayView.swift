//
//  ProcessingOverlayView.swift
//  quietly
//
//  Animated processing overlay shown during extraction.
//

import SwiftUI

struct ProcessingOverlayView: View {
    @State private var currentMessageIndex = 0
    @State private var opacity: Double = 1.0
    
    private let messages = [
        "Organizing your thoughts…",
        "Separating what needs action…",
        "Looking for decisions…",
        "Untangling what's unresolved…"
    ]
    
    private let messageDuration: Double = 0.6
    
    var body: some View {
        ZStack {
            // Dark gradient background matching app theme
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.3))
            
            VStack(spacing: 24) {
                // Animated Clarity Ring
                ClarityRing(
                    size: 80,
                    lineWidth: 5,
                    isResolved: true
                )
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: QuietlyColors.accent))
                        .scaleEffect(1.2)
                )
                
                // Rotating microcopy
                Text(messages[currentMessageIndex])
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.3), value: opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            startMessageRotation()
        }
    }
    
    private func startMessageRotation() {
        Timer.scheduledTimer(withTimeInterval: messageDuration, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview {
    ProcessingOverlayView()
}
