//
//  ProcessingOverlayView.swift
//  quietly
//
//  Premium animated processing overlay shown during AI extraction.
//

import SwiftUI
import Combine

// MARK: - Processing Overlay Container (Type alias for backward compatibility)
typealias ProcessingOverlayContainer = ProcessingOverlayViewContainer

// MARK: - Processing Overlay View Container
struct ProcessingOverlayViewContainer: View {
    @Binding var isProcessing: Bool
    @Binding var processingCompleted: Bool
    @Binding var processingError: String?
    var onComplete: (() -> Void)?
    var onErrorDismiss: (() -> Void)?
    
    @State private var progress: Double = 0.0
    @State private var currentMessageIndex: Int = 0
    @State private var textOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 0.0
    @State private var cardScale: CGFloat = 0.9
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let minimumDisplayTime: TimeInterval = 1.2
    @State private var startTime: Date = Date()
    
    private let messages = [
        "Organizing your thoughts…",
        "Finding tasks…",
        "Detecting decisions…",
        "Grouping repeated themes…",
        "Finalizing…"
    ]
    
    private let messageInterval: TimeInterval = 0.6
    private let progressTo85Duration: TimeInterval = 1.5
    private let progressTo100Duration: TimeInterval = 0.3
    
    @State private var messageTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // Blur background
            VisualEffectBlurView(style: .systemUltraThinMaterialLight)
                .ignoresSafeArea()
            
            // Semi-transparent white overlay
            Color.white
                .opacity(0.12)
                .ignoresSafeArea()
                .allowsHitTesting(true)
            
            // Centered popup card
            VStack(spacing: 0) {
                if showError {
                    errorContent
                } else {
                    loadingContent
                }
            }
            .frame(width: 280)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 24,
                        x: 0,
                        y: 8
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 0.64, green: 0.71, blue: 0.93), lineWidth: 0.5)
            )
            .scaleEffect(cardScale)
        }
        .opacity(overlayOpacity)
        .onAppear {
            startTime = Date()
            appearAnimation()
        }
        .onDisappear {
            messageTimer?.invalidate()
            messageTimer = nil
        }
        .onChange(of: processingCompleted) { _, completed in
            if completed && !showError {
                handleCompletion()
            }
        }
        .onChange(of: processingError) { _, error in
            if let msg = error {
                showErrorState(msg)
            }
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 24) {
            // Ring loader with centered icon
            ZStack {
                // Base ring (light grey)
                Circle()
                    .stroke(
                        Color(red: 0.90, green: 0.91, blue: 0.94),
                        lineWidth: 6
                    )
                    .frame(width: 110, height: 110)
                
                // Progress ring (#001DDE)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(red: 0, green: 0.11, blue: 0.87),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // Quietly sparkle icon - centered in the ring
                QuietlyIconShape()
                    .fill(Color(red: 0, green: 0.11, blue: 0.87)) // #001DDE
                    .frame(width: 55, height: 60)
            }
            
            // Status text with crossfade
            Text(messages[currentMessageIndex])
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0, green: 0.11, blue: 0.87))
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
                .frame(height: 24)
        }
    }
    
    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.orange)
            
            Text(errorMessage)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0, green: 0.11, blue: 0.87))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isProcessing = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onErrorDismiss?()
                }
            } label: {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(Color(red: 0, green: 0.11, blue: 0.87))
                    .cornerRadius(12)
            }
        }
    }
    
    private func appearAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            overlayOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            cardScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            startProgressAnimation()
            startMessageRotation()
        }
    }
    
    private func startProgressAnimation() {
        withAnimation(.easeOut(duration: progressTo85Duration)) {
            progress = 0.85
        }
    }
    
    private func startMessageRotation() {
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: messageInterval, repeats: true) { timer in
            guard isProcessing && !showError else {
                timer.invalidate()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                textOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    textOpacity = 1.0
                }
            }
        }
    }
    
    private func handleCompletion() {
        messageTimer?.invalidate()
        messageTimer = nil
        
        withAnimation(.easeInOut(duration: progressTo100Duration)) {
            progress = 1.0
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remainingTime = max(0, minimumDisplayTime - elapsed)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + progressTo100Duration + 0.1 + remainingTime) {
            withAnimation(.easeIn(duration: 0.2)) {
                overlayOpacity = 0.0
                cardScale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isProcessing = false
                onComplete?()
            }
        }
    }
    
    private func showErrorState(_ message: String) {
        messageTimer?.invalidate()
        messageTimer = nil
        errorMessage = message
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showError = true
        }
    }
}

// MARK: - Quietly Icon Shape
struct QuietlyIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // The original SVG viewBox is 106x117
        // We need to scale and center it within the given rect
        let scale = min(rect.width / 106, rect.height / 117)
        let offsetX = rect.midX - (53 * scale) // 53 = 106/2
        let offsetY = rect.midY - (58.5 * scale) // 58.5 = 117/2
        
        // Large star/sparkle (center)
        let largeStarPoints = [
            CGPoint(x: 41.6272, y: 37.354),
            CGPoint(x: 38.5289, y: 42.7636),
            CGPoint(x: 30.9418, y: 56.015),
            CGPoint(x: 19.5354, y: 66.9108),
            CGPoint(x: 5.66305, y: 74.1603),
            CGPoint(x: 0, y: 77.118),
            CGPoint(x: 5.66305, y: 80.0756),
            CGPoint(x: 19.5354, y: 87.3232),
            CGPoint(x: 30.9418, y: 98.221),
            CGPoint(x: 38.5289, y: 111.472),
            CGPoint(x: 41.6272, y: 116.882),
            CGPoint(x: 44.7235, y: 111.472),
            CGPoint(x: 52.3106, y: 98.221),
            CGPoint(x: 63.717, y: 87.3232),
            CGPoint(x: 77.5914, y: 80.0756),
            CGPoint(x: 83.2524, y: 77.118),
            CGPoint(x: 77.5914, y: 74.1603),
            CGPoint(x: 63.717, y: 66.9108),
            CGPoint(x: 52.3106, y: 56.015),
            CGPoint(x: 44.7235, y: 42.7636)
        ]
        
        if let first = largeStarPoints.first {
            path.move(to: CGPoint(
                x: offsetX + first.x * scale,
                y: offsetY + first.y * scale
            ))
            for point in largeStarPoints.dropFirst() {
                path.addLine(to: CGPoint(
                    x: offsetX + point.x * scale,
                    y: offsetY + point.y * scale
                ))
            }
            path.closeSubpath()
        }
        
        // Medium star/sparkle (top right)
        let mediumStarPoints = [
            CGPoint(x: 105.818, y: 37.9562),
            CGPoint(x: 103.129, y: 36.4763),
            CGPoint(x: 96.5382, y: 32.8534),
            CGPoint(x: 91.1212, y: 27.4042),
            CGPoint(x: 87.5164, y: 20.7782),
            CGPoint(x: 86.0467, y: 18.0742),
            CGPoint(x: 84.5751, y: 20.7782),
            CGPoint(x: 80.9703, y: 27.4042),
            CGPoint(x: 75.5534, y: 32.8534),
            CGPoint(x: 68.9642, y: 36.4763),
            CGPoint(x: 66.2733, y: 37.9562),
            CGPoint(x: 68.9642, y: 39.4361),
            CGPoint(x: 75.5534, y: 43.059),
            CGPoint(x: 80.9703, y: 48.5082),
            CGPoint(x: 84.5751, y: 55.1343),
            CGPoint(x: 86.0467, y: 57.8382),
            CGPoint(x: 87.5164, y: 55.1343),
            CGPoint(x: 91.1212, y: 48.5082),
            CGPoint(x: 96.5382, y: 43.059),
            CGPoint(x: 103.129, y: 39.4361)
        ]
        
        if let first = mediumStarPoints.first {
            path.move(to: CGPoint(
                x: offsetX + first.x * scale,
                y: offsetY + first.y * scale
            ))
            for point in mediumStarPoints.dropFirst() {
                path.addLine(to: CGPoint(
                    x: offsetX + point.x * scale,
                    y: offsetY + point.y * scale
                ))
            }
            path.closeSubpath()
        }
        
        // Small star/sparkle (top left)
        let smallStarPoints = [
            CGPoint(x: 52.7694, y: 21.3373),
            CGPoint(x: 53.6202, y: 22.8944),
            CGPoint(x: 54.4728, y: 21.3373),
            CGPoint(x: 56.5586, y: 17.5222),
            CGPoint(x: 59.6956, y: 14.3854),
            CGPoint(x: 63.511, y: 12.2998),
            CGPoint(x: 65.0683, y: 11.4472),
            CGPoint(x: 63.511, y: 10.5965),
            CGPoint(x: 59.6956, y: 8.50905),
            CGPoint(x: 56.5586, y: 5.37226),
            CGPoint(x: 54.4728, y: 1.55715),
            CGPoint(x: 53.6202, y: 0),
            CGPoint(x: 52.7694, y: 1.55715),
            CGPoint(x: 50.6818, y: 5.37226),
            CGPoint(x: 47.5466, y: 8.50905),
            CGPoint(x: 43.7312, y: 10.5965),
            CGPoint(x: 42.1739, y: 11.4472),
            CGPoint(x: 43.7312, y: 12.2998),
            CGPoint(x: 47.5466, y: 14.3854),
            CGPoint(x: 50.6818, y: 17.5222)
        ]
        
        if let first = smallStarPoints.first {
            path.move(to: CGPoint(
                x: offsetX + first.x * scale,
                y: offsetY + first.y * scale
            ))
            for point in smallStarPoints.dropFirst() {
                path.addLine(to: CGPoint(
                    x: offsetX + point.x * scale,
                    y: offsetY + point.y * scale
                ))
            }
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Visual Effect Blur View
struct VisualEffectBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.blue
            .ignoresSafeArea()
        
        Text("Background Content")
            .font(.title)
            .foregroundColor(.white)
        
        ProcessingOverlayViewContainer(
            isProcessing: .constant(true),
            processingCompleted: .constant(false),
            processingError: .constant(nil),
            onComplete: {
                print("Processing complete")
            }
        )
    }
}
