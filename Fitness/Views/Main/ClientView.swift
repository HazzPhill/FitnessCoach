import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage
import CoreHaptics

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
    
    // Add states for Training PDF functionality
    @State private var showTrainingPDFUploader = false
    @State private var hasPDF = false
    
    // Add states for scrolling effects and haptic feedback
    @State private var hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)
    @State private var currentVisibleDay: String = ""
    @State private var engine: CHHapticEngine?
    
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
                            HStack {
                                Text("Weekly Goals")
                                    .font(themeManager.headingFont(size: 18))
                                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                                
                                Spacer()
                            }
                            
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
                        
                        // Plan Section: Enhanced with scroll effects
                        Text("Plan")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        
                        // Enhanced ScrollView with scroll to current day and scale effects
                        ScrollViewReader { scrollProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                        GeometryReader { geometry in
                                            DayMealPlanCard(day: day,
                                                           clientId: client.userId,
                                                           isCoach: true)
                                            .environmentObject(themeManager)
                                            .simultaneousGesture(TapGesture().onEnded {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                            })
                                            .scaleEffect(getScaleAmount(geometry: geometry))
                                            .animation(.easeOut(duration: 0.15), value: geometry.frame(in: .global).midX)
                                            // Check if this card is the most visible
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

                        PDFUploadBox(clientId: client.userId)
                            .environmentObject(themeManager)
                        
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
                .scrollContentBackground(.hidden) // This fixes the white bar when scrolling
            }
            .onAppear {
                // Refresh weight entries when view appears to make sure we have the most current data
                weightViewModel.fetchAllWeightEntries(userId: client.userId)
            }
            .navigationBarBackButtonHidden(true) // Hide the default back button
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
            }
            // These settings fix the white bar when scrolling by making the navigation bar use theme colors
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showTrainingPDFUploader) {
                TrainingPDFViewerScreen(clientId: client.userId, isCoachView: true)
                    .environmentObject(themeManager)
            }
        }
    }
    
    // Helper function to create a goal card
    private func goalCard(title: String, value: String) -> some View {
        Group {
            if title == "Training" {
                // Special handling for Training goal
                Button(action: {
                    showTrainingPDFUploader = true
                }) {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(themeManager.headingFont(size: 16))
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        
                        HStack {
                            Text(value.isEmpty ? "Not set" : value)
                                .font(themeManager.bodyFont(size: 18))
                                .foregroundColor(themeManager.textColor(for: colorScheme))
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            if hasPDF {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                        }
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
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    // Check if there's a PDF already
                    TrainingPDFManager.shared.checkTrainingExists(clientId: client.userId) { exists in
                        DispatchQueue.main.async {
                            self.hasPDF = exists
                        }
                    }
                }
            } else {
                // Regular card for other goals
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
    }
}

// Helper functions for scroll effects
private func getScaleAmount(geometry: GeometryProxy) -> CGFloat {
    let midPoint = UIScreen.main.bounds.width / 2
    let viewMidPoint = geometry.frame(in: .global).midX
    
    let distance = abs(midPoint - viewMidPoint)
    let percentage = distance / (UIScreen.main.bounds.width / 2)
    
    // Cards at center will be 100% scale, cards at edges will be at 90% scale
    let scale = 1.0 - min(percentage * 0.2, 0.2)
    
    return scale
}

// Helper to get the current day
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
