import SwiftUI
import CachedAsyncImage

struct UpdateDetailView: View {
    let update: AuthManager.Update
    @State private var showingEditSheet = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
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
            return delta >= 0 ? Color("SecondaryAccent") : Color("Warning")
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
                
                // Title & Date with conditional edit/delete buttons
                HStack {
                    Text(update.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("SecondaryAccent"))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let date = update.date {
                            Text(date.formattedWithOrdinal())
                                .font(.footnote)
                                .foregroundColor(Color("SecondaryAccent"))
                        }
                        
                        // Only show edit/delete for the owner
                        if isOwner {
                            // Edit button
                            Button {
                                showingEditSheet = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color("Accent"))
                            }
                            
                            // Delete button
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color("Warning"))
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
                        valueColor: Color("Accent")
                    )
                    InfoBoxView(
                        title: "Weight check in difference",
                        value: weightDeltaText,
                        valueColor: weightDeltaColor
                    )
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
                .padding(.horizontal)
                
                // Reflection answers
                if let win = update.biggestWin, !win.isEmpty {
                    ReflectionBoxView(
                        title: "Biggest win of the week",
                        text: win
                    )
                    .padding(.horizontal)
                }
                
                if let issues = update.issues, !issues.isEmpty {
                    ReflectionBoxView(
                        title: "Issues encountered",
                        text: issues
                    )
                    .padding(.horizontal)
                }
                
                if let extra = update.extraCoachRequest, !extra.isEmpty {
                    ReflectionBoxView(
                        title: "Extra required from coach",
                        text: extra
                    )
                    .padding(.horizontal)
                }
            }
            .ignoresSafeArea(edges: .top)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color("Background").ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            EditUpdateView(update: update)
                .environmentObject(authManager)
        }
        .alert("Delete Check-in", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteUpdate()
            }
        } message: {
            Text("Are you sure you want to delete this weekly check-in? This action cannot be undone.")
        }
    }
    
    // Function to delete the update
    private func deleteUpdate() {
        guard let updateId = update.id else {
            print("Error: No update ID found")
            return
        }
        
        Task {
            do {
                try await authManager.deleteUpdate(updateId: updateId)
                
                // Return to previous screen
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                print("Error deleting update: \(error.localizedDescription)")
            }
        }
    }
}

// Supporting structs and extensions remain the same...
struct InfoBoxView: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color("SecondaryAccent"))
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct ScoresBoxView: View {
    let calories: Double
    let protein: Double
    let steps: Double
    let training: Double
    let total: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Individual score rows
            HStack {
                Text("Calories")
                Spacer()
                Text("\(Int(calories))/7")
            }
            HStack {
                Text("Protein")
                Spacer()
                Text("\(Int(protein))/7")
            }
            HStack {
                Text("Steps")
                Spacer()
                Text("\(Int(steps))/7")
            }
            HStack {
                Text("Training")
                Spacer()
                Text("\(Int(training))/5")
            }
            
            // Total row
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(String(format: "%.0f/10", total))
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 1)
        )
    }
}

struct ReflectionBoxView: View {
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("SecondaryAccent"))
            Text(text)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 1)
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
