//
//  FitnessApp.swift
//  Fitness
//
//  Created by Harry Phillips on 03/02/2025.
//

import SwiftUI
import SwiftData
import Firebase

@main
struct FitnessApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted!")
            } else {
                print("Notification permission denied.")
            }
        }
        
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
    }
}
