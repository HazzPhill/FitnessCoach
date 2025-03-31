import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

class ClientUpdatesViewModel: ObservableObject {
    @Published var updates: [AuthManager.Update] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let clientId: String
    @Published var isLoading: Bool = false
    
    init(clientId: String) {
        self.clientId = clientId
        print("👤 Initializing ClientUpdatesViewModel for client: \(clientId)")
        listenForUpdates()
    }
    
    private func listenForUpdates() {
        // Remove existing listener
        listener?.remove()
        
        isLoading = true
        print("🔍 Setting up listener for updates for client: \(clientId)")
        
        // Get date from 6 months ago to ensure we capture all recent updates
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        // Improved query with better date handling and logging
        listener = db.collection("updates")
            .whereField("userId", isEqualTo: clientId)
            .whereField("date", isGreaterThan: Timestamp(date: sixMonthsAgo))
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error fetching updates for client \(self.clientId): \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    print("📄 Received snapshot with \(snapshot.documents.count) documents for client \(self.clientId)")
                    
                    // Print the IDs of each document
                    for (index, doc) in snapshot.documents.enumerated() {
                        print("📑 Document \(index+1): \(doc.documentID)")
                        
                        // Print date if available
                        if let timestamp = doc.data()["date"] as? Timestamp {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateStyle = .medium
                            dateFormatter.timeStyle = .short
                            let date = timestamp.dateValue()
                            print("📅 Date: \(dateFormatter.string(from: date))")
                        }
                    }
                }
                
                do {
                    let updates = try snapshot?.documents.compactMap { doc -> AuthManager.Update? in
                        do {
                            let update = try doc.data(as: AuthManager.Update.self)
                            return update
                        } catch {
                            print("❌ Error decoding doc \(doc.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    } ?? []
                    
                    DispatchQueue.main.async {
                        print("✅ Updated view model with \(updates.count) updates for client \(self.clientId)")
                        self.updates = updates
                        
                        // Print debug info about most recent update
                        if let mostRecent = updates.first, let date = mostRecent.date {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .full
                            formatter.timeStyle = .medium
                            print("🔍 Most recent update: ID \(mostRecent.id ?? "unknown"), Date \(formatter.string(from: date))")
                        }
                    }
                } catch {
                    print("❌ Error processing updates for client \(self.clientId): \(error.localizedDescription)")
                }
            }
    }
    
    // Add a direct method to get updates without a listener
    func fetchUpdatesDirectly() async {
        print("📥 Directly fetching updates for client: \(clientId)")
        
        do {
            // Get date from 6 months ago
            let calendar = Calendar.current
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            
            // Improved query with better date handling
            let snapshot = try await db.collection("updates")
                .whereField("userId", isEqualTo: clientId)
                .whereField("date", isGreaterThan: Timestamp(date: sixMonthsAgo))
                .order(by: "date", descending: true)
                .getDocuments()
            
            print("📊 Direct query found \(snapshot.documents.count) updates for client \(clientId)")
            
            let updates = try snapshot.documents.compactMap { doc -> AuthManager.Update? in
                return try doc.data(as: AuthManager.Update.self)
            }
            
            await MainActor.run {
                print("✅ Directly fetched \(updates.count) updates for client \(clientId)")
                self.updates = updates
            }
        } catch {
            print("❌ Error in direct fetch for client \(clientId): \(error.localizedDescription)")
        }
    }
    
    // Enhanced force refresh function
    func forceRefresh() {
        print("🔄 Force refreshing updates for client: \(clientId)")
        
        // First, try resetting the listener
        listenForUpdates()
        
        // Also do a direct fetch to be certain
        Task {
            await fetchUpdatesDirectly()
        }
    }
    
    deinit {
        listener?.remove()
        print("🗑️ ClientUpdatesViewModel for \(clientId) is being deallocated")
    }
}
