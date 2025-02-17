import Foundation
import FirebaseFirestoreCombineSwift
import FirebaseFirestore
import Firebase

struct MealPlan: Codable, Identifiable {
    @DocumentID var id: String?
    let clientId: String
    let day: String         // e.g. "Monday"
    let mealType: String    // e.g. "Meal 1", "Meal 2", "Meal 3", "Snack 1", or "Snack 2"
    let mealName: String
    let imageUrl: String?   // Optional URL string for the image
    let ingredients: [Ingredient]  // List of ingredients
    let timestamp: Date?
}

