//
//  EntitlementsManager.swift
//  quietly
//
//  Handles Free vs Pro entitlements and daily usage limits.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class EntitlementsManager: ObservableObject {
    static let shared = EntitlementsManager()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let isPro = "quietly.isPro"
        static let dailyProcessCount = "quietly.dailyProcessCount"
        static let lastProcessDayStamp = "quietly.lastProcessDayStamp"
        static let dailyCheckInEnabled = "quietly.dailyCheckInEnabled"
    }
    
    // MARK: - Published Properties
    @Published var isPro: Bool {
        didSet {
            UserDefaults.standard.set(isPro, forKey: Keys.isPro)
        }
    }
    
    @Published var dailyProcessCount: Int {
        didSet {
            UserDefaults.standard.set(dailyProcessCount, forKey: Keys.dailyProcessCount)
        }
    }
    
    @Published var dailyCheckInEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyCheckInEnabled, forKey: Keys.dailyCheckInEnabled)
        }
    }
    
    // MARK: - Computed Properties
    private var todayStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Free users get 1 process per day, Pro users have unlimited
    var canProcessToday: Bool {
        // Pro users have unlimited access
        if isPro { return true }
        
        // Reset count if it's a new day
        resetIfNewDay()
        
        // Free users get 1 process per day
        return dailyProcessCount < 1
    }
    
    var remainingProcesses: Int {
        guard !isPro else { return 999 }
        
        resetIfNewDay()
        return max(0, 1 - dailyProcessCount)
    }
    
    // MARK: - Init
    private init() {
        self.isPro = UserDefaults.standard.bool(forKey: Keys.isPro)
        self.dailyProcessCount = UserDefaults.standard.integer(forKey: Keys.dailyProcessCount)
        self.dailyCheckInEnabled = UserDefaults.standard.object(forKey: Keys.dailyCheckInEnabled) as? Bool ?? true
    }
    
    // MARK: - Public Methods
    
    /// Check if it's a new day and reset the daily count if needed
    func resetIfNewDay() {
        let lastStamp = UserDefaults.standard.string(forKey: Keys.lastProcessDayStamp) ?? ""
        let today = todayStamp
        
        if lastStamp != today {
            dailyProcessCount = 0
            UserDefaults.standard.set(today, forKey: Keys.lastProcessDayStamp)
        }
    }
    
    /// Increment the daily process usage count
    func incrementProcessUsage() {
        resetIfNewDay()
        dailyProcessCount += 1
        UserDefaults.standard.set(todayStamp, forKey: Keys.lastProcessDayStamp)
    }
    
    /// Unlock Pro features
    func unlockPro() {
        isPro = true
    }
    
    /// Check if user can view decision details (Pro only)
    func canViewDecisionDetails() -> Bool {
        return isPro
    }
    
    /// Check if user can view full themes (Pro only)
    func canViewFullThemes() -> Bool {
        return isPro
    }
    
    /// Check if user can use cloud sync (Pro only)
    func canUseCloudSync() -> Bool {
        return isPro
    }
}
