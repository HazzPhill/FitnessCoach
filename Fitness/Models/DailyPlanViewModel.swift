import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import SwiftUI

class DailyMealPlanViewModel: ObservableObject {
    @Published var meal: Meal?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(clientId: String, day: String, mealSlot: String) {
        print("Fetching doc: /users/\(clientId)/daily_meal_plans/\(day)")
        
        listener = db.collection("users")
                     .document(clientId)
                     .collection("daily_meal_plans")
                     .document(day)
                     .addSnapshotListener { [weak self] snapshot, error in
                        if let error = error {
                            print("Error listening: \(error.localizedDescription)")
                            return
                        }
                        guard let data = snapshot?.data() else {
                            print("No data found for client \(clientId) on day \(day)")
                            return
                        }
                        print("Fetched data: \(data)") // Debug log
                        
                        // Look for the "meals" dictionary
                        if let mealsDict = data["meals"] as? [String: Any],
                           let mealData = mealsDict[mealSlot] as? [String: Any] {
                            // Decode it into a Meal
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: mealData)
                                self?.meal = try JSONDecoder().decode(Meal.self, from: jsonData)
                                print("Decoded meal for slot \(mealSlot): \(String(describing: self?.meal))")
                            } catch {
                                print("Error decoding meal: \(error)")
                            }
                        } else {
                            print("No meal found for slot \(mealSlot)")
                            self?.meal = nil
                        }
                     }
    }
    
    deinit {
        listener?.remove()
    }
}
