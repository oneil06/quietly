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
            VStack(spacing: QuietlySpacing.sectionSpacing) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(QuietlyTypography.title)
                    
                    Text("Manage your preferences.")
                        .font(QuietlyTypography.body)
                        .foregroundColor(QuietlyColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, QuietlySpacing.outerPadding)
                .padding(.top, 8)
                
                VStack(spacing: QuietlySpacing.sectionSpacing) {
                    // Account Section
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Account")
                        
                        VStack(spacing: 8) {
                            HStack {
                                Label("Plan", systemImage: "sparkles")
                                Spacer()
                                Text(entitlements.isPro ? "Pro" : "Free")
                                    .foregroundColor(.secondary)
                            }
                            .padding(QuietlySpacing.cardPadding)
                            .background(QuietlyColors.cardFill)
                            .cornerRadius(12)
                            
                            if entitlements.isPro {
                                Button(action: {}) {
                                    HStack {
                                        Label("Manage subscription", systemImage: "creditcard")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                                }
                                .foregroundColor(.primary)
                            } else {
                                Button(action: { showPaywall = true }) {
                                    HStack {
                                        Label("Upgrade", systemImage: "arrow.up.circle")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    // Privacy Section
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Privacy")
                        
                        VStack(spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Data Storage")
                                        .font(.body)
                                    Text("Stored locally by default. Cloud sync is optional.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(QuietlySpacing.cardPadding)
                            .background(QuietlyColors.cardFill)
                            .cornerRadius(12)
                            
                            HStack {
                                Label("Cloud Sync", systemImage: "icloud")
                                Spacer()
                                if entitlements.isPro {
                                    Toggle("", isOn: $cloudSyncEnabled)
                                        .labelsHidden()
                                } else {
                                    Button(action: { showPaywall = true }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                            Text("Pro")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(QuietlySpacing.cardPadding)
                            .background(QuietlyColors.cardFill)
                            .cornerRadius(12)
                            
                            Button(action: exportData) {
                                Label("Export data", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                            
                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete all data", systemImage: "trash")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    // Notifications Section
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Notifications")
                        
                        HStack {
                            Label("Daily check-in reminder", systemImage: "bell")
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                        }
                        .padding(QuietlySpacing.cardPadding)
                        .background(QuietlyColors.cardFill)
                        .cornerRadius(12)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "About")
                        
                        VStack(spacing: 8) {
                            HStack {
                                Label("Version", systemImage: "info.circle")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            .padding(QuietlySpacing.cardPadding)
                            .background(QuietlyColors.cardFill)
                            .cornerRadius(12)
                            
                            Link(destination: URL(string: "https://quietly.app/privacy")!) {
                                Label("Privacy Policy", systemImage: "hand.raised")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                            
                            Link(destination: URL(string: "https://quietly.app/terms")!) {
                                Label("Terms of Service", systemImage: "doc.text")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(QuietlySpacing.cardPadding)
                                    .background(QuietlyColors.cardFill)
                                    .cornerRadius(12)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, QuietlySpacing.outerPadding)
            }
        }
        .background(QuietlyColors.background)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Delete All Data", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your brain dumps, decisions, tasks, and insights. This action cannot be undone.")
        }
    }
    
    // MARK: - Actions
    private func exportData() {
        // Stub - would implement data export
    }
    
    private func deleteAllData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Delete all entities
        let brainDumpFetch: NSFetchRequest<NSFetchRequestResult> = BrainDump.fetchRequest()
        let brainDumpDelete = NSBatchDeleteRequest(fetchRequest: brainDumpFetch)
        
        let decisionFetch: NSFetchRequest<NSFetchRequestResult> = Decision.fetchRequest()
        let decisionDelete = NSBatchDeleteRequest(fetchRequest: decisionFetch)
        
        let taskFetch: NSFetchRequest<NSFetchRequestResult> = TaskItem.fetchRequest()
        let taskDelete = NSBatchDeleteRequest(fetchRequest: taskFetch)
        
        let extractionFetch: NSFetchRequest<NSFetchRequestResult> = ExtractedItem.fetchRequest()
        let extractionDelete = NSBatchDeleteRequest(fetchRequest: extractionFetch)
        
        let insightFetch: NSFetchRequest<NSFetchRequestResult> = InsightDaily.fetchRequest()
        let insightDelete = NSBatchDeleteRequest(fetchRequest: insightFetch)
        
        do {
            try context.execute(brainDumpDelete)
            try context.execute(decisionDelete)
            try context.execute(taskDelete)
            try context.execute(extractionDelete)
            try context.execute(insightDelete)
            try context.save()
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
