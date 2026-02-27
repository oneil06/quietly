//
//  Theme.swift
//  quietly
//
//  Global visual styling for the Quietly app.
//

import SwiftUI

// MARK: - Color Theme
struct QuietlyColors {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.15)
    static let cardFill = Color.white.opacity(0.08)
    static let secondaryText = Color.white.opacity(0.6)
    static let accent = Color.purple.opacity(0.9)
    
    // MARK: - Page Background
    static let pageBackground = Color(red: 0.01, green: 0.14, blue: 0.98)
    
    // MARK: - Quiet Screen Colors (from design spec)
    static let quietBackground = Color(red: 0.01, green: 0.14, blue: 0.98)
    static let tabBarBackground = Color(red: 0, green: 0.11, blue: 0.87)
    static let tabBarBorder = Color(red: 0.12, green: 0.43, blue: 1)
    static let centerTabButton = Color(red: 0.01, green: 0.58, blue: 0.97)
    
    // MARK: - Text Colors
    static let headerText = Color(red: 0.90, green: 0.91, blue: 1)
    static let placeholderText = Color(red: 0.51, green: 0.58, blue: 0.65)
    
    // MARK: - Segmented Control Colors
    static let segmentedBackground = Color(red: 0, green: 0.11, blue: 0.87)
    static let segmentedSelected = Color(red: 0, green: 0.35, blue: 0.94)
    
    // MARK: - Input Card
    static let inputCardBackground = Color(red: 0.90, green: 0.91, blue: 1)
    
    // MARK: - Button Colors
    static let buttonGreenBackground = Color(red: 0, green: 0.88, blue: 0.45)
    static let buttonBlueText = Color(red: 0.01, green: 0.13, blue: 0.97)
    
    // MARK: - Legacy Colors (for other screens)
    static let gradientTop = Color(hex: "4B6BF5")
    static let gradientMiddle = Color(hex: "2B4CF3")
    static let gradientBottom = Color(hex: "0222F9")
    static let primaryBlue = Color(hex: "3A86FF")
    static let secondaryBlue = Color(hex: "2563EB")
    static let deepBlue = Color(hex: "1E3AFA")
    static let accentGreen = Color(hex: "4ADE80")
    static let ctaGreen = Color(hex: "22C55E")
    static let ctaGreenDark = Color(hex: "16A34A")
    static let inputTextPrimary = Color(hex: "1F2937")
    static let inputTextPlaceholder = Color(hex: "6B7280")
    static let tabbarBackground = Color(hex: "1E3AFA")
    static let segmentedBorder = Color.white.opacity(0.15)
    
    // MARK: - New Design System Tokens (Light Card System)
    static let appBlue = Color(hex: "#0222F9")
    static let headingWhite = Color.white
    static let paragraphLight = Color(hex: "#E5E9FF")
    static let cardBackground = Color(hex: "#E5E9FF")
    static let cardTextDark = Color(hex: "#2B2B2B")
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
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
                .foregroundColor(QuietlyColors.headingWhite)
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
