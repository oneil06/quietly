//
//  AppShell.swift
//  quietly
//
//  Main app shell with Bottom Tab Bar navigation.
//

import SwiftUI
import Combine
import CoreData

struct AppShell: View {
    @ObservedObject var entitlements = EntitlementsManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    
    @State private var selectedTab: Tab = .clear
    @State private var showDailyCheckIn: Bool = false
    @State private var prefilledText: String = ""
    @State private var navigateToDecisions: Bool = false
    
    enum Tab: String, CaseIterable {
        case clear = "Clear"
        case decisions = "Decisions"
        case plan = "Plan"
        case insights = "Insights"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .clear: return "sparkles"
            case .decisions: return "clock.fill"
            case .plan: return "list.bullet"
            case .insights: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var iconOutline: String {
            switch self {
            case .clear: return "sparkles"
            case .decisions: return "clock"
            case .plan: return "list.bullet"
            case .insights: return "chart.bar"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ZStack {
                switch selectedTab {
                case .clear:
                    ClearView(
                        prefilledText: $prefilledText,
                        navigateToDecisions: $navigateToDecisions
                    )
                case .decisions:
                    DecisionsView()
                case .plan:
                    PlanView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar at the bottom
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Check if should show daily check-in
            if checkInManager.shouldShowCheckIn {
                showDailyCheckIn = true
            }
        }
        .onChange(of: navigateToDecisions) { _, newValue in
            if newValue {
                selectedTab = .decisions
                navigateToDecisions = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tabIndex = notification.object as? Int, let tab = Tab.allCases[safe: tabIndex] {
                selectedTab = tab
            }
        }
        .sheet(isPresented: $showDailyCheckIn) {
            DailyCheckInView(
                onContinue: { text in
                    prefilledText = text
                    selectedTab = .clear
                },
                onSkip: {}
            )
        }
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppShell.Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppShell.Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: { selectedTab = tab }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 0)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.primary.opacity(0.1)),
            alignment: .top
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let tab: AppShell.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .frame(width: 28, height: 28)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppShell()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
