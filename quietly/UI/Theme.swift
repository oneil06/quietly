//
//  Theme.swift
//  quietly
//
//  Global visual styling for the Quietly app.
//

import SwiftUI

// MARK: - Color Theme
struct QuietlyColors {
    // Primary brand blue — headers, borders, tab icons, active states
    static let primaryBlue = Color(hex: "001DDE")
    // Medium blue — secondary buttons, accents
    static let mediumBlue = Color(hex: "3B6BE5")
    // CTA green — AI Analysis button, Decide buttons
    static let green = Color(hex: "00E072")
    // Page background — light gray
    static let background = Color(red: 0.95, green: 0.95, blue: 0.95)
    // Card surface — white
    static let card = Color.white
    // Dark text on cards
    static let darkText = Color(hex: "1A1A2E")
    // Muted text
    static let mutedText = Color(hex: "1A1A2E").opacity(0.55)
    // Modal/paywall background — deep navy
    static let modalDark = Color(hex: "001DDE")
    // Mic button red
    static let micRed = Color(red: 1, green: 0.23, blue: 0.19)

    // MARK: - Legacy aliases (avoid adding new uses)
    static var quietPageBlue: Color { primaryBlue }
    static var quietPageBackground: Color { background }
    static var buttonGreenBackground: Color { green }
    static var cardBackground: Color { card }
    static var cardTextDark: Color { darkText }
    static var appBlue: Color { primaryBlue }
    static var headingWhite: Color { .white }
    static var paragraphLight: Color { Color(hex: "E5E9FF") }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(QuietlyTypography.sectionHeader)
                .foregroundColor(QuietlyColors.primaryBlue)
            Spacer()
        }
        .padding(.horizontal, QuietlySpacing.outerPadding)
    }
}

// MARK: - Clarity Ring Component
struct ClarityRing: View {
    var size: CGFloat = 60
    var lineWidth: CGFloat = 4
    var isResolved: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    isResolved ? QuietlyColors.primaryBlue.opacity(0.3) : Color.gray.opacity(0.2),
                    lineWidth: lineWidth
                )
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            QuietlyColors.primaryBlue.opacity(isResolved ? 0.15 : 0.05),
                            QuietlyColors.primaryBlue.opacity(0)
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
                .foregroundColor(QuietlyColors.mutedText)
                .multilineTextAlignment(.center)

            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.callout)
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
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
                .foregroundColor(QuietlyColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isDisabled ? Color.gray.opacity(0.3) : QuietlyColors.green)
                .cornerRadius(12)
        }
        .disabled(isDisabled)
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
