import SwiftUI
import FirebaseFirestore
import Combine

class DailyGoalsViewModel: ObservableObject {
    @Published var dailyCalories: String = ""
    @Published var dailySteps: String = ""
    @Published var dailyProtein: String = ""
    @Published var dailyTraining: String = ""
    @State private var goalsViewModel: DailyGoalsViewModel?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init(userId: String) {
        listener = db.collection("users")
            .document(userId)
            .collection("goals")
            .document("dailyGoals")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening to daily goals: \(error.localizedDescription)")
                    return
                }
                guard let data = snapshot?.data() else {
                    print("No daily goals data found for user \(userId).")
                    return
                }
                self.dailyCalories = data["calories"] as? String ?? ""
                self.dailySteps = data["steps"] as? String ?? ""
                self.dailyProtein = data["protein"] as? String ?? ""
                self.dailyTraining = data["training"] as? String ?? ""
            }
    }
    
    deinit {
        listener?.remove()
    }
    
    func saveGoals(userId: String) async throws {
        let docRef = db.collection("users")
            .document(userId)
            .collection("goals")
            .document("dailyGoals")
        
        let data: [String: Any] = [
            "calories": dailyCalories,
            "steps": dailySteps,
            "protein": dailyProtein,
            "training": dailyTraining
        ]
        
        try await docRef.setData(data, merge: true)
        print("Daily goals updated in Firestore.")
    }
}
