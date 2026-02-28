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
    
    @State private var selectedTab: Tab = .quiet
    @State private var showDailyCheckIn: Bool = false
    @State private var prefilledText: String = ""
    @State private var navigateToDecisions: Bool = false
    
    enum Tab: String, CaseIterable {
        case tasks = "Tasks"
        case decisions = "Decisions"
        case quiet = "Quiet"
        case analysis = "Analysis"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .tasks: return "checklist"
            case .decisions: return "clock.fill"
            case .quiet: return "sparkle"
            case .analysis: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
        
        var iconOutline: String {
            switch self {
            case .tasks: return "checklist"
            case .decisions: return "clock"
            case .quiet: return "sparkle"
            case .analysis: return "chart.bar"
            case .settings: return "gearshape"
            }
        }
        
        var isCenter: Bool {
            return self == .quiet
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ZStack {
                switch selectedTab {
                case .quiet:
                    ClearView(
                        prefilledText: $prefilledText,
                        navigateToDecisions: $navigateToDecisions
                    )
                case .decisions:
                    DecisionsView()
                case .tasks:
                    PlanView()
                case .analysis:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar at the bottom - fixed position
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea(.container, edges: .bottom)
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
                    selectedTab = .quiet
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

// MARK: - Custom Sparkle Icon Shape
struct SparkleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        // Scale factor from SVG viewBox (88x97)
        let scaleX = width / 88
        let scaleY = height / 97
        
        var path = Path()
        
        // Main star (largest) - centered at (34.5463, 64)
        path.move(to: CGPoint(x: 34.5463 * scaleX, y: 31 * scaleY))
        path.addLine(to: CGPoint(x: 31.975 * scaleX, y: 35.4894 * scaleY))
        path.addCurve(
            to: CGPoint(x: 4.69975 * scaleX, y: 61.5455 * scaleY),
            control1: CGPoint(x: 25.6785 * scaleX, y: 46.4867 * scaleY),
            control2: CGPoint(x: 16.2123 * scaleX, y: 55.5291 * scaleY)
        )
        path.addLine(to: CGPoint(x: 0, y: 64 * scaleY))
        path.addLine(to: CGPoint(x: 4.69975 * scaleX, y: 66.4545 * scaleY))
        path.addCurve(
            to: CGPoint(x: 31.975 * scaleX, y: 92.5106 * scaleY),
            control1: CGPoint(x: 16.2123 * scaleX, y: 81.5133 * scaleY),
            control2: CGPoint(x: 25.6785 * scaleX, y: 81.5133 * scaleY)
        )
        path.addLine(to: CGPoint(x: 34.5463 * scaleX, y: 97 * scaleY))
        path.addLine(to: CGPoint(x: 37.1159 * scaleX, y: 92.5106 * scaleY))
        path.addCurve(
            to: CGPoint(x: 64.3929 * scaleX, y: 66.4545 * scaleY),
            control1: CGPoint(x: 43.4124 * scaleX, y: 81.5133 * scaleY),
            control2: CGPoint(x: 52.8786 * scaleX, y: 72.4692 * scaleY)
        )
        path.addLine(to: CGPoint(x: 69.0909 * scaleX, y: 64 * scaleY))
        path.addLine(to: CGPoint(x: 64.3929 * scaleX, y: 61.5455 * scaleY))
        path.addCurve(
            to: CGPoint(x: 37.1159 * scaleX, y: 35.4894 * scaleY),
            control1: CGPoint(x: 52.8786 * scaleX, y: 55.5291 * scaleY),
            control2: CGPoint(x: 43.4124 * scaleX, y: 46.4867 * scaleY)
        )
        path.addLine(to: CGPoint(x: 34.5463 * scaleX, y: 31 * scaleY))
        path.closeSubpath()
        
        // Small star (top right)
        path.move(to: CGPoint(x: 87.8182 * scaleX, y: 31.5 * scaleY))
        path.addLine(to: CGPoint(x: 85.5867 * scaleX, y: 30.2718 * scaleY))
        path.addCurve(
            to: CGPoint(x: 72.6296 * scaleX, y: 17.244 * scaleY),
            control1: CGPoint(x: 80.1167 * scaleX, y: 27.2652 * scaleY),
            control2: CGPoint(x: 75.6212 * scaleX, y: 22.7429 * scaleY)
        )
        path.addLine(to: CGPoint(x: 71.4099 * scaleX, y: 15 * scaleY))
        path.addLine(to: CGPoint(x: 70.1886 * scaleX, y: 17.244 * scaleY))
        path.addCurve(
            to: CGPoint(x: 57.2331 * scaleX, y: 30.2718 * scaleY),
            control1: CGPoint(x: 62.7015 * scaleX, y: 22.7429 * scaleY),
            control2: CGPoint(x: 67.197 * scaleX, y: 27.2652 * scaleY)
        )
        path.addLine(to: CGPoint(x: 55 * scaleX, y: 31.5 * scaleY))
        path.addLine(to: CGPoint(x: 57.2331 * scaleX, y: 32.7281 * scaleY))
        path.addCurve(
            to: CGPoint(x: 70.1886 * scaleX, y: 45.756 * scaleY),
            control1: CGPoint(x: 67.197 * scaleX, y: 40.2571 * scaleY),
            control2: CGPoint(x: 62.7015 * scaleX, y: 35.7348 * scaleY)
        )
        path.addLine(to: CGPoint(x: 71.4099 * scaleX, y: 48 * scaleY))
        path.addLine(to: CGPoint(x: 72.6296 * scaleX, y: 45.756 * scaleY))
        path.addCurve(
            to: CGPoint(x: 85.5867 * scaleX, y: 32.7281 * scaleY),
            control1: CGPoint(x: 75.6212 * scaleX, y: 40.2571 * scaleY),
            control2: CGPoint(x: 80.1167 * scaleX, y: 35.7348 * scaleY)
        )
        path.addLine(to: CGPoint(x: 87.8182 * scaleX, y: 31.5 * scaleY))
        path.closeSubpath()
        
        // Tiny star (top center)
        path.move(to: CGPoint(x: 43.7932 * scaleX, y: 17.7077 * scaleY))
        path.addLine(to: CGPoint(x: 44.4992 * scaleX, y: 19 * scaleY))
        path.addLine(to: CGPoint(x: 45.2068 * scaleX, y: 17.7077 * scaleY))
        path.addCurve(
            to: CGPoint(x: 52.7076 * scaleX, y: 10.2076 * scaleY),
            control1: CGPoint(x: 46.9378 * scaleX, y: 14.5416 * scaleY),
            control2: CGPoint(x: 49.5412 * scaleX, y: 11.9384 * scaleY)
        )
        path.addLine(to: CGPoint(x: 54 * scaleX, y: 9.5 * scaleY))
        path.addLine(to: CGPoint(x: 52.7076 * scaleX, y: 8.79399 * scaleY))
        path.addCurve(
            to: CGPoint(x: 45.2068 * scaleX, y: 1.29227 * scaleY),
            control1: CGPoint(x: 49.5412 * scaleX, y: 7.06163 * scaleY),
            control2: CGPoint(x: 46.9378 * scaleX, y: 4.45842 * scaleY)
        )
        path.addLine(to: CGPoint(x: 44.4992 * scaleX, y: 0))
        path.addLine(to: CGPoint(x: 43.7932 * scaleX, y: 1.29227 * scaleY))
        path.addCurve(
            to: CGPoint(x: 36.2924 * scaleX, y: 8.79399 * scaleY),
            control1: CGPoint(x: 42.0607 * scaleX, y: 4.45842 * scaleY),
            control2: CGPoint(x: 39.4588 * scaleX, y: 7.06163 * scaleY)
        )
        path.addLine(to: CGPoint(x: 35 * scaleX, y: 9.5 * scaleY))
        path.addLine(to: CGPoint(x: 36.2924 * scaleX, y: 10.2076 * scaleY))
        path.addCurve(
            to: CGPoint(x: 43.7932 * scaleX, y: 17.7077 * scaleY),
            control1: CGPoint(x: 39.4588 * scaleX, y: 11.9384 * scaleY),
            control2: CGPoint(x: 42.0607 * scaleX, y: 14.5416 * scaleY)
        )
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: AppShell.Tab
    
    var body: some View {
        // Tab bar background with line on top
        VStack(spacing: 0) {
            // Line on top of tab bar
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3))
            
            HStack(spacing: 0) {
                ForEach(AppShell.Tab.allCases, id: \.self) { tab in
                    if tab.isCenter {
                        // Spacer for center button
                        Color.clear
                            .frame(maxWidth: .infinity)
                    } else {
                        TabBarItem(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
            .background(Color.white)
        .overlay(
            // Center button on top
            centerTabButton(tab: .quiet),
            alignment: .top
        )
        .frame(height: 83) // Fixed height for the tab bar
    }
    
    private func centerTabButton(tab: AppShell.Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            ZStack {
                // Circular button
                Circle()
                    .fill(QuietlyColors.quietPageBlue)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                
                // Custom sparkle icon from SVG
                SparkleIcon()
                    .fill(.white)
                    .frame(width: 26, height: 29)
            }
        }
        .buttonStyle(.plain)
        .offset(y: 11) // Position the button (moved up 3px)
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let tab: AppShell.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.icon : tab.iconOutline)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .frame(width: 24, height: 24)
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .heavy : .semibold))
            }
            .foregroundColor(isSelected ? QuietlyColors.quietPageBlue : QuietlyColors.quietPageBlue.opacity(0.5))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .offset(x: tab == .settings ? -5 : 0) // Move Settings 5px to the left
    }
}

// MARK: - Blur View Helper
#if canImport(UIKit)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
#else
struct BlurView: NSViewRepresentable {
    var style: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = style
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = style
    }
}
#endif

#Preview {
    AppShell()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
