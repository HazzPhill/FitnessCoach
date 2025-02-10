//
//  MealPlanViewModel.swift
//  Fitness
//
//  Created by Harry Phillips on 09/02/2025.
//

import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine
import SwiftUI

class MealPlanViewModel: ObservableObject {
    @Published var mealPlan: MealPlan?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    /// Listens for a meal plan document matching clientId, day, and mealType.
    init(clientId: String, day: String, mealType: String) {
        print("Querying meal_plans where clientId = \(clientId), day = \(day), mealType = \(mealType)")
        listener = db.collection("meal_plans")
            .whereField("clientId", isEqualTo: clientId)
            .whereField("day", isEqualTo: day)
            .whereField("mealType", isEqualTo: mealType)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching meal plan: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    print("Found \(snapshot.documents.count) documents for clientId: \(clientId), day: \(day), mealType: \(mealType)")
                }
                if let document = snapshot?.documents.first {
                    do {
                        self.mealPlan = try document.data(as: MealPlan.self)
                        print("Decoded meal plan: \(String(describing: self.mealPlan))")
                    } catch {
                        print("Error decoding meal plan: \(error.localizedDescription)")
                    }
                } else {
                    self.mealPlan = nil
                    print("No matching meal plan document found.")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
