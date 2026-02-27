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
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppShell()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                
                if showSplash {
                    SplashView(onComplete: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSplash = false
                        }
                    })
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
