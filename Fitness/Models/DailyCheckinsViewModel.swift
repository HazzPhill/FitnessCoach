import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseStorage
import Combine
import SwiftUI

// Structure that matches your DailyGoalsViewModel data structure
struct GoalItem: Identifiable {
    var id: String
    var name: String
    var value: String
}

class DailyCheckinsViewModel: ObservableObject {
    @Published var checkins: [DailyCheckin] = []
    @Published var goalsList: [GoalItem] = []
    
    // Map between goal field names and display names
    private let goalDisplayNames = [
        "calories": "Calories",
        "steps": "Steps",
        "protein": "Protein",
        "training": "Training"
    ]
    
    private var listener: ListenerRegistration?
    private var goalsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
        listenForCheckins()
        fetchGoals()
        
        print("DailyCheckinsViewModel initialized with userId: \(userId)")
    }
    
    private func listenForCheckins() {
        listener = db.collection("daily_checkins")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching check-ins: \(error.localizedDescription)")
                    return
                }
                do {
                    let checkins = try snapshot?.documents.compactMap { doc in
                        try doc.data(as: DailyCheckin.self)
                    } ?? []
                    DispatchQueue.main.async {
                        self.checkins = checkins
                    }
                } catch {
                    print("Error decoding check-ins: \(error.localizedDescription)")
                }
            }
    }
    
    private func fetchGoals() {
        // Path matches your DailyGoalsViewModel structure
        goalsListener = db.collection("users")
            .document(userId)
            .collection("goals")
            .document("dailyGoals")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching goals: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No daily goals data found for user \(self.userId).")
                    return
                }
                
                print("Found daily goals data: \(data)")
                
                // Convert the document fields into GoalItems
                var goals: [GoalItem] = []
                
                for (field, value) in data {
                    if let stringValue = value as? String, !stringValue.isEmpty {
                        let displayName = self.goalDisplayNames[field] ?? field.capitalized
                        goals.append(GoalItem(
                            id: field,
                            name: displayName,
                            value: stringValue
                        ))
                    }
                }
                
                DispatchQueue.main.async {
                    self.goalsList = goals
                    print("Updated goalsList with \(goals.count) goals")
                }
            }
    }
    
    func addCheckin(notes: String, completedGoals: [CompletedGoal], images: [UIImage]) async throws {
        // Upload images and get URLs
        var imageUrls: [String] = []
        for image in images {
            if let url = try await uploadCheckinImage(image: image) {
                imageUrls.append(url.absoluteString)
            }
        }
        
        // Create check-in data
        let checkinData: [String: Any] = [
            "userId": userId,
            "date": Timestamp(date: Date()),
            "completedGoals": completedGoals.map { [
                "id": $0.id,
                "goalId": $0.goalId,
                "name": $0.name,
                "completed": $0.completed
            ]},
            "notes": notes,
            "imageUrls": imageUrls,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Save to Firestore
        _ = try await db.collection("daily_checkins").addDocument(data: checkinData)
    }
    
    func updateCheckin(checkinId: String, notes: String, completedGoals: [CompletedGoal], existingImageUrls: [String], newImages: [UIImage]) async throws {
        // Upload new images and get URLs
        var newImageUrls: [String] = []
        for image in newImages {
            if let url = try await uploadCheckinImage(image: image) {
                newImageUrls.append(url.absoluteString)
            }
        }
        
        // Combine existing and new image URLs
        let allImageUrls = existingImageUrls + newImageUrls
        
        // Update check-in data
        let checkinData: [String: Any] = [
            "completedGoals": completedGoals.map { [
                "id": $0.id,
                "goalId": $0.goalId,
                "name": $0.name,
                "completed": $0.completed
            ]},
            "notes": notes,
            "imageUrls": allImageUrls,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Save to Firestore
        try await db.collection("daily_checkins").document(checkinId).updateData(checkinData)
    }
    
    func deleteCheckin(checkinId: String) async throws {
        try await db.collection("daily_checkins").document(checkinId).delete()
    }
    
    private func uploadCheckinImage(image: UIImage) async throws -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("checkin_images/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
    
    deinit {
        listener?.remove()
        goalsListener?.remove()
    }
}
