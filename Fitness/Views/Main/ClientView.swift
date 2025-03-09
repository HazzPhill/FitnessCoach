import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage

struct ClientView: View {
    let client: AuthManager.DBUser
    @StateObject private var updatesViewModel: ClientUpdatesViewModel
    @StateObject private var goalsViewModel: DailyGoalsViewModel
    @StateObject private var checkinsViewModel: ClientDailyCheckinsViewModel
    @StateObject private var weightViewModel: WeightEntriesViewModel
    @Namespace private var namespace
    @Namespace private var checkinNamespace

    init(client: AuthManager.DBUser) {
        self.client = client
        _updatesViewModel = StateObject(wrappedValue: ClientUpdatesViewModel(clientId: client.userId))
        _goalsViewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: client.userId))
        _checkinsViewModel = StateObject(wrappedValue: ClientDailyCheckinsViewModel(clientId: client.userId))
        _weightViewModel = StateObject(wrappedValue: WeightEntriesViewModel(userId: client.userId))
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
                        
                        // Weekly Goals Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weekly Goals")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            
                            // Goals grid display
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                // Calories goal
                                goalCard(title: "Calories", value: goalsViewModel.dailyCalories)
                                
                                // Steps goal
                                goalCard(title: "Steps", value: goalsViewModel.dailySteps)
                                
                                // Protein goal
                                goalCard(title: "Protein", value: goalsViewModel.dailyProtein)
                                
                                // Training goal
                                goalCard(title: "Training", value: goalsViewModel.dailyTraining)
                            }
                        }
                        
                        // Progress Section - Now using the complete weight history
                        Text("Progress")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        WeightGraphView(weightEntries: weightViewModel.weightEntries)
                        
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
                                                    isCoach: true)
                                        .frame(width: 260)
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        
                        // Daily Check-ins Section
                        HStack {
                            Text("Daily Check-ins")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        
                        LazyVStack(spacing: 16) {
                            if checkinsViewModel.checkins.isEmpty {
                                Text("No daily check-ins yet.")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(checkinsViewModel.checkins) { checkin in
                                    NavigationLink {
                                        DailyCheckinDetailView(checkin: checkin)
                                            .navigationTransition(.zoom(sourceID: checkin.id ?? "", in: checkinNamespace))
                                    } label: {
                                        DailyCheckinPreview(checkin: checkin)
                                            .matchedTransitionSource(id: checkin.id ?? "", in: checkinNamespace)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Updates Section
                        HStack {
                            Text("Weekly Check-ins")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            Spacer()
                        }
                        ScrollView {
                            if updatesViewModel.updates.isEmpty {
                                Text("No weekly check-ins yet.")
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
            .onAppear {
                // Refresh weight entries when view appears to make sure we have the most current data
                weightViewModel.fetchAllWeightEntries(userId: client.userId)
            }
        }
    }
    
    // Helper function to create a goal card
    private func goalCard(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("SecondaryAccent"))
            
            Text(value.isEmpty ? "Not set" : value)
                .font(.title3)
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 1)
        )
    }
}
