import FirebaseAuth
import FirebaseFirestore
import FirebaseStorageCombineSwift
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    @Published var currentUser: DBUser?
    @Published var currentGroup: Group?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var userListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    
    struct Group: Codable, Identifiable {
        @DocumentID var id: String?
        let name: String
        let code: String // Must match Firestore field name
        let coachId: String
        var members: [String]
        @ServerTimestamp var createdAt: Date?
    }
    
    struct DBUser: Codable {
        let userId: String
        let firstName: String
        let lastName: String
        let email: String
        let role: UserRole
        var groupId: String?
        @ServerTimestamp var createdAt: Date?
    }
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.setupListeners(uid: user.uid)
            } else {
                self?.currentUser = nil
                self?.currentGroup = nil
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
                createdAt: nil
            )
            try await createDBUser(user: user)
            setupListeners(uid: result.user.uid)
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
    
    /// New joinGroup method added to allow users to join a group using a code.
    func joinGroup(code: String) async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Fetch group by code
        let snapshot = try await db.collection("groups")
            .whereField("code", isEqualTo: code.uppercased())
            .getDocuments()
        
        guard let groupDoc = snapshot.documents.first else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid group code"])
        }
        
        // Use a batch to atomically update user and group
        let batch = db.batch()
        let groupRef = db.collection("groups").document(groupDoc.documentID)
        let userRef = db.collection("users").document(user.uid)
        
        // Add user to group's members
        batch.updateData(["members": FieldValue.arrayUnion([user.uid])], forDocument: groupRef)
        // Update user's groupId
        batch.updateData(["groupId": groupDoc.documentID], forDocument: userRef)
        
        try await batch.commit() // Atomic write
    }
    
    func createGroup(name: String) async throws -> Group {
        guard let user = currentUser, user.role == .coach else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authorized"])
        }
        
        let groupCode = generateGroupCode()
        let group = Group(
            name: name,
            code: groupCode, // Code generated here
            coachId: user.userId,
            members: [user.userId],
            createdAt: nil
        )
        
        // Add to Firestore
        let groupRef = try db.collection("groups").addDocument(from: group)
        
        // Update user's groupId
        try await db.collection("users").document(user.userId).updateData([
            "groupId": groupRef.documentID
        ])
        
        // Return the group with Firestore ID and code
        return Group(
            id: groupRef.documentID,
            name: name,
            code: groupCode,
            coachId: user.userId,
            members: [user.userId],
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
                    // Reset group listener if groupId changes or is nil
                    if let groupId = self.currentUser?.groupId {
                        self.setupGroupListener(groupId: groupId)
                    } else {
                        self.currentGroup = nil // Clear group data
                        self.groupListener = nil // Remove old listener
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
    
    // MARK: - Helpers
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
        
         func setupGroupListener(groupId: String) {
            groupListener = db.collection("groups").document(groupId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    do {
                        if let snapshot = snapshot {
                            self.currentGroup = try snapshot.data(as: Group.self)
                        }
                    } catch {
                        self.errorMessage = error.localizedDescription
                    }
                }
        }
    }
}

enum UserRole: String, Codable, CaseIterable {
    case coach, client
}
