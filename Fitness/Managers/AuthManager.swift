import FirebaseAuth
import Combine
import FirebaseFirestore
import FirebaseStorageCombineSwift
import FirebaseStorage
import FirebaseCore
import SwiftUI

// MARK: - AuthManager Class
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    // MARK: - Firebase Properties
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
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
    
    // MARK: - Data Models
    
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
        // Raw ratings from dropdowns
        let caloriesRating: Int?    // e.g., 5 (out of 7)
        let stepsRating: Int?       // e.g., 6 (out of 7)
        let proteinRating: Int?     // e.g., 4 (out of 7)
        let trainingRating: Int?    // e.g., 3 (out of 5)
        // Mapped scores for final score calculation
        let caloriesScore: Double?  // e.g., 1.8
        let stepsScore: Double?     // e.g., 2.0
        let proteinScore: Double?   // e.g., 1.4
        let trainingScore: Double?  // e.g., 1.5
        let finalScore: Double?     // e.g., 6.7 (sum of mapped scores)
        @ServerTimestamp var date: Date?
    }
    
    // MARK: - Initialization
    
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
        
        // Schedule all notifications including the Monday cleanup
        scheduleWeeklyNotification()
        scheduleDailyNotification()
        scheduleMondayCleanupNotification()
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
    

    // MARK: - Notification Scheduling
    
    // Schedule a notification for 9am Monday
    func scheduleMondayCleanupNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Reset"
        content.body = "Your daily check-ins have been reset for the new week."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Monday (Calendar uses 1 for Sunday, 2 for Monday)
        dateComponents.hour = 9     // 9 AM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "mondayCleanup", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling Monday cleanup notification: \(error)")
            } else {
                print("Monday 9am cleanup notification scheduled successfully")
            }
        }
    }

    // Check if it's Monday after 9AM
    func isMondayAfter9AM() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        // It's Monday (2) after 9am
        return weekday == 2 && hour >= 9
    }

    // Check and run Monday cleanup if needed
    func checkAndRunMondayCleanup() {
        if isMondayAfter9AM() {
            print("It's Monday after 9AM - running weekly cleanup")
            Task {
                await cleanupOldCheckins()
            }
        }
    }

    // MARK: - Cleanup Functions
    
    func cleanupOldCheckins() async {
        guard let userId = currentUser?.userId else { return }
        
        do {
            let calendar = Calendar.current
            let now = Date()
            let weekday = calendar.component(.weekday, from: now)
            let hour = calendar.component(.hour, from: now)
            
            print("🧹 CLEANUP: Running check - Current weekday: \(weekday) (2=Monday), hour: \(hour)")
            
            // Check if today is Monday (weekday == 2) and after 9am
            let isMonday = (weekday == 2)
            let isAfter9AM = (hour >= 9)
            
            if isMonday && isAfter9AM {
                print("🧹 CLEANUP: It's Monday after 9AM - running weekly cleanup")
                
                // IMPORTANT: Calculate start of today (Monday) at midnight
                let startOfToday = calendar.startOfDay(for: now)
                
                // Only delete check-ins BEFORE today (previous week's check-ins)
                // This preserves any check-ins added today (Monday)
                let snapshot = try await db.collection("daily_checkins")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("date", isLessThan: startOfToday) // This is the key change
                    .getDocuments()
                
                print("📊 CLEANUP: Found \(snapshot.documents.count) check-ins from previous week")
                
                // Delete each check-in from previous week
                var deleteCount = 0
                for document in snapshot.documents {
                    try await db.collection("daily_c®heckins").document(document.documentID).delete()
                    deleteCount += 1
                    print("✅ CLEANUP: Deleted old check-in: \(document.documentID)")
                }
                
                print("🧹 CLEANUP: Monday cleanup completed - Deleted \(deleteCount) check-ins from previous week")
            } else {
                // On other days or before 9am, just delete check-ins older than today (original behavior)
                let startOfToday = calendar.startOfDay(for: now)
                
                let snapshot = try await db.collection("daily_checkins")
                    .whereField("userId", isEqualTo: userId)
                    .whereField("date", isLessThan: startOfToday)
                    .getDocuments()
                
                // Delete each check-in
                for document in snapshot.documents {
                    try await db.collection("daily_checkins").document(document.documentID).delete()
                    print("✅ CLEANUP: Deleted old check-in: \(document.documentID)")
                }
                
                print("🧹 CLEANUP: Regular cleanup completed")
            }
            
            // Also try checking the alternative collection name (dailyCheckins) if relevant
            // This is just in case your app uses both collection names
            
            // Refresh the local cache after deletion
            refreshDailyCheckins()
        } catch {
            print("❌ CLEANUP Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Daily Check-ins Management
    
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

    // MARK: - Group Management
    
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
    
    // MARK: - Listeners Setup
    
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
    
    // Replace the setupUpdatesListener method in AuthManager.swift
    func setupUpdatesListener() {
        if let currentUser = auth.currentUser {
            print("Setting up updates for: \(currentUser.uid)")
            
            updatesListener?.remove()
            
            // Use a more robust query that's less likely to have timing issues
            let calendar = Calendar.current
            
            // Get date from 3 months ago to ensure we capture all recent updates
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            
            updatesListener = db.collection("updates")
                .whereField("userId", isEqualTo: currentUser.uid)
                .whereField("date", isGreaterThan: Timestamp(date: threeMonthsAgo))
                .order(by: "date", descending: true)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("❌ Error fetching updates: \(error.localizedDescription)")
                        return
                    }
                    
                    if let snapshot = snapshot {
                        print("📊 Found \(snapshot.documents.count) update documents in snapshot")
                    }
                    
                    do {
                        let updates = try snapshot?.documents.compactMap { doc -> AuthManager.Update? in
                            // Log each document ID to help with debugging
                            print("💾 Processing update document: \(doc.documentID)")
                            return try doc.data(as: AuthManager.Update.self)
                        } ?? []
                        
                        DispatchQueue.main.async {
                            self.latestUpdates = updates
                            print("✅ Updated latestUpdates with \(updates.count) items")
                            
                            // Log the most recent update for debugging
                            if let mostRecent = updates.first, let date = mostRecent.date {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .full
                                formatter.timeStyle = .medium
                                print("📅 Most recent update: \(formatter.string(from: date))")
                            }
                        }
                    } catch {
                        print("❌ Error decoding updates: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    // MARK: - Update Management
    
    func addUpdate(
        name: String,
        weight: Double,
        image: UIImage?,
        biggestWin: String?,
        issues: String?,
        extraCoachRequest: String?,
        caloriesRating: Int?,
        stepsRating: Int?,
        proteinRating: Int?,
        trainingRating: Int?,
        caloriesScore: Double?,
        stepsScore: Double?,
        proteinScore: Double?,
        trainingScore: Double?,
        finalScore: Double?
    ) async throws {
        guard let currentUser = auth.currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        var imageUrl: String? = nil
        if let image = image {
            if let url = try await uploadUpdateImage(image: image) {
                imageUrl = url.absoluteString
            }
        }
        
        var updateData: [String: Any] = [
            "userId": currentUser.uid,
            "name": name,
            "weight": weight,
            "date": FieldValue.serverTimestamp(),
            "caloriesRating": caloriesRating as Any,
            "stepsRating": stepsRating as Any,
            "proteinRating": proteinRating as Any,
            "trainingRating": trainingRating as Any,
            "caloriesScore": caloriesScore as Any,
            "stepsScore": stepsScore as Any,
            "proteinScore": proteinScore as Any,
            "trainingScore": trainingScore as Any,
            "finalScore": finalScore as Any
        ]
        
        if let imageUrl = imageUrl { updateData["imageUrl"] = imageUrl }
        if let biggestWin = biggestWin { updateData["biggestWin"] = biggestWin }
        if let issues = issues { updateData["issues"] = issues }
        if let extraCoachRequest = extraCoachRequest { updateData["extraCoachRequest"] = extraCoachRequest }
        
        _ = try await db.collection("updates").addDocument(data: updateData)
    }

        // Helper function to upload image
        private func uploadUpdateImage(image: UIImage) async throws -> URL? {
            let storageRef = storage.reference().child("updates/\(UUID().uuidString).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            return try await storageRef.downloadURL()
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
    
    
    // MARK: - Cleanup Operations
    
    // Add this function to AuthManager.swift to force a manual cleanup
    func forceCleanupAllDailyCheckins() async {
        guard let userId = currentUser?.userId else {
            print("❌ Cannot perform cleanup: No current user")
            return
        }
        
        print("🧹 Starting FORCED cleanup of ALL daily check-ins for user: \(userId)")
        
        do {
            // Try with the main collection name
            var snapshot = try await db.collection("daily_checkins")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            print("📊 Found \(snapshot.documents.count) check-ins in 'daily_checkins' collection")
            
            // Delete each check-in
            for document in snapshot.documents {
                try await db.collection("daily_checkins").document(document.documentID).delete()
                print("✅ Deleted check-in: \(document.documentID)")
            }
            
            // Also try with alternative capitalization (dailyCheckins)
            snapshot = try await db.collection("dailyCheckins")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            print("📊 Found \(snapshot.documents.count) check-ins in 'dailyCheckins' collection")
            
            // Delete each check-in
            for document in snapshot.documents {
                try await db.collection("dailyCheckins").document(document.documentID).delete()
                print("✅ Deleted check-in: \(document.documentID)")
            }
            
            // Refresh the local cache after deletion
            print("🔄 Refreshing local cache")
            refreshDailyCheckins()
            
            print("✅ Manual cleanup completed")
        } catch {
            print("❌ Error during forced cleanup: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Refreshing
    
    // Also enhance the refreshWeeklyUpdates method
    func refreshWeeklyUpdates() {
        print("🔄 Manually refreshing weekly updates")
        
        // Remove any existing listeners first to ensure clean state
        updatesListener?.remove()
        yearlyUpdatesListener?.remove()
        
        // Force empty the arrays first to trigger UI updates
        DispatchQueue.main.async {
            self.latestUpdates = []
            self.yearlyUpdates = []
            
            // Small delay before re-setting up listeners
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Re-setup the listeners
                self.setupUpdatesListener()
                self.setupYearlyUpdatesListener()
                print("✅ Update listeners refreshed completely")
            }
        }
    }

    // MARK: - Update Deletion
    
    func deleteUpdate(updateId: String) async throws {
        guard let currentUser = currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        print("🗑️ Attempting to delete update with ID: \(updateId)")
        
        // Get the update document to check ownership
        let document = try await db.collection("updates").document(updateId).getDocument()
        
        // Log the document data for debugging
        if let data = document.data() {
            print("📄 Document data: \(data)")
        } else {
            print("❌ Document not found or empty")
        }
        
        // Verify the current user owns this update
        if let userId = document.data()?["userId"] as? String {
            print("👤 Document userId: \(userId), Current userId: \(currentUser.userId)")
            
            if userId != currentUser.userId {
                print("⛔ Permission denied - user doesn't own this update")
                throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You don't have permission to delete this update"])
            }
        } else {
            print("⚠️ No userId found in the document")
        }
        
        // Delete the update document
        print("✅ Proceeding with deletion...")
        try await db.collection("updates").document(updateId).delete()
        print("✅ Document deleted successfully")
        
        // Refresh the updates
        setupUpdatesListener()
        setupYearlyUpdatesListener() // Also refresh the yearly updates since this might affect them
        
        print("🔄 Update listeners refreshed")
    }
    
    // MARK: - Notification Scheduling Methods
    
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

// MARK: - Weekly Check-in Status Extension
extension AuthManager {
    // Enum to represent the weekly check-in status
    enum WeeklyCheckinStatus {
        case eligible        // User can submit a check-in (it's Saturday or Sunday)
        case completed       // User has already completed this week's check-in
        case missed          // User missed this week's check-in window
        case waitingForNext  // Not eligible yet, waiting for next check-in window
    }
    
    // MARK: - UPDATED: Weekly Check-in Status Methods
    
    // MARK: - UPDATED: Allows weekly check-ins on any weekend day of each week
    // This ensures if someone checked in on Sunday, they can check in the following Saturday
    
    // Check the status of weekly check-ins
    func getWeeklyCheckinStatus() -> WeeklyCheckinStatus {
        // Get current date
        let now = Date()
        let calendar = Calendar.current
        
        print("📅 TIMEZONE DEBUG: Calendar timezone: \(calendar.timeZone)")
        print("📅 TIMEZONE DEBUG: Current date/time: \(now)")
        
        // Get the current weekday (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
        let weekday = calendar.component(.weekday, from: now)
        
        // ENHANCED DEBUG: Detailed weekday logging
        print("📅 WEEKDAY DEBUG: Raw weekday value: \(weekday)")
        print("📅 WEEKDAY DEBUG: Is this a Saturday? \(weekday == 7)")
        print("📅 WEEKDAY DEBUG: Is this a Sunday? \(weekday == 1)")
        
        // FIXED: Explicitly set weekend days and always force weekends to be eligible
        let isSaturday = (weekday == 7)
        let isSunday = (weekday == 1)
        let isWeekend = (isSaturday || isSunday)
        
        print("📅 WEEKEND DEBUG: isSaturday: \(isSaturday), isSunday: \(isSunday)")
        print("📅 WEEKEND DEBUG: isWeekend calculated as: \(isWeekend)")
        
        // Calculate the start of the CURRENT week (Sunday)
        let today = calendar.startOfDay(for: now)
        
        // Get start of this week based on current weekday
        let startOfWeek: Date
        if isSunday {
            // Today is Sunday - start of the week is today
            startOfWeek = today
            print("📅 WEEK DEBUG: Today is Sunday, so start of week is today")
        } else {
            // For any other day (including Saturday), calculate the previous Sunday
            let daysToSubtract = weekday == 7 ? 6 : (weekday - 1)
            if let date = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) {
                startOfWeek = date
                print("📅 WEEK DEBUG: Calculated start of week (Sunday): \(startOfWeek)")
            } else {
                // Fallback
                startOfWeek = today
                print("📅 WEEK DEBUG: Error calculating start of week, using today")
            }
        }
        
        print("📅 WEEK DEBUG: today is: \(today)")
        print("📅 WEEK DEBUG: final startOfWeek: \(startOfWeek)")
        
        print("📅 Checking weekly check-in status:")
        print("   - Today: \(today)")
        print("   - Current weekday: \(weekday) (1=Sunday, 7=Saturday)")
        print("   - Start of week: \(startOfWeek)")
        print("   - Is weekend: \(isWeekend)")
        
        // Debug logging for current user
        print("📅 Current User ID: \(self.currentUser?.userId ?? "nil")")
        print("📅 Latest Updates Count: \(latestUpdates.count)")
        
        // Check for existing check-ins only if we have a current user
        if let currentUserId = self.currentUser?.userId {
            // NEW IMPLEMENTATION: Get the most recent check-in for the CURRENT week
            // This allows checks on Saturday to be done regardless of having done a check the previous Sunday
            let weeklyCheckIn = latestUpdates.first { update in
                guard let updateDate = update.date else { return false }
                let updateDay = calendar.startOfDay(for: updateDate)
                let isThisWeek = updateDay >= startOfWeek && updateDay <= today
                let isCurrentUser = update.userId == currentUserId
                
                print("📅 DEBUG: Checking update: date=\(updateDate), isThisWeek=\(isThisWeek), isCurrentUser=\(isCurrentUser)")
                
                return isThisWeek && isCurrentUser
            }
            
            // If there's a check-in THIS week already, they're done
            if weeklyCheckIn != nil {
                print("✅ User has completed a check-in THIS week")
                print("✅ Check-in detail: \(String(describing: weeklyCheckIn))")
                return .completed
            }
        } else {
            print("⚠️ No current user ID available for check-in verification")
        }
        
        // FIXED: If it's the weekend, ALWAYS allow check-in if no check-in this week
        if isWeekend {
            print("📅 It's the weekend - user can submit check-in FOR THIS WEEK")
            return .eligible
        }
        
        // If it's Monday-Friday and no weekend check-in, they missed it
        if weekday >= 2 && weekday <= 6 {
            // Check if there was a check-in from the previous week
            
            // Calculate start of previous week
            guard let startOfPreviousWeek = calendar.date(byAdding: .day, value: -7, to: startOfWeek) else {
                // If we can't calculate, be lenient
                return .waitingForNext
            }
            
            // Calculate end of previous weekend (end of Sunday)
            guard let endOfPreviousWeekend = calendar.date(byAdding: .day, value: 1, to: startOfWeek) else {
                return .waitingForNext
            }
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfPreviousWeekend) ?? endOfPreviousWeekend
            
            // FIXED: Find check-ins from previous week's weekend with proper user ID check
            let previousWeekendCheckin = latestUpdates.first { update in
                guard let updateDate = update.date,
                      let currentUserId = self.currentUser?.userId else { return false }
                return updateDate >= startOfPreviousWeek &&
                updateDate <= endOfDay &&
                update.userId == currentUserId
            }
            
            if previousWeekendCheckin == nil {
                print("❌ No check-in from the previous weekend - user missed it")
                return .missed
            } else {
                print("⏱️ User completed last week's check-in, waiting for next weekend")
                return .waitingForNext
            }
        }
        
        // Default case - should wait for the weekend
        return .waitingForNext
    }
    
    func shouldShowWeeklyCheckinReminder() -> Bool {
        // Get the actual status
        let status = getWeeklyCheckinStatus()
        
        // Check if user has recently dismissed the banner
        if status == .missed {
            if let lastDismissalDate = UserDefaults.standard.object(forKey: "lastBannerDismissalDate") as? Date {
                // If banner was dismissed in the last 24 hours, don't show it again
                let dismissalAge = Date().timeIntervalSince(lastDismissalDate)
                if dismissalAge < 86400 { // 24 hours in seconds
                    return false
                }
            }
        }
        
        // Only show reminder in these cases:
        // 1. It's the weekend and they haven't checked in yet
        // 2. They missed last week's check-in (but don't let them check in)
        return status == .eligible || status == .missed
    }
    
    // Public method to check if user can actually submit a check-in
    func canSubmitWeeklyCheckin() -> Bool {
        return true // Temporarily allow submission any day
    }
    
    func dismissMissedCheckinBanner() {
        // Store the current date as the last dismissal time
        UserDefaults.standard.set(Date(), forKey: "lastBannerDismissalDate")
        
        // Post notification to update the UI
        NotificationCenter.default.post(name: .weeklyCheckInStatusChanged, object: nil)
    }
}

// MARK: - Password Reset Extension
extension AuthManager {
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

// MARK: - String Helper Extension
extension String {
    func capitalisedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}

// MARK: - User Role Enum
enum UserRole: String, Codable, CaseIterable {
    case coach, client
}

// MARK: - User Profile Update Extension
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

// MARK: - Notification Extension
extension Notification.Name {
    static let weeklyCheckInStatusChanged = Notification.Name("weeklyCheckInStatusChanged")
}

// MARK: - Weekly Check-in Status Debug Extension
extension AuthManager {
    // Check if user has completed weekly check-in this week with debug logging
    func hasCompletedWeeklyCheckinThisWeek() -> Bool {
        guard let userId = currentUser?.userId else {
            print("👤 No current user found when checking weekly status")
            return false
        }
        
        // Get current date
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate the start of the current week (Sunday)
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1 // 1 = Sunday in Calendar
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            print("📅 Could not calculate start of week")
            return false
        }
        
        print("📅 Checking for updates since: \(startOfWeek)")
        
        // Check if there's any update from this week
        let matchingUpdates = latestUpdates.filter { update in
            guard let updateDate = update.date else { return false }
            let isThisWeek = updateDate >= startOfWeek && update.userId == userId
            return isThisWeek
        }
        
        let hasCompletedCheckIn = !matchingUpdates.isEmpty
        
        print("🔍 Found \(matchingUpdates.count) updates for this week. Has completed check-in: \(hasCompletedCheckIn)")
        
        if !matchingUpdates.isEmpty {
            // For debugging, print info about the most recent update
            if let latestUpdate = matchingUpdates.first,
               let updateDate = latestUpdate.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                print("📝 Most recent check-in: \(formatter.string(from: updateDate))")
            }
        }
        
        return hasCompletedCheckIn
    }
    
    // TESTING CONTROLS - Set to true to force banner to show regardless of day
    #if DEBUG
    var testingModeEnabled: Bool { return false } // Set to true to test banner on any day
    #endif
}

extension AuthManager {
    // Public method to debug weekly check-ins
    func debugClientUpdates(clientId: String) async {
        print("🔍 DEBUGGING CLIENT UPDATES FOR: \(clientId)")
        
        do {
            // 1. Check client's existence
            let clientDoc = try await db.collection("users").document(clientId).getDocument()
            print("👤 Client document exists: \(clientDoc.exists)")
            
            // 2. Directly query client's updates without filters
            let updatesSnapshot = try await db.collection("updates")
                .whereField("userId", isEqualTo: clientId)
                .order(by: "date", descending: true)
                .getDocuments()
            
            print("📊 Found \(updatesSnapshot.documents.count) total updates for client")
            
            // 3. Print details about each update
            for (index, doc) in updatesSnapshot.documents.enumerated() {
                print("------- Update \(index + 1) -------")
                print("🆔 Document ID: \(doc.documentID)")
                
                if let timestamp = doc.data()["date"] as? Timestamp {
                    let date = timestamp.dateValue()
                    let formatter = DateFormatter()
                    formatter.dateStyle = .full
                    formatter.timeStyle = .medium
                    print("📅 Date: \(formatter.string(from: date))")
                    
                    // Check if this update is from the weekend
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: date)
                    let isWeekend = (weekday == 1 || weekday == 7) // 1 = Sunday, 7 = Saturday
                    print("🏠 Weekend update: \(isWeekend ? "YES" : "NO") (weekday = \(weekday))")
                } else {
                    print("⚠️ No date field found")
                }
                
                // Print other relevant fields
                if let weight = doc.data()["weight"] as? Double {
                    print("⚖️ Weight: \(weight) KG")
                }
                
                if let name = doc.data()["name"] as? String {
                    print("📝 Name: \(name)")
                }
                
                print("-----------------------------")
            }
            
            // 4. Check for any Sunday night updates specifically
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let sundayNightStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday)!
            
            let sundayNightUpdates = try await db.collection("updates")
                .whereField("userId", isEqualTo: clientId)
                .whereField("date", isGreaterThan: Timestamp(date: sundayNightStart))
                .whereField("date", isLessThan: Timestamp(date: today))
                .getDocuments()
            
            print("🌙 Sunday night updates (6PM to midnight): \(sundayNightUpdates.documents.count)")
            
            // 5. Verify that the coach can read this client's updates
            if let currentUser = auth.currentUser {
                print("👨‍🏫 Current user (coach) ID: \(currentUser.uid)")
                
                // Get the client's group ID
                if let clientData = clientDoc.data(), let clientGroupId = clientData["groupId"] as? String {
                    print("🏢 Client's group ID: \(clientGroupId)")
                    
                    // Get the group document to check if current user is the coach
                    let groupDoc = try await db.collection("groups").document(clientGroupId).getDocument()
                    if let groupData = groupDoc.data(), let coachId = groupData["coachId"] as? String {
                        print("👨‍🏫 Group's coach ID: \(coachId)")
                        print("✅ Current user is the coach: \(coachId == currentUser.uid ? "YES" : "NO")")
                    }
                }
            }
            
            print("🔍 DEBUG COMPLETED")
        } catch {
            print("❌ DEBUG ERROR: \(error.localizedDescription)")
        }
    }
}

// MARK: - Group Actions Extension
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
