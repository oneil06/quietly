//
//  SettingsView.swift
//  quietly
//
//  Tab 5: Settings - Account, privacy, and preferences.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    @State private var showPaywall: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                if !entitlements.isPro { proBanner }
                accountSection
                privacySection
                notificationsSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(QuietlyColors.background.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAllData() }
        } message: {
            Text("This will permanently delete all your brain dumps, decisions, tasks, and insights. This action cannot be undone.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(QuietlyColors.primaryBlue)
            Text("Manage your preferences.")
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Pro Banner (free users)
    private var proBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.green.opacity(0.25))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundColor(QuietlyColors.primaryBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Upgrade to Pro")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                Text("Unlock decisions, full insights & more.")
                    .font(.system(size: 13))
                    .foregroundColor(QuietlyColors.mutedText)
            }
            Spacer()
            Button(action: { showPaywall = true }) {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(QuietlyColors.green)
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Account Section
    private var accountSection: some View {
        settingsGroup(title: "Account") {
            infoRow(icon: "sparkles", iconColor: QuietlyColors.primaryBlue,
                    title: "Plan", trailing: entitlements.isPro ? "Pro ✦" : "Free")

            divider

            if entitlements.isPro {
                actionRow(icon: "creditcard", iconColor: QuietlyColors.primaryBlue,
                          title: "Manage subscription", action: {})
            } else {
                Button(action: { showPaywall = true }) {
                    actionRowContent(icon: "arrow.up.circle.fill", iconColor: QuietlyColors.green,
                                     title: "Upgrade to Pro")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        settingsGroup(title: "Privacy") {
            HStack(spacing: 14) {
                iconBubble("lock.fill", color: QuietlyColors.primaryBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Data Storage")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(QuietlyColors.darkText)
                    Text("Stored locally on your device")
                        .font(.system(size: 13))
                        .foregroundColor(QuietlyColors.mutedText)
                }
                Spacer()
            }
            .padding(.vertical, 4)

            divider

            HStack(spacing: 14) {
                iconBubble("icloud.fill", color: QuietlyColors.primaryBlue)
                Text("Cloud Sync")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(QuietlyColors.darkText)
                Spacer()
                if entitlements.isPro {
                    Toggle("", isOn: $cloudSyncEnabled).labelsHidden()
                } else {
                    Button(action: { showPaywall = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill").font(.system(size: 11))
                            Text("Pro").font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(QuietlyColors.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(QuietlyColors.primaryBlue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            divider

            Button(action: {}) {
                actionRowContent(icon: "square.and.arrow.up", iconColor: QuietlyColors.primaryBlue,
                                 title: "Export data")
            }
            .buttonStyle(.plain)

            divider

            Button(action: { showDeleteConfirmation = true }) {
                HStack(spacing: 14) {
                    iconBubble("trash.fill", color: Color.red)
                    Text("Delete all data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(QuietlyColors.mutedText)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        settingsGroup(title: "Notifications") {
            HStack(spacing: 14) {
                iconBubble("bell.fill", color: QuietlyColors.primaryBlue)
                Text("Daily check-in reminder")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(QuietlyColors.darkText)
                Spacer()
                Toggle("", isOn: $notificationsEnabled).labelsHidden()
            }
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        settingsGroup(title: "About") {
            infoRow(icon: "info.circle.fill", iconColor: QuietlyColors.primaryBlue,
                    title: "Version", trailing: "1.0.0")

            divider

            Link(destination: URL(string: "https://quietly.app/privacy")!) {
                actionRowContent(icon: "hand.raised.fill", iconColor: QuietlyColors.primaryBlue,
                                 title: "Privacy Policy")
            }
            .buttonStyle(.plain)

            divider

            Link(destination: URL(string: "https://quietly.app/terms")!) {
                actionRowContent(icon: "doc.text.fill", iconColor: QuietlyColors.primaryBlue,
                                 title: "Terms of Service")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reusable Components

    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuietlyColors.mutedText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }

    private func iconBubble(_ icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(color)
                .frame(width: 34, height: 34)
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }

    private func infoRow(icon: String, iconColor: Color, title: String, trailing: String) -> some View {
        HStack(spacing: 14) {
            iconBubble(icon, color: iconColor)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(QuietlyColors.darkText)
            Spacer()
            Text(trailing)
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.mutedText)
        }
    }

    private func actionRow(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionRowContent(icon: icon, iconColor: iconColor, title: title)
        }
        .buttonStyle(.plain)
    }

    private func actionRowContent(icon: String, iconColor: Color, title: String) -> some View {
        HStack(spacing: 14) {
            iconBubble(icon, color: iconColor)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(QuietlyColors.darkText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(QuietlyColors.mutedText)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.12))
            .frame(height: 1)
            .padding(.vertical, 10)
            .padding(.leading, 48)
    }

    // MARK: - Delete All Data
    private func deleteAllData() {
        let context = PersistenceController.shared.container.viewContext

        let entities: [NSFetchRequest<NSFetchRequestResult>] = [
            BrainDump.fetchRequest(),
            Decision.fetchRequest(),
            TaskItem.fetchRequest(),
            ExtractedItem.fetchRequest(),
            InsightDaily.fetchRequest()
        ]

        do {
            for fetch in entities {
                try context.execute(NSBatchDeleteRequest(fetchRequest: fetch))
            }
            try context.save()
        } catch {
            // Deletion failed — surface to user if needed
        }
    }
}

#Preview {
    SettingsView()
}
