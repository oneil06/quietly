//
//  SplashView.swift
//  quietly
//
//  Splash screen displayed on app launch.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    var onComplete: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Background image
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo image with animation
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(isAnimating ? 1 : 0.8)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
            }
        }
        .onAppear {
            // Start animation
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // Dismiss splash after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete?()
            }
        }
    }
}

#Preview {
    SplashView()
}
