import SwiftUI
import CachedAsyncImage

struct UpdateDetailView: View {
    let update: AuthManager.Update
    @State private var showingEditSheet = false
    @State private var showDeleteAlert = false
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
            // In dark mode, use white for the text but with different opacity
            if colorScheme == .dark {
                return delta >= 0 ? .white : .white.opacity(0.7)
            }
            // In light mode, use accent or red
            return delta >= 0 ? themeManager.accentColor(for: colorScheme) : Color.red
        }
        return .gray
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top image
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
                ScoresBoxView(
                    calories: update.caloriesScore ?? 0,
                    protein: update.proteinScore ?? 0,
                    steps: update.stepsScore ?? 0,
                    training: update.trainingScore ?? 0,
                    total: update.finalScore ?? 0
                )
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
    }
    
    private func deleteUpdate() {
        guard let updateId = update.id else {
            print("Error: No update ID found")
            return
        }
        
        Task {
            do {
                try await authManager.deleteUpdate(updateId: updateId)
                
                // Force refresh the updates
                authManager.refreshWeeklyUpdates()
                
                // Post a notification that an update was deleted
                NotificationCenter.default.post(name: .weeklyCheckInStatusChanged, object: nil)
                
                // Add a small delay to ensure Firebase operations complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Return to previous screen
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
    let calories: Double
    let protein: Double
    let steps: Double
    let training: Double
    let total: Double
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Individual score rows
            HStack {
                Text("Calories")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(Int(calories))/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Protein")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(Int(protein))/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Steps")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(Int(steps))/7")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            HStack {
                Text("Training")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text("\(Int(training))/5")
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
            
            // Total row
            HStack {
                Text("Total")
                    .font(themeManager.bodyFont())
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                Text(String(format: "%.0f/10", total))
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
