//
//  ResultsView.swift
//  quietly
//
//  Shows extracted results from brain dump with enhanced categorization.
//

import SwiftUI
import CoreData

struct ResultsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entitlements = EntitlementsManager.shared
    
    let result: ExtractionResult
    let brainDump: BrainDump?
    @Binding var inputText: String
    let onDismiss: () -> Void
    @Binding var navigateToDecisions: Bool
    
    @State private var showPaywall = false
    @State private var removedTasks: Set<String> = []
    
    // Fetch extracted items for this brain dump to get linked tasks
    @FetchRequest private var extractedItems: FetchedResults<ExtractedItem>
    
    init(result: ExtractionResult, brainDump: BrainDump?, inputText: Binding<String>, onDismiss: @escaping () -> Void, navigateToDecisions: Binding<Bool>) {
        self.result = result
        self.brainDump = brainDump
        self._inputText = inputText
        self.onDismiss = onDismiss
        self._navigateToDecisions = navigateToDecisions
        
        // Fetch extracted items for this brain dump
        if let dump = brainDump {
            _extractedItems = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \ExtractedItem.createdAt, ascending: true)],
                predicate: NSPredicate(format: "sourceDump == %@ AND type == 'task'", dump),
                animation: .default
            )
        } else {
            _extractedItems = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \ExtractedItem.createdAt, ascending: true)],
                animation: .default
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Here's what surfaced.")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                        Text("Nothing added. Just organized.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // FIXED ORDER: Tasks, Decisions, Worries, Ideas
                    
                    // Tasks Section
                    SectionCard(
                        title: "Tasks",
                        icon: "checkmark.circle",
                        count: result.tasks.count,
                        isExpanded: true
                    ) {
                        if result.tasks.isEmpty {
                            Text("No tasks detected in your text.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            // Confirmation text
                            Text("Added to your plan.")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.bottom, 4)
                            
                            ForEach(result.tasks, id: \.self) { taskText in
                                if !removedTasks.contains(taskText) {
                                    TaskRowWithRemove(
                                        title: taskText,
                                        extractedItem: findExtractedItem(for: taskText),
                                        onRemove: {
                                            removeTask(taskText: taskText)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Decisions Section
                    SectionCard(
                        title: "Decisions",
                        icon: "circle.hexagonpath",
                        count: result.decisions.count,
                        isExpanded: true
                    ) {
                        if result.decisions.isEmpty {
                            Text("No decisions detected in your text.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(result.decisions, id: \.question) { decision in
                                DecisionRow(
                                    question: decision.question,
                                    optionA: decision.optionA,
                                    optionB: decision.optionB,
                                    onReview: {
                                        reviewInDecisions(decision: decision)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Worries Section
                    SectionCard(
                        title: "Worries",
                        icon: "cloud",
                        count: result.worries.isEmpty ? nil : result.worries.count,
                        isExpanded: true
                    ) {
                        if result.worries.isEmpty {
                            Text("No worries detected. That's great!")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(result.worries, id: \.self) { worry in
                                SimpleRow(text: worry)
                            }
                        }
                    }
                    
                    // Ideas Section
                    SectionCard(
                        title: "Ideas",
                        icon: "lightbulb",
                        count: result.ideas.isEmpty ? nil : result.ideas.count,
                        isExpanded: true
                    ) {
                        if result.ideas.isEmpty {
                            Text("No ideas detected in your text.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(result.ideas, id: \.self) { idea in
                                SimpleRow(text: idea)
                            }
                        }
                    }
                    
                    // Insights Card (if any)
                    if !result.insights.isEmpty {
                        SectionCard(title: "Insights", icon: "sparkle") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(result.insights, id: \.self) { insight in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption)
                                            .foregroundStyle(.yellow)
                                        Text(insight)
                                            .font(.callout)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Themes (if detected)
                    if !result.themes.isEmpty {
                        SectionCard(title: "Themes", icon: "tag") {
                            HStack(spacing: 8) {
                                ForEach(result.themes, id: \.self) { theme in
                                    Text(theme)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Empty state fallback
                    if result.tasks.isEmpty && result.decisions.isEmpty && result.worries.isEmpty && result.ideas.isEmpty {
                        SectionCard(title: "Let's go a little deeper", icon: "questionmark.circle") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Try being more specific about what you're thinking. For example:")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• \"I need to call the doctor about my appointment\"")
                                    Text("• \"Should I take the job offer in another city?\"")
                                    Text("• \"I'm worried about my parent's health\"")
                                    Text("• \"Maybe I could start a small side project\"")
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                
                                HStack(spacing: 12) {
                                    Button("Add more") {
                                        onDismiss()
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button("Keep as is") {
                                        onDismiss()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    
                    // Footer
                    HStack {
                        Spacer()
                        Text("Mental load reduced.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .padding(.bottom, 32)
            }
            .background(QuietlyColors.quietPageBackground)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findExtractedItem(for taskText: String) -> ExtractedItem? {
        return extractedItems.first { item in
            item.text == taskText
        }
    }
    
    private func removeTask(taskText: String) {
        guard let item = findExtractedItem(for: taskText) else { return }
        
        withAnimation {
            // Delete the linked TaskItem
            if let task = item.linkedTask {
                viewContext.delete(task)
            }
            
            // Mark as not promoted
            item.isPromotedToTask = false
            
            // Save context
            try? viewContext.save()
            
            // Update UI state
            removedTasks.insert(taskText)
        }
    }
    
    private func reviewInDecisions(decision: DecisionDraft) {
        // The decision should already be created in ClearView during extraction
        // Just switch to Decisions tab
        NotificationCenter.default.post(name: .switchToTab, object: 1) // Index 1 = Decisions tab
        onDismiss()
    }
}

// MARK: - Task Row with Remove
struct TaskRowWithRemove: View {
    let title: String
    let extractedItem: ExtractedItem?
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            
            Text(title)
                .font(.callout)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onRemove) {
                Text("Remove")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Section Card
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    var count: Int? = nil
    var isExpanded: Bool = true
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                if let count = count {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            
            content()
        }
        .padding(14)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
}

// MARK: - Decision Row
struct DecisionRow: View {
    let question: String
    var optionA: String?
    var optionB: String?
    let onReview: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.callout)
                .lineLimit(2)
            
            // Show options if available
            if let optionA = optionA, let optionB = optionB {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Option A")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(optionA)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    Text("vs")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Option B")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(optionB)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .padding(8)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
            }
            
            HStack {
                Text("Needs attention")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Button(action: onReview) {
                    Text("Review in Decisions")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Simple Row
struct SimpleRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.callout)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}
