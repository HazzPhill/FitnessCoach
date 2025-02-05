import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct ClientHome: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddUpdate = false  // Controls presentation of AddUpdateView
    
    // Compute weight entries from the realtime updates in AuthManager for the current year.
    var weightEntries: [WeightEntry] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return authManager.latestUpdates.compactMap { update in
            if let date = update.date, calendar.component(.year, from: date) == currentYear {
                return WeightEntry(date: date, weight: update.weight)
            }
            return nil
        }
        .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea(edges: .all)
                VStack(alignment: .leading) {
                    // Header Section
                    HStack {
                        Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Accent"))
                        Spacer()
                        // Replace the gym_background image with the user's profile picture.
                        NavigationLink {
                            SettingsView()
                        } label: {
                            if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } else if phase.error != nil {
                                        Image(systemName: "person.circle")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } else {
                                        ProgressView()
                                            .frame(width: 45, height: 45)
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Text("Your Progress")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                    
                    // Graph view of weight entries
                    WeightGraphView(weightEntries: weightEntries)
                    
                    Text("Your Plan")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                    
                    // Updates Section Header with plus button
                    HStack {
                        Text("Updates")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        Spacer()
                        Button {
                            showingAddUpdate = true
                        } label: {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(Color("Accent"))
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                    
                    // ScrollView displaying latest 5 updates in real time
                    ScrollView {
                        if authManager.latestUpdates.isEmpty {
                            Text("No updates yet.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(authManager.latestUpdates) { update in
                                UpdatePreview(label: update.name,
                                              Weight: Int(update.weight),
                                              date: update.date ?? Date(),
                                              imageUrl: update.imageUrl)
                            }
                        }
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showingAddUpdate) {
                AddUpdateView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    ClientHome()
}
