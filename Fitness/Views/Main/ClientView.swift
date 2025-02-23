import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage

struct ClientView: View {
    let client: AuthManager.DBUser
    @StateObject private var updatesViewModel: ClientUpdatesViewModel
    @Namespace private var namespace

    // Compute weight entries for this client's updates.
    var weightEntries: [WeightEntry] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return updatesViewModel.updates.compactMap { update in
            if let date = update.date, calendar.component(.year, from: date) == currentYear {
                return WeightEntry(date: date, weight: update.weight)
            }
            return nil
        }
        .sorted { $0.date < $1.date }
    }
    
    init(client: AuthManager.DBUser) {
        self.client = client
        _updatesViewModel = StateObject(wrappedValue: ClientUpdatesViewModel(clientId: client.userId))
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
                            Text("\(client.firstName)'s Dashboard")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color("Accent"))
                            Spacer()
                            if let profileImageUrl = client.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
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
                                }
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Progress Section
                        Text("Progress")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        WeightGraphView(weightEntries: weightEntries)
                        
                        // Plan Section: One horizontal scroll view with 7 cards.
                        Text("Plan")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                    DayMealPlanCard(day: day,
                                                    clientId: client.userId,
                                                    isCoach: true) // or set false if needed
                                        .frame(width: 260)
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        
                        // Updates Section (unchanged)
                        HStack {
                            Text("Check-ins")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        ScrollView {
                            if updatesViewModel.updates.isEmpty {
                                Text("No Check-ins yet.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(updatesViewModel.updates) { update in
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
                    }
                    .padding()
                }
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
    ClientView(client: dummyClient)
        .environmentObject(AuthManager.shared)
}
