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
            
            // Add this to your app's initialization (like in your App struct's init)
            for family in UIFont.familyNames.sorted() {
                print("Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family).sorted() {
                    print("   Font: \(name)")
                }
            }
        }
        
    }
    
    // Add this method to check for Monday cleanup when app becomes active
       func applicationDidBecomeActive(_ application: UIApplication) {
           // Check and run Monday cleanup when app becomes active
           AuthManager.shared.checkAndRunMondayCleanup()
       }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
    }
}
