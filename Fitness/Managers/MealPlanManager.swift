import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import UIKit

class MealPlanManager {
    static let shared = MealPlanManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    /// Updates (or creates) the daily meal plan for a specific client, day, and meal slot.
    func updateDailyMealPlan(clientId: String,
                             day: String,
                             mealSlot: String, // e.g. "Meal 1", "Snack 1", etc.
                             mealName: String,
                             ingredients: [Ingredient],
                             image: UIImage?) async throws {
        var imageUrl: String? = nil
        
        // Upload the image if provided
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let fileName = UUID().uuidString + ".jpg"
            let storageRef = storage.reference().child("daily_meal_plans/\(clientId)/\(day)/\(mealSlot)/\(fileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            imageUrl = try await storageRef.downloadURL().absoluteString
        }
        
        // Prepare the meal dictionary to be stored - simplified for new Ingredient model
        let mealData: [String: Any] = [
            "mealName": mealName,
            "imageUrl": imageUrl as Any,
            "ingredients": ingredients.map { [
                "name": $0.name,
                "amount": $0.amount
            ]}
        ]
        
        // Reference to the daily meal plan document in a subcollection under the user.
        let dailyPlanRef = db.collection("users")
                             .document(clientId)
                             .collection("daily_meal_plans")
                             .document(day) // using the day (e.g. "Monday") as the document ID
        
        // Use setData with merge:true so we only update the given meal slot.
        try await dailyPlanRef.setData([
            "clientId": clientId,
            "day": day,
            "meals": [mealSlot: mealData],
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
        
        print("Updated daily meal plan for \(clientId) on \(day) – \(mealSlot)")
    }
}
