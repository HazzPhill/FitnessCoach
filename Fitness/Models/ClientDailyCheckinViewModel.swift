import SwiftUI
import Foundation
import Firebase

class ClientDailyCheckinsViewModel: ObservableObject {
    @Published var checkins: [DailyCheckin] = []
    private var listener: ListenerRegistration?
    private var secondaryListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    init(clientId: String) {
        print("Initializing ClientDailyCheckinsViewModel for client ID: \(clientId)")
        
        // First check if the collection exists and contains documents
        db.collection("daily_checkins").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error checking collection: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot {
                print("✅ Found \(snapshot.documents.count) total documents in daily_checkins collection")
                
                // Try the alternative collection name to see if that's the issue
                self.db.collection("dailyCheckins").getDocuments { altSnapshot, altError in
                    if let altSnapshot = altSnapshot, !altSnapshot.documents.isEmpty {
                        print("⚠️ Also found \(altSnapshot.documents.count) documents in 'dailyCheckins' collection (note capitalization)")
                    }
                }
            }
        }
        
        // Then check if there are any documents for this specific client
        db.collection("daily_checkins")
            .whereField("userId", isEqualTo: clientId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching client's check-ins: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot {
                    print("🔍 Found \(snapshot.documents.count) documents for client ID: \(clientId)")
                    
                    // Print debug info about each document
                    for (index, doc) in snapshot.documents.enumerated() {
                        print("📄 Document \(index + 1):")
                        print("  - ID: \(doc.documentID)")
                        if let data = try? doc.data(as: DailyCheckin.self) {
                            print("  - Successfully decoded as DailyCheckin")
                            if let date = data.date {
                                print("  - Date: \(date)")
                            } else {
                                print("  - Date: nil")
                            }
                        } else {
                            print("  - Failed to decode as DailyCheckin")
                            print("  - Raw data: \(doc.data())")
                        }
                    }
                }
                
                // Set up the regular listener after debugging
                self.setupListener(clientId: clientId)
            }
    }
    
    private func setupListener(clientId: String) {
        // Check both possible collection names
        setupListenerForCollection(name: "daily_checkins", clientId: clientId, isPrimary: true)
        setupListenerForCollection(name: "dailyCheckins", clientId: clientId, isPrimary: false)
    }
    
    private func setupListenerForCollection(name: String, clientId: String, isPrimary: Bool) {
        let listenerRef = db.collection(name)
            .whereField("userId", isEqualTo: clientId)
            .order(by: "date", descending: true)
            .limit(to: 10)
        
        print("Setting up listener for \(name) collection with client ID: \(clientId)")
        
        let newListener = listenerRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error in \(name) listener: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ Empty snapshot returned for \(name)")
                return
            }
            
            print("📥 \(name) listener received \(snapshot.documents.count) documents")
            
            do {
                let checkins = try snapshot.documents.compactMap { doc -> DailyCheckin? in
                    let result = try doc.data(as: DailyCheckin.self)
                    print("✅ Successfully decoded check-in: \(doc.documentID)")
                    return result
                }
                
                if !checkins.isEmpty {
                    DispatchQueue.main.async {
                        print("🔄 Updating UI with \(checkins.count) check-ins from \(name)")
                        withAnimation {
                            self.checkins = checkins
                            
                            // If we found check-ins in the secondary collection, make it primary
                            if !isPrimary {
                                self.listener?.remove()
                                self.listener = self.secondaryListener
                                self.secondaryListener = nil
                            }
                        }
                    }
                } else {
                    print("⚠️ No check-ins decoded from \(snapshot.documents.count) documents in \(name)")
                    for doc in snapshot.documents {
                        print("  - Document \(doc.documentID) data: \(doc.data())")
                    }
                }
            } catch {
                print("❌ Error decoding check-ins from \(name): \(error.localizedDescription)")
            }
        }
        
        // Store the listener in the appropriate property
        if isPrimary {
            listener = newListener
        } else {
            secondaryListener = newListener
        }
    }
    
    deinit {
        listener?.remove()
        secondaryListener?.remove()
    }
}
