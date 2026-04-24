//
//  InsightsView.swift
//  quietly
//
//  Tab 4: Analysis - Analytics and patterns.
//

import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entitlements = EntitlementsManager.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InsightDaily.date, ascending: false)],
        animation: .default
    ) private var dailyInsights: FetchedResults<InsightDaily>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Decision.resolvedAt, ascending: false)],
        predicate: NSPredicate(format: "resolvedAt != nil"),
        animation: .default
    ) private var resolvedDecisions: FetchedResults<Decision>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.completedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES"),
        animation: .default
    ) private var completedTasks: FetchedResults<TaskItem>

    @State private var showPaywall: Bool = false

    private let trendValues: [Int] = [55, 62, 70, 65, 78, 82, 85]
    private let sampleThemes = [
        ("Work", 8), ("Career", 5), ("Health", 4), ("Finances", 3), ("Relationships", 2)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                statsRow
                clarityTrendCard
                themesCard
                weeklySummaryCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(QuietlyColors.background.ignoresSafeArea())
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Analysis")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(QuietlyColors.primaryBlue)
            Text("Your clarity over time.")
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: "85",
                label: "Clarity Score",
                icon: "brain.head.profile",
                highlight: true
            )
            statCard(
                value: "\(resolvedDecisions.count)",
                label: "Decisions Made",
                icon: "checkmark.seal.fill",
                highlight: false
            )
            statCard(
                value: "\(completedTasks.count)",
                label: "Tasks Done",
                icon: "checklist",
                highlight: false
            )
        }
    }

    private func statCard(value: String, label: String, icon: String, highlight: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(highlight ? QuietlyColors.primaryBlue : QuietlyColors.primaryBlue.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(highlight ? .white : QuietlyColors.primaryBlue)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(QuietlyColors.darkText)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(QuietlyColors.mutedText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Clarity Trend Card
    private var clarityTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clarity Trend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(QuietlyColors.darkText)
                    Text("Last 7 days")
                        .font(.system(size: 12))
                        .foregroundColor(QuietlyColors.mutedText)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(QuietlyColors.green)
                    Text("+18%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(QuietlyColors.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(QuietlyColors.green.opacity(0.15))
                .cornerRadius(10)
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                let maxVal = trendValues.max() ?? 1
                ForEach(Array(zip(trendValues.indices, trendValues)), id: \.0) { i, val in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(i == trendValues.count - 1 ? QuietlyColors.primaryBlue : QuietlyColors.primaryBlue.opacity(0.2))
                            .frame(height: CGFloat(val) / CGFloat(maxVal) * 80)
                        Text(dayLabel(offset: i - (trendValues.count - 1)))
                            .font(.system(size: 10))
                            .foregroundColor(QuietlyColors.mutedText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            .animation(.easeInOut(duration: 0.4), value: trendValues.count)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func dayLabel(offset: Int) -> String {
        let days = ["Su","Mo","Tu","We","Th","Fr","Sa"]
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        let idx = ((weekday + offset) + 7) % 7
        return days[idx]
    }

    // MARK: - Themes Card
    private var themesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recurring Themes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(QuietlyColors.darkText)
                    Text("What your mind keeps returning to")
                        .font(.system(size: 12))
                        .foregroundColor(QuietlyColors.mutedText)
                }
                Spacer()
                if !entitlements.isPro {
                    proTag
                }
            }

            let visibleThemes = entitlements.isPro ? sampleThemes : Array(sampleThemes.prefix(2))
            let maxCount = sampleThemes.first?.1 ?? 1

            VStack(spacing: 10) {
                ForEach(visibleThemes, id: \.0) { theme, count in
                    HStack(spacing: 12) {
                        Text(theme)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(QuietlyColors.darkText)
                            .frame(width: 90, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(QuietlyColors.primaryBlue.opacity(0.08))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(QuietlyColors.primaryBlue)
                                    .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                            }
                        }
                        .frame(height: 8)

                        Text("\(count)x")
                            .font(.system(size: 13))
                            .foregroundColor(QuietlyColors.mutedText)
                            .frame(width: 28, alignment: .trailing)
                    }
                }
            }

            if !entitlements.isPro {
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                        Text("Unlock full pattern history with Pro")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(QuietlyColors.primaryBlue.opacity(0.08))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Weekly Summary Card
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(QuietlyColors.green.opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Weekly Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(QuietlyColors.darkText)
                    Text("Generated for you")
                        .font(.system(size: 12))
                        .foregroundColor(QuietlyColors.mutedText)
                }
            }

            Text("Your clarity score has improved 18 points this week. You've resolved \(resolvedDecisions.count) decision\(resolvedDecisions.count == 1 ? "" : "s") and checked off \(completedTasks.count) task\(completedTasks.count == 1 ? "" : "s"). Keep building this habit — consistent reflection compounds quickly.")
                .font(.system(size: 15))
                .foregroundColor(QuietlyColors.darkText.opacity(0.85))
                .lineSpacing(3)

            Text("Clarity builds with consistency.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(QuietlyColors.mutedText)
                .italic()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Pro Tag
    private var proTag: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9))
            Text("Pro")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(QuietlyColors.primaryBlue)
        .cornerRadius(10)
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
