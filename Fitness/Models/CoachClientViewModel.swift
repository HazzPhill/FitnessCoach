//
//  CoachClientViewModel.swift
//  Fitness
//
//  Created by Harry Phillips on 09/02/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import SwiftUI

class CoachClientsViewModel: ObservableObject {
    @Published var clients: [AuthManager.DBUser] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(groupId: String) {
        listener = db.collection("users")
            .whereField("groupId", isEqualTo: groupId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let documents = snapshot?.documents else { return }
                do {
                    // Decode all users with this groupId.
                    let allUsers = try documents.compactMap { try $0.data(as: AuthManager.DBUser.self) }
                    // Filter to include only clients (if needed)
                    self.clients = allUsers.filter { $0.role == .client }
                } catch {
                    print("Error decoding clients: \(error.localizedDescription)")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
