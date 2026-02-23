//
//  Theme.swift
//  quietly
//
//  Global visual styling for the Quietly app.
//

import SwiftUI

// MARK: - Color Theme
struct QuietlyColors {
    static let background = Color(.systemGroupedBackground)
    static let cardFill = Color.primary.opacity(0.04)
    static let secondaryText = Color.secondary
    static let accent = Color.accentColor
}

// MARK: - Typography
struct QuietlyTypography {
    static let title = Font.title3.weight(.semibold)
    static let sectionHeader = Font.headline
    static let body = Font.callout
    static var secondary: Font { Font.footnote }
}

// MARK: - Spacing
struct QuietlySpacing {
    static let outerPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let cornerRadius: CGFloat = 16
}

// MARK: - Card View Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(QuietlyColors.cardFill)
            .cornerRadius(QuietlySpacing.cornerRadius)
            .padding(.horizontal, QuietlySpacing.outerPadding)
            .padding(.vertical, 8)
    }
}

extension View {
    func quietlyCard() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(QuietlyTypography.sectionHeader)
            Spacer()
        }
        .padding(.horizontal, QuietlySpacing.outerPadding)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isDisabled ? Color.gray : QuietlyColors.accent)
                .cornerRadius(12)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .foregroundColor(QuietlyColors.accent)
        }
    }
}

// MARK: - Clarity Ring Component
struct ClarityRing: View {
    var size: CGFloat = 60
    var lineWidth: CGFloat = 4
    var isResolved: Bool = false
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(
                    isResolved ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Inner subtle gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.accentColor.opacity(isResolved ? 0.15 : 0.05),
                            Color.accentColor.opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 3
                    )
                )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(QuietlyTypography.title)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.callout)
                        .foregroundColor(QuietlyColors.accent)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
    }
}

// MARK: - Locked Overlay
struct LockedOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Pro Feature")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}
