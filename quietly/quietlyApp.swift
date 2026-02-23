//
//  quietlyApp.swift
//  quietly
//
//  Main app entry point.
//

import SwiftUI
import CoreData

@main
struct quietlyApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            AppShell()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
