import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

class ClientBoxViewModel: ObservableObject {
    @Published var latestUpdate: AuthManager.Update?
    private var listener: ListenerRegistration?
    private let clientId: String
    private let db = Firestore.firestore()
    
    init(clientId: String) {
        self.clientId = clientId
        listenForLatestUpdate()
    }
    
    private func listenForLatestUpdate() {
        listener = db.collection("updates")
            .whereField("userId", isEqualTo: clientId)
            .order(by: "date", descending: true)
            .limit(to: 1)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching update for client \(self.clientId): \(error.localizedDescription)")
                    return
                }
                guard let document = snapshot?.documents.first else {
                    // No updates for this client
                    DispatchQueue.main.async {
                        self.latestUpdate = nil
                    }
                    return
                }
                do {
                    let update = try document.data(as: AuthManager.Update.self)
                    DispatchQueue.main.async {
                        self.latestUpdate = update
                    }
                } catch {
                    print("Error decoding update for client \(self.clientId): \(error.localizedDescription)")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
