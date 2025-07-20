import SwiftUI

struct DailyGoalsView: View {
    let userId: String  // The authenticated user's ID
    @StateObject private var viewModel: DailyGoalsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Daily Goals")
                .font(themeManager.titleFont(size: 24))
                .padding(.top, 16)
            
            // A vertical stack of goal fields (without Water)
            VStack(spacing: 12) {
                GoalField(label: "Protein", text: $viewModel.dailyProtein)
                    .environmentObject(themeManager)
                GoalField(label: "Steps", text: $viewModel.dailySteps)
                    .environmentObject(themeManager)
                GoalField(label: "Calories", text: $viewModel.dailyCalories)
                    .environmentObject(themeManager)
                GoalField(label: "Training", text: $viewModel.dailyTraining)
                    .environmentObject(themeManager)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            Spacer()
            
            // Save button
            Button {
                Task {
                    do {
                        // Log current goal values before saving
                        print("Saving goals for user \(userId):")
                        print("Calories: \(viewModel.dailyCalories)")
                        print("Steps: \(viewModel.dailySteps)")
                        print("Protein: \(viewModel.dailyProtein)")
                        print("Training: \(viewModel.dailyTraining)")
                        
                        try await viewModel.saveGoals(userId: userId)
                        
                        await MainActor.run {
                            dismiss()
                        }
                        
                        print("Goals saved successfully.")
                    } catch {
                        print("Error saving goals: \(error.localizedDescription)")
                    }
                }
            } label: {
                Text("Save Goals")
                    .font(themeManager.bodyFont(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .glassEffect(.regular.tint(Color(hex: "002E37")))
            }
            .padding(.bottom, 16)
        }
        .background(Color.clear)
        .presentationDetents([.medium])
        .presentationBackground(.ultraThinMaterial)
    }
}

/// A reusable row for each goal with direct TextField editing.
struct GoalField: View {
    let label: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .cornerRadius(12)
            
            HStack {
                Text(label)
                    .font(themeManager.bodyFont())
                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                Spacer()
                TextField("", text: $text)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                    .font(themeManager.bodyFont())
                    .frame(minWidth: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }
}
