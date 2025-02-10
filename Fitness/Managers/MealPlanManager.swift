import FirebaseFirestore
import FirebaseStorage
import UIKit

class MealPlanManager {
    static let shared = MealPlanManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    /// Uploads a meal plan document to Firestore.
    func uploadMealPlan(clientId: String,
                        day: String,
                        mealType: String,
                        mealName: String,
                        ingredients: [Ingredient],
                        image: UIImage?) async throws {
        var imageUrl: String? = nil
        
        // If an image is provided, upload it to Firebase Storage.
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let fileName = UUID().uuidString + ".jpg"
            let storageRef = storage.reference().child("meal_plans/\(fileName)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            imageUrl = try await storageRef.downloadURL().absoluteString
        }
        
        // Prepare the meal plan data.
        let mealPlanData: [String: Any] = [
            "clientId": clientId,
            "day": day,
            "mealType": mealType,
            "mealName": mealName,
            // Convert ingredients array into an array of dictionaries.
            "ingredients": ingredients.map { [
                "name": $0.name,
                "amount": $0.amount,
                "protein": $0.protein,
                "calories": $0.calories,
                "carbs": $0.carbs,
                "fats": $0.fats
            ] },
            "imageUrl": imageUrl as Any,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        let docRef = try await db.collection("meal_plans").addDocument(data: mealPlanData)
        print("Meal plan uploaded with document id: \(docRef.documentID)")
    }
}
