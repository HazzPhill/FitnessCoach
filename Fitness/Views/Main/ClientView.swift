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
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        HStack {
                            Text("\(client.firstName)'s Dashboard")
                                .font(themeManager.titleFont(size: 24))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
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
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            
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
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        WeightGraphView(weightEntries: weightViewModel.weightEntries)
                            .environmentObject(themeManager)
                        
                        // Plan Section: One horizontal scroll view with 7 cards.
                        Text("Plan")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                    DayMealPlanCard(day: day,
                                                    clientId: client.userId,
                                                    isCoach: true)
                                    .environmentObject(themeManager)
                                    .frame(width: 260)
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        
                        // Daily Check-ins Section
                        HStack {
                            Text("Daily Check-ins")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            Spacer()
                        }
                        
                        LazyVStack(spacing: 16) {
                            if checkinsViewModel.checkins.isEmpty {
                                Text("No daily check-ins yet.")
                                    .font(themeManager.bodyFont(size: 16))
                                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(checkinsViewModel.checkins) { checkin in
                                    NavigationLink {
                                        DailyCheckinDetailView(checkin: checkin)
                                            .environmentObject(themeManager)
                                            .navigationTransition(.zoom(sourceID: checkin.id ?? "", in: checkinNamespace))
                                    } label: {
                                        DailyCheckinPreview(checkin: checkin)
                                            .environmentObject(themeManager)
                                            .matchedTransitionSource(id: checkin.id ?? "", in: checkinNamespace)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    })
                                }
                            }
                        }
                        
                        // Updates Section
                        HStack {
                            Text("Weekly Check-ins")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            Spacer()
                        }
                        ScrollView {
                            if updatesViewModel.updates.isEmpty {
                                Text("No weekly check-ins yet.")
                                    .font(themeManager.bodyFont(size: 16))
                                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                                    .padding()
                            } else {
                                ForEach(updatesViewModel.updates) { update in
                                    NavigationLink {
                                        UpdateDetailView(update: update)
                                            .environmentObject(themeManager)
                                            .navigationTransition(.zoom(sourceID: update.id, in: namespace))
                                    } label: {
                                        UpdatePreview(
                                            label: update.name,
                                            Weight: Int(update.weight),
                                            date: update.date ?? Date(),
                                            imageUrl: update.imageUrl
                                        )
                                        .environmentObject(themeManager)
                                        .matchedTransitionSource(id: update.id, in: namespace)
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    })
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
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
                .font(themeManager.headingFont(size: 16))
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            
            Text(value.isEmpty ? "Not set" : value)
                .font(themeManager.bodyFont(size: 18))
                .foregroundColor(themeManager.textColor(for: colorScheme))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
        )
    }
}
