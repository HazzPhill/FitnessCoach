//
//  DailyCheckinModel.swift
//  Fitness
//
//  Created by Harry Phillips on 07/03/2025.
//

import Foundation
import FirebaseFirestoreCombineSwift
import FirebaseFirestore

struct CompletedGoal: Codable, Identifiable {
    var id: String = UUID().uuidString
    let goalId: String
    let name: String
    var completed: Bool
}

struct DailyCheckin: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let date: Date?
    let completedGoals: [CompletedGoal]
    let notes: String?
    let imageUrls: [String]?
    @ServerTimestamp var timestamp: Date?
}
