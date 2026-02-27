//
//  InsightsView.swift
//  quietly
//
//  Tab 4: Insights - Analytics and patterns.
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
    
    @State private var showPaywall: Bool = false
    
    // Sample data for demo
    private let sampleThemes = ["Work", "Career", "Health", "Finances"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: QuietlySpacing.sectionSpacing) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Insights")
                        .font(QuietlyTypography.title)
                        .foregroundColor(QuietlyColors.headingWhite)
                    
                    Text("Your clarity over time.")
                        .font(QuietlyTypography.body)
                        .foregroundColor(QuietlyColors.paragraphLight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, QuietlySpacing.outerPadding)
                .padding(.top, 8)
                
                // Clarity Score Card
                clarityScoreCard
                
                // Clarity Trend (Placeholder)
                clarityTrendCard
                
                // Top Themes
                themesCard
                
                // Decisions Closed
                decisionsClosedCard
                
                // Weekly Summary
                weeklySummaryCard
                
                // Footer
                Text("Clarity builds with consistency.")
                    .font(.footnote)
                    .foregroundColor(QuietlyColors.paragraphLight)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
        }
        .background(QuietlyColors.pageBackground)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Clarity Score Card
    private var clarityScoreCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Clarity Score")
            
            HStack(alignment: .bottom, spacing: 8) {
                Text("85")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(QuietlyColors.cardTextDark)
                
                Text("/ 100")
                    .font(.title3)
                    .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                    .padding(.bottom, 8)
                
                Spacer()
                
                ClarityRing(size: 50, isResolved: true)
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding - 4)
    }
    
    // MARK: - Clarity Trend Card
    private var clarityTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Clarity Trend")
            
            VStack(spacing: 12) {
                // Placeholder chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach([65, 72, 68, 78, 82, 75, 85], id: \.self) { value in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(QuietlyColors.cardTextDark.opacity(Double(value) / 150))
                            .frame(width: 36, height: CGFloat(value))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                
                Text("Last 7 days")
                    .font(.caption)
                    .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding - 4)
    }
    
    // MARK: - Themes Card
    private var themesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Most Repeated Thoughts")
            
            VStack(spacing: 8) {
                // First theme always visible
                HStack {
                    Text(sampleThemes[0])
                        .font(QuietlyTypography.body)
                        .foregroundColor(QuietlyColors.cardTextDark)
                    Spacer()
                    Text("3 times")
                        .font(.caption)
                        .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                }
                .padding(12)
                .background(QuietlyColors.cardTextDark.opacity(0.1))
                .cornerRadius(8)
                
                // Additional themes locked for free users
                if entitlements.isPro {
                    ForEach(sampleThemes.dropFirst(), id: \.self) { theme in
                        HStack {
                            Text(theme)
                                .font(QuietlyTypography.body)
                                .foregroundColor(QuietlyColors.cardTextDark)
                            Spacer()
                            Text("2 times")
                                .font(.caption)
                                .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                        }
                        .padding(12)
                        .background(QuietlyColors.cardBackground.opacity(0.5))
                        .cornerRadius(8)
                    }
                } else {
                    // Locked overlay for free users
                    VStack(spacing: 8) {
                        HStack {
                            Text(sampleThemes[1])
                                .font(QuietlyTypography.body)
                                .foregroundColor(QuietlyColors.cardTextDark)
                            Spacer()
                            Text("2 times")
                                .font(.caption)
                                .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                        }
                        .padding(12)
                        .background(QuietlyColors.cardBackground.opacity(0.5))
                        .cornerRadius(8)
                        .blur(radius: 2)
                        
                        HStack {
                            Text(sampleThemes[2])
                                .font(QuietlyTypography.body)
                                .foregroundColor(QuietlyColors.cardTextDark)
                            Spacer()
                            Text("1 time")
                                .font(.caption)
                                .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                        }
                        .padding(12)
                        .background(QuietlyColors.cardBackground.opacity(0.5))
                        .cornerRadius(8)
                        .blur(radius: 2)
                    }
                    
                    Button(action: { showPaywall = true }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(QuietlyColors.cardTextDark)
                            Text("See full pattern history with Pro")
                                .foregroundColor(QuietlyColors.cardTextDark)
                        }
                        .font(.callout)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding - 4)
    }
    
    // MARK: - Decisions Closed Card
    private var decisionsClosedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Decisions Closed")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(resolvedDecisions.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(QuietlyColors.cardTextDark)
                    
                    Text("this week")
                        .font(.caption)
                        .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.largeTitle)
                    .foregroundColor(QuietlyColors.cardTextDark.opacity(0.6))
            }
            .padding(QuietlySpacing.cardPadding)
            .background(QuietlyColors.cardBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding - 4)
    }
    
    // MARK: - Weekly Summary Card
    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Weekly Summary")
            
            Text("You've made great progress this week. Your clarity score has improved by 12 points, and you've resolved 5 decisions. Keep up the consistent practice of clearing your mind daily.")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.cardTextDark)
                .padding(QuietlySpacing.cardPadding)
                .background(QuietlyColors.cardBackground)
                .cornerRadius(12)
        }
        .padding(.horizontal, QuietlySpacing.outerPadding - 4)
    }
}

#Preview {
    InsightsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
