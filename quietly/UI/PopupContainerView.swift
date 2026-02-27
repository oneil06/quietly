//
//  PopupContainerView.swift
//  quietly
//
//  Reusable popup container with Quietly design system styling.
//

import SwiftUI

struct PopupContainerView<Content: View>: View {
    let title: String
    let onCancel: () -> Void
    @ViewBuilder let content: Content
    
    var body: some View {
        NavigationStack {
            ZStack {
                QuietlyColors.appBlue
                    .ignoresSafeArea()
                
                ScrollView {
                    content
                        .padding(.horizontal, QuietlySpacing.outerPadding)
                        .padding(.top, 16)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(QuietlyColors.headingWhite)
                }
            }
        }
    }
}

// MARK: - Popup Content Card
struct PopupContentCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(spacing: 16) {
            content
        }
        .padding(QuietlySpacing.cardPadding)
        .background(QuietlyColors.cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Popup Text Field
struct PopupTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int> = 1...1
    
    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color.white.opacity(0.6))
            .cornerRadius(10)
            .foregroundColor(QuietlyColors.cardTextDark)
            .lineLimit(lineLimit)
    }
}

// MARK: - Popup Primary Button
struct PopupPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(QuietlyColors.headingWhite)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isEnabled ? QuietlyColors.appBlue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Popup Secondary Text
struct PopupSecondaryText: View {
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
    }
}

// MARK: - Popup Section Header
struct PopupSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(QuietlyTypography.sectionHeader)
            .foregroundColor(QuietlyColors.cardTextDark)
    }
}

#Preview {
    PopupContainerView(title: "Sample Popup", onCancel: {}) {
        VStack(spacing: 16) {
            PopupContentCard {
                VStack(alignment: .leading, spacing: 12) {
                    PopupSectionHeader(title: "Description")
                    PopupTextField(placeholder: "Enter text", text: .constant(""), axis: .vertical, lineLimit: 3...6)
                }
            }
            
            PopupPrimaryButton(title: "Save", action: {}, isEnabled: true)
        }
    }
}
