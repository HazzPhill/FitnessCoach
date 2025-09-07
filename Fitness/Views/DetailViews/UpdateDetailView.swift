import SwiftUI
import CachedAsyncImage

struct UpdateDetailView: View {
    let update: AuthManager.Update
    @State private var showingEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showFullScreenImage = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Check if current user is the owner of this update
    private var isOwner: Bool {
        return authManager.currentUser?.userId == update.userId
    }
    
    private var weightDeltaText: String {
        guard let _ = update.date else { return "N/A" }
        let userUpdates = authManager.latestUpdates
            .filter { $0.userId == update.userId && $0.date != nil }
            .sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        if let index = userUpdates.firstIndex(where: { $0.id == update.id }), index > 0 {
            let previousUpdate = userUpdates[index - 1]
            let delta = update.weight - previousUpdate.weight
            let sign = delta >= 0 ? "+" : ""
            return sign + String(format: "%.1fKG", delta)
        }
        return "N/A"
    }
    
    private var weightDeltaColor: Color {
        guard let _ = update.date else { return .gray }
        let userUpdates = authManager.latestUpdates
            .filter { $0.userId == update.userId && $0.date != nil }
            .sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        if let index = userUpdates.firstIndex(where: { $0.id == update.id }), index > 0 {
            let previousUpdate = userUpdates[index - 1]
            let delta = update.weight - previousUpdate.weight
            if colorScheme == .dark {
                return delta >= 0 ? .white : .white.opacity(0.7)
            }
            return delta >= 0 ? themeManager.accentColor(for: colorScheme) : Color.red
        }
        return .gray
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top image with tap gesture for full-screen viewing
                ZStack(alignment: .bottom) {
                    if let imageUrl = update.imageUrl, let url = URL(string: imageUrl) {
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        showFullScreenImage = true
                                    }
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
                    } else {
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                    }
                    
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
                    .allowsHitTesting(false)
                    
                    // Add tap hint icon
                    if update.imageUrl != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                    .padding(12)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Custom back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(themeManager.bodyFont(size: 16))
                        }
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor(for: colorScheme).opacity(0.2))
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Title & Date with conditional edit/delete buttons
                HStack {
                    Text(update.name)
                        .font(themeManager.titleFont(size: 22))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let date = update.date {
                            Text(date.formattedWithOrdinal())
                                .font(themeManager.captionFont())
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        }
                        
                        // Only show edit/delete for the owner
                        if isOwner {
                            // Edit button
                            Button {
                                showingEditSheet = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                            
                            // Delete button
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color.red)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Current Weight & Difference
                HStack(spacing: 16) {
                    InfoBoxView(
                        title: "Current Weight",
                        value: String(format: "%.0fKG", update.weight),
                        valueColor: themeManager.accentOrWhiteText(for: colorScheme)
                    )
                    .environmentObject(themeManager)
                    
                    InfoBoxView(
                        title: "Weight check in difference",
                        value: weightDeltaText,
                        valueColor: weightDeltaColor
                    )
                    .environmentObject(themeManager)
                }
                .padding(.horizontal)
                
                // Scores Box
                ScoresBoxView(update: update)
                    .environmentObject(themeManager)
                    .padding(.horizontal)
                
                // Reflection answers
                if let win = update.biggestWin, !win.isEmpty {
                    ReflectionBoxView(
                        title: "Biggest win of the week",
                        text: win
                    )
                    .environmentObject(themeManager)
                    .padding(.horizontal)
                }
                
                if let issues = update.issues, !issues.isEmpty {
                    ReflectionBoxView(
                        title: "Issues encountered",
                        text: issues
                    )
                    .environmentObject(themeManager)
                    .padding(.horizontal)
                }
                
                if let extra = update.extraCoachRequest, !extra.isEmpty {
                    ReflectionBoxView(
                        title: "Extra required from coach",
                        text: extra
                    )
                    .environmentObject(themeManager)
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(edges: .top)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .background(themeManager.backgroundColor(for: colorScheme).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            EditUpdateView(update: update)
                .environmentObject(authManager)
                .environmentObject(themeManager)
        }
        .alert("Delete Check-in", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteUpdate()
            }
        } message: {
            Text("Are you sure you want to delete this weekly check-in? This action cannot be undone.")
                .font(themeManager.bodyFont())
        }
        .fullScreenCover(isPresented: $showFullScreenImage) {
            if let imageUrl = update.imageUrl {
                FullScreenImageViewer(
                    imageUrls: [imageUrl],
                    currentIndex: 0,
                    isPresented: $showFullScreenImage
                )
                .environmentObject(themeManager)
            }
        }
    }
    
    private func deleteUpdate() {
        guard let updateId = update.id else {
            print("Error: No update ID found")
            return
        }
        
        Task {
            do {
                try await authManager.deleteUpdate(updateId: updateId)
                
                await MainActor.run {
                    authManager.refreshWeeklyUpdates()
                    print("✅ First refresh completed after deletion")
                    
                    NotificationCenter.default.post(name: .weeklyCheckInStatusChanged, object: nil)
                    print("📢 Posted weeklyCheckInStatusChanged notification")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        authManager.refreshWeeklyUpdates()
                        print("✅ Second refresh completed after delay")
                    }
                }
                
                try? await Task.sleep(nanoseconds: 600_000_000)
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error deleting update: \(error.localizedDescription)")
            }
        }
    }
}

struct ScoresBoxView: View {
    let update: AuthManager.Update
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Calories")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(update.caloriesRating ?? 0)/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Protein")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(update.proteinRating ?? 0)/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Steps")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(update.stepsRating ?? 0)/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Training")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(update.trainingRating ?? 0)/5")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            
            HStack {
                Text("Total")
                    .font(themeManager.bodyFont())
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text(String(format: "%.1f/10", update.finalScore ?? 0))
                    .font(themeManager.bodyFont())
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            }
        }
        .padding()
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
        )
    }
}
