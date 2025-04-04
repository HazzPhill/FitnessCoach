import SwiftUI

struct DailyGoalsView: View {
    let userId: String  // The authenticated user's ID
    @StateObject private var viewModel: DailyGoalsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Tracks whether we're in "Edit" mode
    @State private var isEditing = false
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Set Daily Goals")
                        .font(themeManager.titleFont(size: 24))
                        .padding(.top, 16)
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    // A vertical stack of goal fields (without Water)
                    VStack(spacing: 12) {
                        GoalField(label: "Calories", text: $viewModel.dailyCalories, isEditing: $isEditing)
                            .environmentObject(themeManager)
                        GoalField(label: "Steps", text: $viewModel.dailySteps, isEditing: $isEditing)
                            .environmentObject(themeManager)
                        GoalField(label: "Protein", text: $viewModel.dailyProtein, isEditing: $isEditing)
                            .environmentObject(themeManager)
                        GoalField(label: "Training", text: $viewModel.dailyTraining, isEditing: $isEditing)
                            .environmentObject(themeManager)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Button toggles between "Edit" and "Save Goals"
                    Button {
                        if isEditing {
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
                                        isEditing = false
                                    }
                                    
                                    print("Goals saved successfully.")
                                } catch {
                                    print("Error saving goals: \(error.localizedDescription)")
                                }
                            }
                        } else {
                            isEditing = true
                        }
                    } label: {
                        Text(isEditing ? "Save Goals" : "Edit")
                            .font(themeManager.bodyFont(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.backgroundColor(for: colorScheme))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(themeManager.accentColor(for: colorScheme))
                            .cornerRadius(25)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
            }
            .navigationTitle("Daily Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

/// A reusable row for each goal. If `isEditing` is false, it shows the current text plus a pencil icon.
/// If `isEditing` is true, it shows a TextField for editing.
struct GoalField: View {
    let label: String
    @Binding var text: String
    @Binding var isEditing: Bool
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
                if isEditing {
                    TextField("", text: $text)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(themeManager.textColor(for: colorScheme))
                        .font(themeManager.bodyFont())
                        .frame(minWidth: 50)
                } else {
                    HStack(spacing: 4) {
                        Text(text.isEmpty ? "Not set" : text)
                            .font(themeManager.bodyFont())
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        Image(systemName: "pencil")
                            .foregroundStyle(themeManager.accentColor(for: colorScheme).opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }
}
