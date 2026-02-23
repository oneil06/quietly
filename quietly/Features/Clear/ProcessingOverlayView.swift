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
            // Blur background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
            
            VStack(spacing: 24) {
                // Animated Clarity Ring
                ClarityRing(
                    size: 80,
                    lineWidth: 5,
                    isResolved: true
                )
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .scaleEffect(1.2)
                )
                
                // Rotating microcopy
                Text(messages[currentMessageIndex])
                    .font(.callout)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.3), value: opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
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
