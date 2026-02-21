//
//  quietlyApp.swift
//  quietly
//
//  Created by Oniel McCalla on 21/02/2026.
//

import SwiftUI
import CoreData

@main
struct quietlyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
