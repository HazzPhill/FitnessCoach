import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage
import CoreHaptics

struct ClientHome: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddUpdate = false  // For weekly check-ins
    @State private var showingAddDailyCheckin = false // For daily check-ins
    @State private var refreshDailyCheckins = false // Trigger for refreshing daily check-ins
    @State private var canAddDailyCheckin: Bool = true // Track if user can add a check-in today
    @State private var checkinsCount: Int = 0 // Used to track changes in checkins array
    
    @StateObject private var weightViewModel: WeightEntriesViewModel
    @Namespace private var namespace
    @Namespace private var updatezoom
    @Namespace private var checkinNamespace
    
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)

    @State private var engine: CHHapticEngine?
    @State private var currentVisibleDay: String = ""
    
    // Initialize the weight view model with the current user's ID
    init(client: AuthManager.DBUser) {
        self.client = client
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
                            Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                                .font(themeManager.titleFont(size: 24))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
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
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        
                        WeightGraphView(weightEntries: weightViewModel.weightEntries)
                            .environmentObject(themeManager)
                        // AFTER:
                        HStack {
                            Text("Daily Goals")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            
                            NavigationLink {
                                DailyGoalsView(userId: client.userId)
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .foregroundStyle(themeManager.accentColor(for: colorScheme))
                                    .font(.system(size: 20))
                            }
                            .padding(.leading, 4)
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        
                        DailyGoalsGridView(userId: client.userId)
                            .environmentObject(themeManager)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.backgroundColor(for: colorScheme))
                            )
                      
                        
                        Text("Your Plan")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
    
                        // Then update your ScrollView with this implementation
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                        GeometryReader { geometry in
                                            DayMealPlanCard(day: day,
                                                           clientId: client.userId,
                                                           isCoach: false)
                                            .environmentObject(themeManager)
                                            .simultaneousGesture(TapGesture().onEnded {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                            })
                                            .scaleEffect(getScaleAmount(geometry: geometry))
                                            .animation(.easeOut(duration: 0.15), value: geometry.frame(in: .global).midX)
                                            // Check if this card is the most visible and update currentVisibleDay
                                            .onChange(of: isMostVisible(geometry: geometry)) { isMostVisible in
                                                if isMostVisible && currentVisibleDay != day {
                                                    currentVisibleDay = day
                                                    hapticFeedback.impactOccurred(intensity: 1.2)
                                                }
                                            }
                                        }
                                        .id(day)
                                        .frame(width: 260, height: 400)
                                    }
                                }
                                .padding(.vertical)
                                .padding(.trailing, 20)
                            }
                            .scrollIndicators(.hidden)
                            .onAppear {
                                // Initialize haptic engine
                                hapticFeedback.prepare()
                                
                                // Scroll to current day with animation when view appears
                                withAnimation {
                                    scrollProxy.scrollTo(currentDay, anchor: .leading)
                                    currentVisibleDay = currentDay  // Initialize current visible day
                                }
                            }
                        }
                        
                        PDFViewerBox(clientId: client.userId)
                            .environmentObject(themeManager)
                        
                        // IMPROVED: Daily Check-ins Section with conditional button
                        HStack {
                            Text("Daily Check-ins")
                                .font(themeManager.headingFont(size:18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            Spacer()
                            Button {
                                showingAddDailyCheckin = true
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            } label: {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(canAddDailyCheckin ?
                                        themeManager.accentColor(for: colorScheme) :
                                        Color.gray.opacity(0.5))
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundStyle(.white)
                                    )
                            }
                            .disabled(!canAddDailyCheckin)
                               .opacity(canAddDailyCheckin ? 1.0 : 0.3)
                        }

                        // UPDATED: LazyVStack for better performance
                        LazyVStack(spacing: 16) {
                            if authManager.dailyCheckins.isEmpty {
                                Text("No daily check-ins yet.")
                                    .font(themeManager.bodyFont(size: 16))
                                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .id("empty-checkins") // Add a stable ID to force refresh
                            } else {
                                ForEach(authManager.dailyCheckins) { checkin in
                                    NavigationLink {
                                        DailyCheckinDetailView(checkin: checkin)
                                            .environmentObject(authManager)
                                            .environmentObject(themeManager)
                                            .navigationTransition(.zoom(sourceID: checkin.id ?? "", in: checkinNamespace))
                                    } label: {
                                        DailyCheckinPreview(checkin: checkin)
                                            .environmentObject(themeManager)
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
                            // Update the checkins count to track changes
                            checkinsCount = authManager.dailyCheckins.count
                            // Check if user can add a daily checkin
                            checkDailyCheckinStatus()
                        }
                        
                        // Weekly Check-ins Section
                        HStack {
                            Text("Weekly Check-ins")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                            Spacer()
                            Button {
                                showingAddUpdate = true
                            } label: {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(themeManager.accentColor(for: colorScheme))
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
                                    .font(themeManager.bodyFont(size: 16))
                                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                                    .padding()
                            } else {
                                ForEach(authManager.latestUpdates) { update in
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
                        
                        NavigationLink(destination: allUpdatesView()
                                        .environmentObject(authManager)
                                        .environmentObject(themeManager)
                                        .navigationTransition(.zoom(sourceID: "allUpdates", in: updatezoom))) {
                            Text("View All")
                                .font(themeManager.bodyFont(size: 16))
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 24)
                                .background(themeManager.accentColor(for: colorScheme))
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
                    // Check if user can add a check-in after dismissal (handled in onChange of refreshDailyCheckins)
                }
            }) {
                DailyCheckinView(userId: client.userId)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
            }
            // Weekly check-in sheet
            .sheet(isPresented: $showingAddUpdate) {
                AddUpdateView()
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
            }
            .onAppear {
                // Make sure daily check-ins are refreshed when the view appears
                authManager.refreshDailyCheckins()
                // Initialize the checkins count
                checkinsCount = authManager.dailyCheckins.count
                // Check if user can add a check-in today
                checkDailyCheckinStatus()
            }
            // Use a timer to periodically check status (handles deletion case)
            .onReceive(Timer.publish(every: 2, on: .main, in: .common).autoconnect()) { _ in
                // Only update if the count has changed
                if checkinsCount != authManager.dailyCheckins.count {
                    checkinsCount = authManager.dailyCheckins.count
                    checkDailyCheckinStatus()
                }
            }
        }
    }
    
    // Check if user has already submitted a check-in today
    private func checkDailyCheckinStatus() {
        // Get today's date at midnight
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if there's a check-in for today in the daily check-ins array
        let hasCheckinForToday = authManager.dailyCheckins.contains { checkin in
            if let checkinDate = checkin.date {
                return calendar.isDate(calendar.startOfDay(for: checkinDate), inSameDayAs: today)
            }
            return false
        }
        
        // Update the state to enable/disable the button
        withAnimation {
            canAddDailyCheckin = !hasCheckinForToday
        }
    }
}

// Helper functions
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

// Function to determine if a card is the most visible one in the view
private func isMostVisible(geometry: GeometryProxy) -> Bool {
    let midPoint = UIScreen.main.bounds.width / 2
    let cardMidPoint = geometry.frame(in: .global).midX
    
    // This card is considered "most visible" if it's within 50 points of the center
    return abs(cardMidPoint - midPoint) < 50
}
