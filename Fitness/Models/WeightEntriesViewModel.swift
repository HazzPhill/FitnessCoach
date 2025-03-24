import SwiftUI
import FirebaseFirestore
import Combine

// View model to fetch all weight entries for a user
class WeightEntriesViewModel: ObservableObject {
    @Published var weightEntries: [WeightEntry] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(userId: String) {
        fetchAllWeightEntries(userId: userId)
    }

    func fetchAllWeightEntries(userId: String) {
        // Remove any existing listener
        listener?.remove()
        
        print("Fetching all weight entries for user: \(userId)")
        
        // Clear existing entries first to ensure UI updates properly
        DispatchQueue.main.async {
            self.weightEntries = []
        }
        
        // Set up listener for all weight entries with no limit
        listener = db.collection("updates")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: false) // Using descending: false for ascending order (oldest to newest)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching weight entries: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found for weight entries")
                    return
                }
                
                print("📊 Found \(documents.count) weight entry documents")
                
                let entries = documents.compactMap { doc -> WeightEntry? in
                    // Get the data without conditional binding since it's not optional
                    let data = doc.data()
                    
                    // Check for required fields
                    guard let weight = data["weight"] as? Double,
                          let timestamp = data["date"] as? Timestamp else {
                        print("⚠️ Skipping document \(doc.documentID) - missing weight or date")
                        return nil
                    }
                    
                    let date = timestamp.dateValue()
                    return WeightEntry(date: date, weight: weight)
                }
                
                // Sort entries by date (oldest to newest)
                let sortedEntries = entries.sorted { $0.date < $1.date }
                
                DispatchQueue.main.async {
                    print("📈 Updating chart with \(sortedEntries.count) weight entries")
                    self.weightEntries = sortedEntries
                }
            }
    }

    // Add a new method to the ViewModel to refresh the data immediately when needed
    func forceRefresh(userId: String) {
        print("🔄 Force refreshing weight entries")
        // Remove and re-create the listener
        listener?.remove()
        fetchAllWeightEntries(userId: userId)
    }
    
    deinit {
        listener?.remove()
    }
}
