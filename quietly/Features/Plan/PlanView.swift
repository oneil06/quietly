//
//  PlanView.swift
//  quietly
//
//  Tab 3: Plan - Simple task checklist.
//

import SwiftUI
import CoreData

struct PlanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showAddTask: Bool = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    ) private var incompleteTasks: FetchedResults<TaskItem>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskItem.completedAt, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES"),
        animation: .default
    ) private var completedTasks: FetchedResults<TaskItem>

    private var totalTasks: Int { incompleteTasks.count + completedTasks.count }
    private var progress: Double {
        totalTasks == 0 ? 0 : Double(completedTasks.count) / Double(totalTasks)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                if totalTasks > 0 { progressCard }
                if !incompleteTasks.isEmpty { incompleteSection }
                if !completedTasks.isEmpty { completedSection }
                if incompleteTasks.isEmpty && completedTasks.isEmpty { emptyState }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(QuietlyColors.background.ignoresSafeArea())
        .sheet(isPresented: $showAddTask) { AddTaskView() }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tasks")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                Text("Your action items.")
                    .font(.system(size: 15))
                    .foregroundColor(QuietlyColors.mutedText)
            }
            Spacer()
            Button(action: { showAddTask = true }) {
                ZStack {
                    Circle()
                        .fill(QuietlyColors.green)
                        .frame(width: 42, height: 42)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - Progress Card
    private var progressCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(QuietlyColors.primaryBlue.opacity(0.12), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(QuietlyColors.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: progress)
                VStack(spacing: 0) {
                    Text("\(completedTasks.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(QuietlyColors.primaryBlue)
                    Text("done")
                        .font(.system(size: 10))
                        .foregroundColor(QuietlyColors.mutedText)
                }
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(incompleteTasks.count) remaining")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                Text("\(totalTasks) total tasks")
                    .font(.system(size: 14))
                    .foregroundColor(QuietlyColors.mutedText)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 3)
    }

    // MARK: - Incomplete Section
    private var incompleteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuietlyColors.mutedText)
                .padding(.leading, 4)

            ForEach(incompleteTasks) { task in
                taskRow(task)
            }
        }
    }

    // MARK: - Completed Section
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Completed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(QuietlyColors.mutedText)
                .padding(.leading, 4)

            ForEach(completedTasks.prefix(5)) { task in
                completedTaskRow(task)
            }
        }
    }

    // MARK: - Task Row
    private func taskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 14) {
            Button(action: { completeTask(task) }) {
                ZStack {
                    Circle()
                        .stroke(QuietlyColors.primaryBlue, lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    Circle()
                        .fill(QuietlyColors.primaryBlue.opacity(0.06))
                        .frame(width: 26, height: 26)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "Untitled")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(QuietlyColors.darkText)
                if let dueDate = task.dueDate {
                    Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundColor(QuietlyColors.mutedText)
                }
            }

            Spacer()

            if let sourceKind = task.sourceKind, sourceKind != "manual" {
                Text(sourceKind)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(QuietlyColors.primaryBlue.opacity(0.08))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityLabel("\(task.title ?? "Untitled"), tap to complete")
    }

    // MARK: - Completed Task Row
    private func completedTaskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(QuietlyColors.green)

            Text(task.title ?? "Untitled")
                .font(.system(size: 16))
                .foregroundColor(QuietlyColors.mutedText)
                .strikethrough(color: QuietlyColors.mutedText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.7))
        .cornerRadius(16)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(QuietlyColors.primaryBlue.opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "checklist")
                    .font(.system(size: 32))
                    .foregroundColor(QuietlyColors.primaryBlue.opacity(0.5))
            }
            Text("No tasks yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(QuietlyColors.primaryBlue)
            Text("Tasks extracted from your brain dumps will appear here.")
                .font(.system(size: 14))
                .foregroundColor(QuietlyColors.mutedText)
                .multilineTextAlignment(.center)
            Button(action: { showAddTask = true }) {
                Text("Add a task")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(QuietlyColors.primaryBlue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(QuietlyColors.green)
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }

    private func completeTask(_ task: TaskItem) {
        withAnimation {
            task.isCompleted = true
            task.completedAt = Date()
            try? viewContext.save()
        }
    }
}

// MARK: - Add Task Sheet
struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                QuietlyColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What needs to be done?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(QuietlyColors.mutedText)

                        TextField("", text: $title, axis: .vertical)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(QuietlyColors.darkText)
                            .focused($isFocused)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .lineLimit(2...5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    Spacer()

                    Button(action: saveTask) {
                        Text("Save Task")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(QuietlyColors.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.2) : QuietlyColors.green)
                            .cornerRadius(27)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(QuietlyColors.primaryBlue)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func saveTask() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = PersistenceController.shared.createTask(title: title, notes: nil)
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    PlanView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
