import FirebaseAuth
import Combine
import FirebaseFirestore
import FirebaseStorageCombineSwift
import FirebaseStorage
import FirebaseCore
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentUser: DBUser?
    @Published var currentGroup: Group?
    @Published var latestUpdates: [Update] = [] // Realtime updates listener
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var dailyCheckins: [DailyCheckin] = []
    private var dailyCheckinsListener: ListenerRegistration?
    
    @Published var yearlyUpdates: [Update] = []
    private var yearlyUpdatesListener: ListenerRegistration?
    
    private var userListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var updatesListener: ListenerRegistration?
    
    // MARK: - Models
    
    struct Group: Codable, Identifiable {
        @DocumentID var id: String?
        let name: String
        let code: String
        let coachId: String
        var members: [String]
        var groupImageUrl: String?
        @ServerTimestamp var createdAt: Date?
    }
    
    struct DBUser: Codable {
        let userId: String
        let firstName: String
        let lastName: String
        let email: String
        let role: UserRole
        var groupId: String?
        var profileImageUrl: String?
        @ServerTimestamp var createdAt: Date?
    }
    
    struct Update: Codable, Identifiable {
        @DocumentID var id: String?
        let userId: String
        let name: String
        let weight: Double
        let imageUrl: String?
        let biggestWin: String?
        let issues: String?
        let extraCoachRequest: String?
        let caloriesScore: Double?
        let stepsScore: Double?
        let proteinScore: Double?
        let trainingScore: Double?
        let finalScore: Double?
        @ServerTimestamp var date: Date?
    }
    
    // MARK: - Initialisation
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupListeners(uid: user.uid)
                self?.setupUpdatesListener()
                self?.setupYearlyUpdatesListener()
                self?.setupDailyCheckinsListener(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.currentGroup = nil
                self?.latestUpdates = []
                self?.yearlyUpdates = []
                self?.dailyCheckins = []
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(firstName: String, lastName: String, email: String, role: UserRole, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let user = DBUser(
                userId: result.user.uid,
                firstName: firstName,
                lastName: lastName,
                email: email,
                role: role,
                groupId: nil,
                profileImageUrl: nil,
                createdAt: nil
            )
            try await createDBUser(user: user)
            setupListeners(uid: result.user.uid)
            setupUpdatesListener()
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.signIn(withEmail: email, password: password)
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            self.currentUser = nil
            self.currentGroup = nil
        } catch {
            throw error
        }
    }
    
    func setupYearlyUpdatesListener() {
        if let currentUser = auth.currentUser {
            let calendar = Calendar.current
            let now = Date()
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)),
                  let endOfYear = calendar.date(byAdding: .year, value: 1, to: startOfYear) else {
                return
            }
            
            yearlyUpdatesListener?.remove()
            
            yearlyUpdatesListener = db.collection("updates")
                .whereField("userId", isEqualTo: currentUser.uid)  // Using auth.currentUser.uid directly
                .whereField("date", isGreaterThanOrEqualTo: startOfYear)
                .whereField("date", isLessThan: endOfYear)
                .order(by: "date", descending: false)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self, let snapshot = snapshot else { return }
                    do {
                        let updates = try snapshot.documents.compactMap { try $0.data(as: Update.self) }
                        DispatchQueue.main.async {
                            self.yearlyUpdates = updates
                        }
                    } catch {
                        print("Error decoding yearly updates: \(error)")
                    }
                }
        }
    }
    

    func cleanupOldCheckins() async {
        guard let userId = currentUser?.userId else { return }
        
        do {
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            
            // Check if today is Monday (weekday == 2 in Calendar, as Sunday == 1)
            let isMonday = (weekday == 2)
            
            if isMonday {
                // On Monday, get ALL check-ins for this user regardless of date
                let snapshot = try await db.collection("daily_checkins")
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                
                // Delete each check-in
                for document in snapshot.documents {
                    try await db.collection("daily_checkins").document(document.documentID).delete()
                    print("Deleted check-in for Monday cleanup: \(document.documentID)")
                }
                
                print("Completed Monday cleanup of ALL daily check-ins")
            } else {
                // On other days, just delete check-ins older than today (original behavior)
                let startOfToday = calendar.startOfDay(for: today)
                
                let snapshot = try await db.collection("daily_checkins")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("date", isLessThan: startOfToday)
                    .getDocuments()
                
                // Delete each check-in
                for document in snapshot.documents {
                    try await db.collection("daily_checkins").document(document.documentID).delete()
                    print("Deleted old check-in: \(document.documentID)")
                }
                
                print("Completed regular cleanup of old daily check-ins")
            }
            
            // Refresh the local cache after deletion
            refreshDailyCheckins()
        } catch {
            print("Error cleaning up daily check-ins: \(error.localizedDescription)")
        }
    }
    
    func setupDailyCheckinsListener(uid: String) {
        // Clean up existing listener
        dailyCheckinsListener?.remove()
        
        // Set up a new listener
        dailyCheckinsListener = db.collection("daily_checkins")
            .whereField("userId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching daily check-ins: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("Invalid snapshot returned for daily check-ins")
                    return
                }
                
                // Important: Explicitly handle empty snapshot case
                if snapshot.documents.isEmpty {
                    print("No documents found in daily check-ins snapshot")
                    DispatchQueue.main.async {
                        withAnimation {
                            self.dailyCheckins = []
                        }
                    }
                    return
                }
                
                do {
                    let checkins = try snapshot.documents.compactMap { doc -> DailyCheckin? in
                        return try doc.data(as: DailyCheckin.self)
                    }
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            self.dailyCheckins = checkins
                        }
                        print("Updated dailyCheckins with \(checkins.count) items")
                    }
                } catch {
                    print("Error decoding daily check-ins: \(error.localizedDescription)")
                }
            }
    }

    // Add this function to refresh check-ins on demand
    func refreshDailyCheckins() {
        guard let userId = currentUser?.userId else {
            print("Cannot refresh check-ins: No current user")
            return
        }
        
        // Re-setup the listener to force a refresh
        setupDailyCheckinsListener(uid: userId)
    }

    func joinGroup(code: String) async throws {
        guard let user = auth.currentUser else {
            print("❌ Join Group Error: No authenticated user")
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔍 Searching for group with code: \(code.uppercased())")
            
            // First, find the group with this code - using uppercased code
            let snapshot = try await db.collection("groups")
                .whereField("code", isEqualTo: code.uppercased())
                .getDocuments()
            
            guard let groupDoc = snapshot.documents.first else {
                print("❌ Join Group Error: No group found with code \(code.uppercased())")
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid group code"])
            }
            
            let groupId = groupDoc.documentID
            print("✅ Found group with ID: \(groupId)")
            
            // Print current members for debugging
            if let currentMembers = groupDoc.data()["members"] as? [String] {
                print("👥 Current group members: \(currentMembers)")
            }
            
            // Update both the group and user documents
            print("📝 Updating group and user documents")
            
            // First update the user document
            print("👤 Updating user document for ID: \(user.uid) with groupId: \(groupId)")
            try await db.collection("users").document(user.uid).updateData([
                "groupId": groupId
            ])
            
            // Then update the group document
            print("👥 Adding user \(user.uid) to group \(groupId) members")
            try await db.collection("groups").document(groupId).updateData([
                "members": FieldValue.arrayUnion([user.uid])
            ])
            
            print("✅ Database updates successful")
            
            // Get the updated group document
            let updatedGroup = try await db.collection("groups").document(groupId).getDocument(as: Group.self)
            
            // Update local state immediately
            if var updatedUser = self.currentUser {
                updatedUser.groupId = groupId
                print("⚙️ Updating local state: currentUser.groupId = \(groupId)")
                self.currentUser = updatedUser
                self.currentGroup = updatedGroup
                print("⚙️ Updated currentGroup: \(String(describing: updatedGroup.name)) with \(updatedGroup.members.count) members")
            }
            
            // Re-setup listeners to ensure data is fresh
            print("🔄 Re-setting up group listener")
            setupGroupListener(groupId: groupId)
            
            print("✅ Successfully joined group: \(updatedGroup.name)")
        } catch {
            print("❌ Join Group Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createGroup(name: String) async throws -> Group {
        guard let user = currentUser, user.role == .coach else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])
        }
        let groupCode = generateGroupCode()
        let group = Group(
            name: name,
            code: groupCode,
            coachId: user.userId,
            members: [user.userId],
            groupImageUrl: nil,
            createdAt: nil
        )
        
        let groupRef: DocumentReference = try await withCheckedThrowingContinuation { continuation in
            db.collection("groups")
                .addDocument(from: group)
                .sink { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { docRef in
                    continuation.resume(returning: docRef)
                }
                .store(in: &self.cancellables)
        }
        
        try await db.collection("users").document(user.userId).updateData([
            "groupId": groupRef.documentID
        ])
        
        return Group(
            id: groupRef.documentID,
            name: name,
            code: groupCode,
            coachId: user.userId,
            members: [user.userId],
            groupImageUrl: nil,
            createdAt: Date()
        )
    }
    
    private func createDBUser(user: DBUser) async throws {
        let document = db.collection("users").document(user.userId)
        try document.setData(from: user)
    }
    
    func setupListeners(uid: String) {
        userListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                do {
                    self.currentUser = try snapshot?.data(as: DBUser.self)
                    if let groupId = self.currentUser?.groupId {
                        self.setupGroupListener(groupId: groupId)
                    } else {
                        self.currentGroup = nil
                        self.groupListener = nil
                    }
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        setupDailyCheckinsListener(uid: uid)
    }
    
    private func setupGroupListener(groupId: String) {
        groupListener = db.collection("groups").document(groupId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let snapshot = snapshot else { return }
                self.currentGroup = try? snapshot.data(as: Group.self)
            }
    }
    
    func setupUpdatesListener() {
        if let currentUser = auth.currentUser {
            print("Setting up updates for: \(currentUser.uid)")
            
            updatesListener?.remove()
            
            updatesListener = db.collection("updates")
                .whereField("userId", isEqualTo: currentUser.uid)  // Using auth.currentUser.uid directly
                .order(by: "date", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self, let snapshot = snapshot else { return }
                    do {
                        let updates = try snapshot.documents.compactMap { doc -> Update? in
                            try doc.data(as: Update.self)
                        }
                        DispatchQueue.main.async {
                            self.latestUpdates = updates
                            print("Found \(updates.count) updates for current user")
                        }
                    } catch {
                        print("Error decoding updates: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    func addUpdate(name: String, weight: Double, image: UIImage?, biggestWin: String, issues: String, extraCoachRequest: String, finalScore: Double) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        var imageUrl: String? = nil
        if let image = image {
            if let url = try await uploadUpdateImage(image: image) {
                imageUrl = url.absoluteString
            }
        }
        let updateData: [String: Any] = [
            "userId": currentUser.userId,
            "name": name,
            "weight": weight,
            "imageUrl": imageUrl as Any,
            "biggestWin": biggestWin,
            "issues": issues,
            "extraCoachRequest": extraCoachRequest,
            "finalScore": finalScore,
            "date": Timestamp(date: Date())
        ]
        _ = try await db.collection("updates").addDocument(data: updateData)
    }
    
    private func uploadUpdateImage(image: UIImage) async throws -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("updates/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url
    }
    
    func updateGroupPhoto(image: UIImage) async throws {
        guard let groupId = currentGroup?.id else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("groupImages/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        try await db.collection("groups").document(groupId).updateData([
            "groupImageUrl": url.absoluteString
        ])
    }
    
    func updateProfilePicture(image: UIImage) async throws {
        guard let currentUser = currentUser else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = storage.reference().child("profileImages/\(fileName)")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        try await db.collection("users").document(currentUser.userId).updateData([
            "profileImageUrl": url.absoluteString
        ])
        self.currentUser = try await db.collection("users").document(currentUser.userId).getDocument(as: DBUser.self)
    }
    
    // MARK: - Daily Checkins Operations
    
    func uploadDailyCheckinImage(image: UIImage) async throws -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "dailyCheckins/\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child(fileName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let url = try await storageRef.downloadURL()
        return url
    }
    
    func addDailyCheckin(data: [String: Any]) async throws {
        _ = try await db.collection("daily_Checkins").addDocument(data: data)
    }
    
    func updateDailyCheckin(documentID: String, data: [String: Any]) async throws {
        try await db.collection("daily_Checkins").document(documentID).setData(data, merge: true)
    }
    
    func deleteDailyCheckin(documentID: String) async throws {
        try await db.collection("daily_checkins").document(documentID).delete()
    }
    
    // Improved update method with debugging
    func updateUpdate(
        updateId: String,
        name: String,
        weight: Double,
        newImage: UIImage?,
        existingImageUrl: String?,
        biggestWin: String,
        issues: String,
        extraCoachRequest: String,
        caloriesScore: Double,
        stepsScore: Double,
        proteinScore: Double,
        trainingScore: Double,
        finalScore: Double
    ) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        print("🔄 Starting update for document ID: \(updateId)")
        
        var imageUrl: String? = existingImageUrl
        
        // If we have a new image, upload it
        if let newImage = newImage {
            print("📸 Uploading new image...")
            if let url = try await uploadUpdateImage(image: newImage) {
                imageUrl = url.absoluteString
                print("✅ Image uploaded, URL: \(imageUrl ?? "nil")")
            } else {
                print("⚠️ Image upload returned nil URL")
            }
        } else {
            print("ℹ️ Using existing image URL: \(imageUrl ?? "nil")")
        }
        
        // Update data for the document
        let updateData: [String: Any] = [
            "userId": currentUser.userId,
            "name": name,
            "weight": weight,
            "imageUrl": imageUrl as Any,
            "biggestWin": biggestWin,
            "issues": issues,
            "extraCoachRequest": extraCoachRequest,
            "caloriesScore": caloriesScore,
            "stepsScore": stepsScore,
            "proteinScore": proteinScore,
            "trainingScore": trainingScore,
            "finalScore": finalScore
        ]
        
        print("📝 Update data prepared: \(updateData)")
        
        // First verify the document exists and the current user owns it
        do {
            let doc = try await db.collection("updates").document(updateId).getDocument()
            
            if !doc.exists {
                print("❌ Document does not exist: \(updateId)")
                throw NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Update not found"])
            }
            
            guard let docData = doc.data(), let docUserId = docData["userId"] as? String else {
                print("❌ Document data missing userId field")
                throw NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid document data"])
            }
            
            if docUserId != currentUser.userId {
                print("⛔ Permission denied - document userId: \(docUserId) does not match current user: \(currentUser.userId)")
                throw NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "You do not have permission to update this record"])
            }
            
            print("✅ Document exists and user has permission to update it")
            
            // Try either updateData or setData
            do {
                print("📤 Attempting updateData...")
                try await db.collection("updates").document(updateId).updateData(updateData)
                print("✅ Document updated successfully")
            } catch let updateError {
                print("⚠️ updateData failed: \(updateError.localizedDescription), trying setData...")
                
                // If updateData fails, try setData with merge
                do {
                    try await db.collection("updates").document(updateId).setData(updateData, merge: true)
                    print("✅ Document updated successfully using setData with merge")
                } catch let setError {
                    print("❌ setData also failed: \(setError.localizedDescription)")
                    
                    // Check your Firebase security rules!
                    print("🔒 IMPORTANT: Verify your Firebase security rules allow updates to the 'updates' collection!")
                    print("🔒 Current rule may be set to: allow update, delete: if false;")
                    print("🔒 Change to: allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;")
                    
                    throw setError
                }
            }
            
            // Refresh the updates to show the changes
            print("🔄 Refreshing updates list...")
            setupUpdatesListener()
            setupYearlyUpdatesListener()
            print("✅ Update complete")
            
        } catch {
            print("❌ Error during update process: \(error.localizedDescription)")
            throw error
        }
    }

    func deleteUpdate(updateId: String) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // Get the update document to check ownership
        let document = try await db.collection("updates").document(updateId).getDocument()
        
        // Verify the current user owns this update
        guard let userId = document.data()?["userId"] as? String, userId == currentUser.userId else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You don't have permission to delete this update"])
        }
        
        // Delete the update document
        try await db.collection("updates").document(updateId).delete()
        
        // Refresh the updates
        setupUpdatesListener()
        setupYearlyUpdatesListener() // Also refresh the yearly updates since this might affect them
    }
    
    func scheduleWeeklyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Checkin"
        content.body = "Have you done your weekly checkin?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 9     // 9 AM (adjust if you want a different time)
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyCheckin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly notification: \(error)")
            }
        }
    }

    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Checkin"
        content.body = "Have you done your daily checkin?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20  // 8 PM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error)")
            }
        }
    }
    
    
    
    // MARK: - Helper Methods
    
    private func generateGroupCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }
    
    private func handleError(_ error: Error) {
        let nsError = error as NSError
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            errorMessage = "Unknown error occurred"
            return
        }
        switch errorCode {
        case .emailAlreadyInUse:
            errorMessage = "Email already in use"
        case .invalidEmail:
            errorMessage = "Invalid email format"
        case .weakPassword:
            errorMessage = "Password needs at least 6 characters"
        case .wrongPassword:
            errorMessage = "Incorrect password"
        case .userNotFound:
            errorMessage = "Account not found"
        default:
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
    }
}

extension AuthManager {
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

extension String {
    func capitalisedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}

enum UserRole: String, Codable, CaseIterable {
    case coach, client
}

// Add this method to your AuthManager class

extension AuthManager {
    func updateUserName(firstName: String, lastName: String) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        // Update in Firestore
        let userRef = db.collection("users").document(currentUser.userId)
        try await userRef.updateData([
            "firstName": firstName,
            "lastName": lastName
        ])
        
        // Create a new DBUser with updated values
        self.currentUser = DBUser(
            userId: currentUser.userId,
            firstName: firstName,
            lastName: lastName,
            email: currentUser.email,
            role: currentUser.role,
            groupId: currentUser.groupId,
            profileImageUrl: currentUser.profileImageUrl,
            createdAt: currentUser.createdAt
        )
    }
}

// MARK: - Extension to AuthManager for group actions
extension AuthManager {
    // For clients to leave a group
    func leaveGroup() async throws {
        guard let user = auth.currentUser, let currentUser = self.currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        guard let groupId = currentUser.groupId, let group = self.currentGroup else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not in a group"])
        }
        
        // Create a batch operation
        let batch = db.batch()
        
        // 1. Remove user from group's members array
        let groupRef = db.collection("groups").document(groupId)
        batch.updateData([
            "members": FieldValue.arrayRemove([user.uid])
        ], forDocument: groupRef)
        
        // 2. Remove groupId from user's document
        let userRef = db.collection("users").document(user.uid)
        batch.updateData([
            "groupId": FieldValue.delete()
        ], forDocument: userRef)
        
        // Execute the batch
        try await batch.commit()
        
        // Update the local state
        if var updatedUser = self.currentUser {
            updatedUser.groupId = nil
            self.currentUser = updatedUser
            self.currentGroup = nil
        }
    }
    
    // For coaches to delete a group
    func deleteGroup() async throws {
        guard let user = auth.currentUser, let currentUser = self.currentUser, currentUser.role == .coach else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Only coaches can delete groups"])
        }
        
        guard let groupId = currentUser.groupId, let group = self.currentGroup else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No group to delete"])
        }
        
        // Verify this coach owns the group
        guard group.coachId == user.uid else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You can only delete groups you own"])
        }
        
        // Get all members of the group
        let groupRef = db.collection("groups").document(groupId)
        let groupDoc = try await groupRef.getDocument()
        guard let groupData = groupDoc.data(), let members = groupData["members"] as? [String] else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get group members"])
        }
        
        // Create a batch operation
        let batch = db.batch()
        
        // 1. Remove groupId from all member documents
        for memberId in members {
            let memberRef = db.collection("users").document(memberId)
            batch.updateData([
                "groupId": FieldValue.delete()
            ], forDocument: memberRef)
        }
        
        // 2. Delete the group document
        batch.deleteDocument(groupRef)
        
        // Execute the batch
        try await batch.commit()
        
        // Update the local state
        if var updatedUser = self.currentUser {
            updatedUser.groupId = nil
            self.currentUser = updatedUser
            self.currentGroup = nil
        }
    }
}
