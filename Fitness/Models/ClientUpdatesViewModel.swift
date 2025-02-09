import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

class ClientUpdatesViewModel: ObservableObject {
    @Published var updates: [AuthManager.Update] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let clientId: String
    
    init(clientId: String) {
        self.clientId = clientId
        listenForUpdates()
    }
    
    private func listenForUpdates() {
        listener = db.collection("updates")
            .whereField("userId", isEqualTo: clientId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching updates for client \(self.clientId): \(error.localizedDescription)")
                    return
                }
                do {
                    let updates = try snapshot?.documents.compactMap { doc in
                        try doc.data(as: AuthManager.Update.self)
                    } ?? []
                    DispatchQueue.main.async {
                        self.updates = updates
                    }
                } catch {
                    print("Error decoding updates for client \(self.clientId): \(error.localizedDescription)")
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
