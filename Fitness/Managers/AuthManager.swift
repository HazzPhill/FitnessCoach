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
    private let storage = Storage.storage() // For image uploads
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentUser: DBUser?
    @Published var currentGroup: Group?
    @Published var latestUpdates: [Update] = [] // Realtime updates listener
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var userListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var updatesListener: ListenerRegistration?
    
    // MARK: - Models
    
    struct Group: Codable, Identifiable {
        @DocumentID var id: String?
        let name: String
        let code: String // Must match Firestore field name
        let coachId: String
        var members: [String]
        var groupImageUrl: String?  // For group photo URL
        @ServerTimestamp var createdAt: Date?
    }
    
    struct DBUser: Codable {
        let userId: String
        let firstName: String
        let lastName: String
        let email: String
        let role: UserRole
        var groupId: String?
        var profileImageUrl: String?  // For profile picture URL
        @ServerTimestamp var createdAt: Date?
    }
    
    struct Update: Codable, Identifiable {
        @DocumentID var id: String?
        let userId: String
        let name: String
        let weight: Double
        let imageUrl: String?
        @ServerTimestamp var date: Date?
    }
    
    // MARK: - Initialisation
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupListeners(uid: user.uid)
                self?.setupUpdatesListener() // Start realtime listening for updates
            } else {
                self?.currentUser = nil
                self?.currentGroup = nil
                self?.latestUpdates = []
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
    
    /// Allows a user to join a group using its code.
    func joinGroup(code: String) async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        isLoading = true
        defer { isLoading = false }
        let snapshot = try await db.collection("groups")
            .whereField("code", isEqualTo: code.uppercased())
            .getDocuments()
        guard let groupDoc = snapshot.documents.first else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid group code"])
        }
        let batch = db.batch()
        let groupRef = db.collection("groups").document(groupDoc.documentID)
        let userRef = db.collection("users").document(user.uid)
        batch.updateData(["members": FieldValue.arrayUnion([user.uid])], forDocument: groupRef)
        batch.updateData(["groupId": groupDoc.documentID], forDocument: userRef)
        try await batch.commit()
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

    
    // MARK: - Firestore Operations
    
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
    }
    
    private func setupGroupListener(groupId: String) {
        groupListener = db.collection("groups").document(groupId)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let snapshot = snapshot else { return }
                self.currentGroup = try? snapshot.data(as: Group.self)
            }
    }
    
    /// Sets up a realtime listener for the latest 5 updates.
    func setupUpdatesListener() {
        updatesListener = db.collection("updates")
            .order(by: "date", descending: true)
            .limit(to: 5)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot else { return }
                do {
                    let updates = try snapshot.documents.compactMap { doc -> Update? in
                        try doc.data(as: Update.self)
                    }
                    DispatchQueue.main.async {
                        self.latestUpdates = updates
                    }
                } catch {
                    print("Error decoding updates: \(error.localizedDescription)")
                }
            }
    }
    
    // MARK: - Update Functionality
    
    /// Adds a new update for the client with an optional image.
    func addUpdate(name: String, weight: Double, image: UIImage?) async throws {
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
            "date": Timestamp(date: Date())
        ]
        _ = try await db.collection("updates").addDocument(data: updateData)
    }
    
    /// Helper method to upload an update image to Firebase Storage.
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
    
    /// Updates the group's photo by uploading the image and updating Firestore.
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
    
    /// Updates the user's profile picture by uploading the image and updating Firestore.
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
    /// Sends a password reset email.
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}

enum UserRole: String, Codable, CaseIterable {
    case coach, client
}
