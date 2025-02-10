import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage

struct ClientHome: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddUpdate = false  // Controls presentation of AddUpdateView
    @Namespace private var namespace
    
    // Compute weight entries.
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
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        HStack {
                            Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color("Accent"))
                            Spacer()
                            NavigationLink {
                                SettingsView()
                            } label: {
                                if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                                   let url = URL(string: profileImageUrl) {
                                    CachedAsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView().frame(width: 45, height: 45)
                                        case .success(let image):
                                            image.resizable()
                                                .scaledToFill()
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                        case .failure(_):
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                        @unknown default:
                                            EmptyView()
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
                        WeightGraphView(weightEntries: weightEntries)
                        
                        Text("Your Plan")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        // Horizontal scroll with 7 day cards.
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                                    DayMealPlanCard(day: day,
                                                    clientId: client.userId,
                                                    isCoach: false)
                                        .frame(width: 260)
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        
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
                        
                        ScrollView {
                            if authManager.latestUpdates.isEmpty {
                                Text("No updates yet.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(authManager.latestUpdates) { update in
                                    NavigationLink {
                                        UpdateDetailView(update: update)
                                            .navigationTransition(.zoom(sourceID: update.id, in: namespace))
                                    } label: {
                                        UpdatePreview(
                                            label: update.name,
                                            Weight: Int(update.weight),
                                            date: update.date ?? Date(),
                                            imageUrl: update.imageUrl
                                        )
                                        .matchedTransitionSource(id: update.id, in: namespace)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingAddUpdate) {
                AddUpdateView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    let dummyClient = AuthManager.DBUser(
        userId: "client123",
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        role: .client,
        groupId: "group123",
        profileImageUrl: nil,
        createdAt: nil
    )
    ClientHome(client: dummyClient)
        .environmentObject(AuthManager.shared)
}
