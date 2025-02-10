import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import SwiftUI

class ClientMealPlansViewModel: ObservableObject {
    @Published var mealPlans: [MealPlan] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(clientId: String) {
        listener = db.collection("meal_plans")
            .whereField("clientId", isEqualTo: clientId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                do {
                    self.mealPlans = try documents.compactMap { try $0.data(as: MealPlan.self) }
                } catch {
                    print("Error decoding meal plans: \(error.localizedDescription)")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
