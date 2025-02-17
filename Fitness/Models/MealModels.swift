//
//  MealModels.swift
//  Fitness
//
//  Created by Harry Phillips on 17/02/2025.
//

import FirebaseFirestoreCombineSwift
import Firebase
import FirebaseFirestore
import FirebaseStorage
import Foundation
import SwiftUI

// Ingredient model
struct Ingredient: Codable, Identifiable {
    var id: String? = UUID().uuidString  // Mark id as optional with a default value
    var name: String
    var amount: String
    var protein: String
    var calories: String
    var carbs: String
    var fats: String
}

// Meal model – represents a single meal (or snack)
struct Meal: Codable, Identifiable {
    var id: String { UUID().uuidString }
    let mealName: String
    let imageUrl: String?
    let ingredients: [Ingredient]
}

// DailyMealPlan model – one document per client per day
struct DailyMealPlan: Codable, Identifiable {
    @DocumentID var id: String?
    let clientId: String
    let day: String  // e.g. "Monday"
    let meals: [String: Meal] // Keys: "Meal 1", "Meal 2", "Meal 3", "Snack 1", "Snack 2"
    let createdAt: Date?
    let updatedAt: Date?
}

