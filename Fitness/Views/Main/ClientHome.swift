import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage
import CoreHaptics

struct ClientHome: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddUpdate = false  // For weekly check-ins
    @State private var showingAddDailyCheckin = false // For daily check-ins
    @State private var refreshDailyCheckins = false // Trigger for refreshing daily check-ins
    @StateObject private var weightViewModel: WeightEntriesViewModel
    @Namespace private var namespace
    @Namespace private var updatezoom
    @Namespace private var checkinNamespace
    

    @State private var engine: CHHapticEngine?
    
    // Initialize the weight view model with the current user's ID
        init(client: AuthManager.DBUser) {
            self.client = client
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
                        
                        WeightGraphView(weightEntries: weightViewModel.weightEntries)
                        
                        // Daily Goals Grid Section
                        Text("Daily Goals")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        DailyGoalsGridView(userId: client.userId)
                        
                        Text("Your Plan")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
    
                        // Then update your ScrollView with a ScrollViewReader
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                        GeometryReader { geometry in
                                            DayMealPlanCard(day: day,
                                                            clientId: client.userId,
                                                            isCoach: false)
                                            .simultaneousGesture(TapGesture().onEnded {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                            })
                                            .scaleEffect(getScaleAmount(geometry: geometry))
                                            .animation(.easeOut(duration: 0.15), value: geometry.frame(in: .global).midX)
                                        }
                                        .id(day) // Important: Add an ID for the scrollTo function
                                        .frame(width: 260, height: 400)
                                    }
                                }
                                .padding(.vertical)
                                .padding(.trailing, 20)
                            }
                            .scrollIndicators(.hidden)
                            .onAppear {
                                // Scroll to current day with animation when view appears
                                withAnimation {
                                    scrollProxy.scrollTo(currentDay, anchor: .leading)
                                }
                            }
                        }
                        
                        // IMPROVED: Daily Check-ins Section with better animations and update handling
                        HStack {
                            Text("Daily Check-ins")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            Spacer()
                            Button {
                                showingAddDailyCheckin = true
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
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

                        // UPDATED: LazyVStack for better performance
                        LazyVStack(spacing: 16) {
                            if authManager.dailyCheckins.isEmpty {
                                Text("No daily check-ins yet.")
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(authManager.dailyCheckins) { checkin in
                                    NavigationLink {
                                        DailyCheckinDetailView(checkin: checkin)
                                            .environmentObject(authManager)
                                            .navigationTransition(.zoom(sourceID: checkin.id ?? "", in: checkinNamespace))
                                    } label: {
                                        DailyCheckinPreview(checkin: checkin)
                                            .matchedTransitionSource(id: checkin.id ?? "", in: checkinNamespace)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                            .simultaneousGesture(TapGesture().onEnded {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                            })
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .animation(.spring(), value: refreshDailyCheckins)
                        .onChange(of: refreshDailyCheckins) { _ in
                            // Force immediate refresh when this value changes
                            authManager.refreshDailyCheckins()
                        }
                        
                        // Weekly Check-ins Section
                        HStack {
                            Text("Check-ins")
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
                            .sensoryFeedback(.impact(flexibility: .solid, intensity: 1), trigger: showingAddUpdate)
                        }
                        
                        ScrollView {
                            if authManager.latestUpdates.isEmpty {
                                Text("No check-ins yet.")
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
                                    .simultaneousGesture(TapGesture().onEnded {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    })
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        
                        NavigationLink(destination: allUpdatesView()
                                        .environmentObject(authManager)
                                        .navigationTransition(.zoom(sourceID: "allUpdates", in: updatezoom))) {
                            Text("View All")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("White"))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(Color("Accent"))
                                .clipShape(Capsule())
                                .matchedTransitionSource(id: "allUpdates", in: updatezoom)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            // IMPROVED: Daily check-in sheet with better dismiss handling
            .sheet(isPresented: $showingAddDailyCheckin, onDismiss: {
                // Force refresh when sheet is dismissed
                withAnimation {
                    refreshDailyCheckins.toggle()
                }
            }) {
                DailyCheckinView(userId: client.userId)
                    .environmentObject(authManager)
            }
            // Weekly check-in sheet
            .sheet(isPresented: $showingAddUpdate) {
                AddUpdateView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Make sure daily check-ins are refreshed when the view appears
                authManager.refreshDailyCheckins()
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

private func getScaleAmount(geometry: GeometryProxy) -> CGFloat {
    let midPoint = UIScreen.main.bounds.width / 2
    let viewMidPoint = geometry.frame(in: .global).midX
    
    let distance = abs(midPoint - viewMidPoint)
    let percentage = distance / (UIScreen.main.bounds.width / 2)
    
    // Cards at center will be 100% scale, cards at edges will be at 90% scale
    let scale = 1.0 - min(percentage * 0.2, 0.2)
    
    return scale
}

// Add this computed property to get the current day
private var currentDay: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE" // Short weekday name (Mon, Tue, etc.)
    let dayString = dateFormatter.string(from: Date())
    // Convert to format that matches your data (first 3 letters)
    return String(dayString.prefix(3))
}
