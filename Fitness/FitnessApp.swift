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
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
