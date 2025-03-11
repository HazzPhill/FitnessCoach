import SwiftUI
import CachedAsyncImage

struct DailyCheckinDetailView: View {
    let checkin: DailyCheckin
    @State private var showingEditSheet = false
    @State private var currentImageIndex = 0
    @State private var imageTimer: Timer? = nil
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Check if current user is the owner of this check-in
    private var isOwner: Bool {
        return authManager.currentUser?.userId == checkin.userId
    }
    
    private var completedGoalsCount: Int {
        return checkin.completedGoals.filter { $0.completed }.count
    }
    
    private var totalGoalsCount: Int {
        return checkin.completedGoals.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Image carousel
                ZStack(alignment: .bottom) {
                    if let imageUrls = checkin.imageUrls, !imageUrls.isEmpty {
                        if let url = URL(string: imageUrls[currentImageIndex]) {
                            CachedAsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 220)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipped()
                                case .failure(_):
                                    Image("gym_background")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipped()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    } else {
                        // Fallback image if no images available
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                    }
                    
                    // Navigation controls removed
                    
                    // Subtle gradient fade at bottom
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 80)
                }
                .ignoresSafeArea(edges: .top)
                
                // Title & Date with conditional edit button
                HStack {
                    Text(formattedDay(from: checkin.date))
                        .font(themeManager.headingFont(size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let date = checkin.date {
                            Text(date.formattedWithOrdinal())
                                .font(themeManager.captionFont(size: 12))
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        }
                        
                        // Edit button only shown if user owns this check-in
                        if isOwner {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Goal completion status
                HStack(spacing: 16) {
                    InfoBoxView(
                        title: "Goals Completed",
                        value: "\(completedGoalsCount)/\(totalGoalsCount)",
                        valueColor: themeManager.accentOrWhiteText(for: colorScheme)
                    )
                    .environmentObject(themeManager)
                    
                    InfoBoxView(
                        title: "Completion Rate",
                        value: String(format: "%.0f%%", Double(completedGoalsCount) / Double(totalGoalsCount) * 100),
                        valueColor: completedGoalsCount == totalGoalsCount ?
                            themeManager.accentOrWhiteText(for: colorScheme) :
                            themeManager.accentOrWhiteText(for: colorScheme).opacity(0.7)
                    )
                    .environmentObject(themeManager)
                }
                .padding(.horizontal)
                
                // Goals section styled as the scores box
                VStack(spacing: 12) {
                    HStack {
                        Text("Goals")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        Spacer()
                    }
                    
                    // List of goals
                    ForEach(checkin.completedGoals) { goal in
                        HStack {
                            Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(goal.completed ? themeManager.accentOrWhiteText(for: colorScheme) : .gray)
                            Text(goal.name)
                                .font(themeManager.bodyFont(size: 16))
                                .foregroundColor(goal.completed ? themeManager.accentOrWhiteText(for: colorScheme) : .gray)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Notes section (if any) - styled as reflection box
                if let notes = checkin.notes, !notes.isEmpty {
                    ReflectionBoxView(
                        title: "Notes",
                        text: notes
                    )
                    .environmentObject(themeManager)
                    .padding(.horizontal)
                }
                
                // Photos grid (thumbnails)
                if let imageUrls = checkin.imageUrls, imageUrls.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<imageUrls.count, id: \.self) { index in
                                    let urlString = imageUrls[index]
                                    if let url = URL(string: urlString) {
                                        CachedAsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 200, height: 200)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 200, height: 200)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                                                    )
                                                    .onTapGesture {
                                                        withAnimation {
                                                            currentImageIndex = index
                                                        }
                                                        stopImageTimer()
                                                        startImageTimer()
                                                    }
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 200, height: 200)
                                                    .foregroundColor(.gray)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                                                    )
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
        .sheet(isPresented: $showingEditSheet) {
            if let userId = authManager.currentUser?.userId {
                EditDailyCheckinView(checkin: checkin, userId: userId)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startImageTimer()
        }
        .onDisappear {
            stopImageTimer()
        }
    }
    
    // Timer methods - properly placed inside the struct
    private func startImageTimer() {
        // Only start timer if there are multiple images
        guard let imageUrls = checkin.imageUrls, imageUrls.count > 1 else { return }
        
        // Stop any existing timer first
        stopImageTimer()
        
        // Create a new timer that fires every few seconds
        imageTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            // Update the image index with animation
            withAnimation {
                self.currentImageIndex = (self.currentImageIndex + 1) % imageUrls.count
            }
        }
    }
    
    private func stopImageTimer() {
        imageTimer?.invalidate()
        imageTimer = nil
    }
    
    // Helper function to get the day name
    private func formattedDay(from date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name (e.g., "Monday")
        return formatter.string(from: date)
    }
}

struct InfoBoxView: View {
    let title: String
    let value: String
    let valueColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(themeManager.captionFont(size: 12))
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            Text(value)
                .font(themeManager.bodyFont(size: 16))
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct ReflectionBoxView: View {
    let title: String
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(themeManager.headingFont(size: 18))
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            Text(text)
                .font(themeManager.bodyFont(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(themeManager.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
        )
    }
}

extension Date {
    func formattedWithOrdinal() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        guard let day = components.day,
              let month = components.month,
              let year = components.year else {
            return ""
        }
        
        // Formatter for month abbreviated and two-digit year.
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let monthString = monthFormatter.string(from: self)
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yy"
        let yearString = yearFormatter.string(from: self)
        
        // Compute ordinal suffix.
        let suffix: String
        switch day {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        
        return "\(monthString) \(day)\(suffix) \(yearString)"
    }
}
