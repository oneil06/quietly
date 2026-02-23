//
//  Persistence.swift
//  quietly
//
//  Created by Oniel McCalla.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "quietly")
        
        // Design for future CloudKit support - keep syncable flag ready
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Prepare for future NSPersistentCloudKitContainer migration
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Preview Support
    @MainActor
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let task = TaskItem(context: context)
        task.id = UUID()
        task.title = "Sample Task"
        task.createdAt = Date()
        task.isCompleted = false
        
        let decision = Decision(context: context)
        decision.id = UUID()
        decision.question = "Should I take that job?"
        decision.optionA = "Accept"
        decision.optionB = "Decline"
        decision.status = "active"
        decision.createdAt = Date()
        decision.isLockedPreview = true
        
        let brainDump = BrainDump(context: context)
        brainDump.id = UUID()
        brainDump.rawText = "I need to finish the project and also think about career options."
        brainDump.mode = "text"
        brainDump.createdAt = Date()
        
        do {
            try context.save()
        } catch {
            fatalError("Preview data error: \(error)")
        }
        
        return controller
    }()
    
    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
}

// MARK: - Convenience Extensions
extension PersistenceController {
    func createBrainDump(text: String, mode: String) -> BrainDump {
        let context = container.viewContext
        let dump = BrainDump(context: context)
        dump.id = UUID()
        dump.rawText = text
        dump.mode = mode
        dump.createdAt = Date()
        return dump
    }
    
    func createTask(title: String, notes: String? = nil, dueDate: Date? = nil, sourceKind: String? = nil) -> TaskItem {
        let context = container.viewContext
        let task = TaskItem(context: context)
        task.id = UUID()
        task.title = title
        task.notes = notes
        task.dueDate = dueDate
        task.sourceKind = sourceKind
        task.createdAt = Date()
        task.isCompleted = false
        return task
    }
    
    func createDecision(question: String, optionA: String? = nil, optionB: String? = nil) -> Decision {
        let context = container.viewContext
        let decision = Decision(context: context)
        decision.id = UUID()
        decision.question = question
        decision.optionA = optionA
        decision.optionB = optionB
        decision.status = "active"
        decision.createdAt = Date()
        decision.isLockedPreview = true
        return decision
    }
}
