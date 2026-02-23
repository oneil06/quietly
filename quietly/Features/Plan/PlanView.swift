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
    
    var body: some View {
        ScrollView {
            VStack(spacing: QuietlySpacing.sectionSpacing) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plan")
                            .font(QuietlyTypography.title)
                        
                        Text("Your action items.")
                            .font(QuietlyTypography.body)
                            .foregroundColor(QuietlyColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, QuietlySpacing.outerPadding)
                .padding(.top, 8)
                
                // Today Section
                if !incompleteTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Today")
                        
                        ForEach(incompleteTasks) { task in
                            taskRow(task: task)
                        }
                    }
                }
                
                // Completed Section
                if !completedTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Completed")
                        
                        ForEach(completedTasks.prefix(5)) { task in
                            completedTaskRow(task: task)
                        }
                    }
                }
                
                // Empty State
                if incompleteTasks.isEmpty && completedTasks.isEmpty {
                    emptyStateView
                }
            }
            .padding(.vertical, 16)
        }
        .background(QuietlyColors.background)
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
        }
    }
    
    // MARK: - Task Row
    private func taskRow(task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button(action: { completeTask(task) }) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title ?? "Untitled")
                    .font(QuietlyTypography.body)
                    .foregroundColor(.primary)
                
                if let dueDate = task.dueDate {
                    Text("Due \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let sourceKind = task.sourceKind {
                Text(sourceKind)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(QuietlySpacing.cardPadding)
        .background(QuietlyColors.cardFill)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title ?? "Untitled"), tap to complete")
    }
    
    // MARK: - Completed Task Row
    private func completedTaskRow(task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            Text(task.title ?? "Untitled")
                .font(QuietlyTypography.body)
                .foregroundColor(.secondary)
                .strikethrough()
            
            Spacer()
        }
        .padding(QuietlySpacing.cardPadding)
        .background(QuietlyColors.cardFill.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No tasks yet")
                .font(QuietlyTypography.body)
                .foregroundColor(QuietlyColors.secondaryText)
            
            Button(action: { showAddTask = true }) {
                Text("Add a task")
                    .font(.callout)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(32)
    }
    
    // MARK: - Actions
    private func completeTask(_ task: TaskItem) {
        withAnimation {
            task.isCompleted = true
            task.completedAt = Date()
            
            // Subtle haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            try? viewContext.save()
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs to be done?", text: $title)
                }
                
                Section("Notes (optional)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        let task = PersistenceController.shared.createTask(
            title: title,
            notes: notes.isEmpty ? nil : notes
        )
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    PlanView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
