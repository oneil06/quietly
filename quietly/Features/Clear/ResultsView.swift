//
//  ResultsView.swift
//  quietly
//
//  Action-first results screen with micro-interactions and priority grouping.
//

import SwiftUI
import CoreData
import UIKit

struct ResultsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entitlements = EntitlementsManager.shared

    let result: ExtractionResult
    let brainDump: BrainDump?
    @Binding var inputText: String
    let onDismiss: () -> Void
    @Binding var navigateToDecisions: Bool

    @State private var removedTasks: Set<String> = []
    @State private var completedTasks: Set<String> = []
    @State private var appeared: Bool = false
    @State private var showAlsoNoted: Bool = false
    @State private var showPaywall = false

    @FetchRequest private var extractedItems: FetchedResults<ExtractedItem>

    init(result: ExtractionResult, brainDump: BrainDump?, inputText: Binding<String>, onDismiss: @escaping () -> Void, navigateToDecisions: Binding<Bool>) {
        self.result = result
        self.brainDump = brainDump
        self._inputText = inputText
        self.onDismiss = onDismiss
        self._navigateToDecisions = navigateToDecisions

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

    // MARK: - Computed

    private var visibleTasks: [ExtractedTask] {
        result.tasks.filter { !removedTasks.contains($0.text) }
    }

    private var urgentTasks: [ExtractedTask] { visibleTasks.filter { $0.priority == .urgent } }
    private var thisWeekTasks: [ExtractedTask] { visibleTasks.filter { $0.priority == .thisWeek } }
    private var somedayTasks: [ExtractedTask] { visibleTasks.filter { $0.priority == .someday } }

    private var heroItem: HeroItem? {
        if let first = urgentTasks.first { return .task(first) }
        if let first = result.decisions.first { return .decision(first) }
        if let first = thisWeekTasks.first { return .task(first) }
        return nil
    }

    private var hasAlsoNoted: Bool {
        !result.worries.isEmpty || !result.ideas.isEmpty
    }

    private var isEmpty: Bool {
        result.tasks.isEmpty && result.decisions.isEmpty && result.worries.isEmpty && result.ideas.isEmpty
    }

    enum HeroItem {
        case task(ExtractedTask)
        case decision(DecisionDraft)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                QuietlyColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if isEmpty {
                            emptyState
                                .cardReveal(index: 0, appeared: appeared)
                        } else {
                            if let hero = heroItem {
                                heroCard(hero)
                                    .cardReveal(index: 0, appeared: appeared)
                            }

                            if !visibleTasks.isEmpty {
                                tasksSection
                                    .cardReveal(index: 1, appeared: appeared)
                            }

                            if !result.decisions.isEmpty {
                                decisionsSection
                                    .cardReveal(index: 2, appeared: appeared)
                            }

                            if hasAlsoNoted {
                                alsoNotedSection
                                    .cardReveal(index: 3, appeared: appeared)
                            }

                            if let summary = result.summary, !summary.isEmpty {
                                insightBanner(summary)
                                    .cardReveal(index: 4, appeared: appeared)
                            }
                        }

                        doneButton
                            .cardReveal(index: 5, appeared: appeared)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
            .navigationTitle("What surfaced")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDismiss() }
                        .foregroundColor(QuietlyColors.primaryBlue)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    // MARK: - Hero Card

    private func heroCard(_ item: HeroItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(QuietlyColors.green.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
                Text("Start here")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(QuietlyColors.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            switch item {
            case .task(let task):
                HStack(spacing: 14) {
                    completionCircle(task: task)
                    Text(task.text)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(completedTasks.contains(task.text) ? QuietlyColors.mutedText : QuietlyColors.darkText)
                        .strikethrough(completedTasks.contains(task.text), color: QuietlyColors.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

            case .decision(let decision):
                VStack(alignment: .leading, spacing: 8) {
                    Text(decision.question)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(QuietlyColors.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    decisionOptions(decision)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(QuietlyColors.green.opacity(0.4), lineWidth: 1.5)
                )
        )
        .shadow(color: QuietlyColors.green.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Tasks", icon: "checkmark.circle.fill", color: QuietlyColors.primaryBlue, count: visibleTasks.count)
                .padding(.bottom, 12)

            if !urgentTasks.isEmpty {
                priorityGroup(label: "Urgent", dot: Color.red, tasks: urgentTasks)
            }
            if !thisWeekTasks.isEmpty {
                priorityGroup(label: "This week", dot: QuietlyColors.primaryBlue, tasks: thisWeekTasks)
            }
            if !somedayTasks.isEmpty {
                priorityGroup(label: "Someday", dot: Color.gray, tasks: somedayTasks)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func priorityGroup(label: String, dot: Color, tasks: [ExtractedTask]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(dot).frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(QuietlyColors.mutedText)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.bottom, 6)

            ForEach(tasks, id: \.text) { task in
                taskRow(task)
            }
        }
        .padding(.bottom, 12)
    }

    private func taskRow(_ task: ExtractedTask) -> some View {
        let isDone = completedTasks.contains(task.text)
        return HStack(spacing: 12) {
            completionCircle(task: task)

            Text(task.text)
                .font(.system(size: 14))
                .foregroundColor(isDone ? QuietlyColors.mutedText : QuietlyColors.darkText)
                .strikethrough(isDone, color: QuietlyColors.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .animation(.easeInOut(duration: 0.2), value: isDone)

            if !isDone {
                Button(action: { removeTask(task.text) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(QuietlyColors.mutedText.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func completionCircle(task: ExtractedTask) -> some View {
        let isDone = completedTasks.contains(task.text)
        return Button(action: { toggleTaskDone(task) }) {
            ZStack {
                Circle()
                    .stroke(isDone ? QuietlyColors.green : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 28, height: 28)
                if isDone {
                    Circle()
                        .fill(QuietlyColors.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDone)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Decisions Section

    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Decisions", icon: "scale.3d", color: Color(hex: "6B7AE8"), count: result.decisions.count)

            ForEach(result.decisions, id: \.question) { decision in
                decisionCard(decision)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func decisionCard(_ decision: DecisionDraft) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(decision.question)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(QuietlyColors.darkText)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            decisionOptions(decision)

            Button(action: { reviewDecision(decision) }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 13))
                    Text("Review in Decisions")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(QuietlyColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(QuietlyColors.primaryBlue.opacity(0.07))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(hex: "6B7AE8").opacity(0.04))
        .cornerRadius(14)
    }

    private func decisionOptions(_ decision: DecisionDraft) -> some View {
        Group {
            if let a = decision.optionA, let b = decision.optionB, !a.isEmpty, !b.isEmpty {
                HStack(spacing: 8) {
                    optionChip("A", text: a)
                    Text("vs")
                        .font(.system(size: 11))
                        .foregroundColor(QuietlyColors.mutedText)
                    optionChip("B", text: b)
                    Spacer()
                }
            }
        }
    }

    private func optionChip(_ letter: String, text: String) -> some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.primaryBlue.opacity(0.12))
                    .frame(width: 18, height: 18)
                Text(letter)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
            }
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(QuietlyColors.darkText)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(QuietlyColors.primaryBlue.opacity(0.05))
        .cornerRadius(10)
    }

    // MARK: - Also Noted (worries + ideas collapsed)

    private var alsoNotedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showAlsoNoted.toggle()
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "ellipsis.bubble.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "8E8E93"))
                        Text("Also noted")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(QuietlyColors.darkText)
                        Text("\(result.worries.count + result.ideas.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    Image(systemName: showAlsoNoted ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(QuietlyColors.mutedText)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if showAlsoNoted {
                VStack(alignment: .leading, spacing: 12) {
                    if !result.worries.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Worries")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(QuietlyColors.mutedText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            ForEach(result.worries, id: \.self) { worry in
                                bulletRow(worry, dot: Color(hex: "8E8E93"))
                            }
                        }
                    }
                    if !result.ideas.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ideas")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(QuietlyColors.mutedText)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            ForEach(result.ideas, id: \.self) { idea in
                                bulletRow(idea, dot: Color(hex: "FF9500"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func bulletRow(_ text: String, dot: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(dot.opacity(0.6)).frame(width: 6, height: 6).padding(.top, 6)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.darkText)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Insight Banner

    private func insightBanner(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(QuietlyColors.primaryBlue)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.darkText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .background(QuietlyColors.primaryBlue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(QuietlyColors.primaryBlue.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(QuietlyColors.primaryBlue.opacity(0.08)).frame(width: 72, height: 72)
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(QuietlyColors.primaryBlue.opacity(0.4))
            }
            VStack(spacing: 6) {
                Text("Let's go a little deeper")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(QuietlyColors.darkText)
                Text("Try being more specific — name the task, name the decision.")
                    .font(.system(size: 14))
                    .foregroundColor(QuietlyColors.mutedText)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(["\"I need to call the doctor about my appointment\"",
                         "\"Should I take the job offer in another city?\"",
                         "\"I'm worried about my parent's health\""], id: \.self) { ex in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(QuietlyColors.primaryBlue.opacity(0.3)).frame(width: 5, height: 5).padding(.top, 6)
                        Text(ex).font(.system(size: 13)).foregroundColor(QuietlyColors.mutedText)
                    }
                }
            }
            .padding(12)
            .background(QuietlyColors.primaryBlue.opacity(0.04))
            .cornerRadius(14)
            Button(action: { onDismiss() }) {
                Text("Add more")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(QuietlyColors.green)
                    .cornerRadius(24)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onDismiss()
        }) {
            Text("Let's go")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(QuietlyColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(QuietlyColors.green)
                .cornerRadius(28)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Reusable

    private func sectionHeader(_ title: String, icon: String, color: Color, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(QuietlyColors.darkText)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold)).foregroundColor(color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(color.opacity(0.12)).clipShape(Capsule())
            Spacer()
        }
    }

    // MARK: - Actions

    private func toggleTaskDone(_ task: ExtractedTask) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if completedTasks.contains(task.text) {
                completedTasks.remove(task.text)
            } else {
                completedTasks.insert(task.text)
                // Also mark the linked TaskItem as complete in CoreData
                if let item = extractedItems.first(where: { $0.text == task.text }),
                   let taskItem = item.linkedTask {
                    taskItem.isCompleted = true
                    taskItem.completedAt = Date()
                    try? viewContext.save()
                }
            }
        }
    }

    private func removeTask(_ text: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let item = extractedItems.first(where: { $0.text == text }) else {
            withAnimation { removedTasks.insert(text) }
            return
        }
        withAnimation {
            if let task = item.linkedTask { viewContext.delete(task) }
            item.isPromotedToTask = false
            try? viewContext.save()
            removedTasks.insert(text)
        }
    }

    private func reviewDecision(_ decision: DecisionDraft) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        NotificationCenter.default.post(name: .switchToTab, object: 1)
        onDismiss()
    }
}

// MARK: - Card Reveal Modifier

private struct CardReveal: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 24)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82)
                    .delay(Double(index) * 0.09),
                value: appeared
            )
    }
}

private extension View {
    func cardReveal(index: Int, appeared: Bool) -> some View {
        modifier(CardReveal(index: index, appeared: appeared))
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
}
