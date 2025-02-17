import SwiftUI

struct DailyGoalsView: View {
    let userId: String  // The authenticated user's ID
    @StateObject private var viewModel: DailyGoalsViewModel
    @Environment(\.dismiss) var dismiss
    
    // Tracks whether we're in "Edit" mode
    @State private var isEditing = false
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Set Daily Goals")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.top, 16)
                        .foregroundColor(Color("Accent"))
                    
                    // A vertical stack of goal fields (without Water)
                    VStack(spacing: 12) {
                        GoalField(label: "Calories", text: $viewModel.dailyCalories, isEditing: $isEditing)
                        GoalField(label: "Steps", text: $viewModel.dailySteps, isEditing: $isEditing)
                        GoalField(label: "Protein", text: $viewModel.dailyProtein, isEditing: $isEditing)
                        GoalField(label: "Training", text: $viewModel.dailyTraining, isEditing: $isEditing)
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
                            .font(.headline)
                            .foregroundColor(Color("Background"))
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color("Accent"))
                            .cornerRadius(25)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

/// A reusable row for each goal. If `isEditing` is false, it shows the current text plus a pencil icon.
/// If `isEditing` is true, it shows a TextField for editing.
struct GoalField: View {
    let label: String
    @Binding var text: String
    @Binding var isEditing: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 2)
                .background(Color.white)
                .cornerRadius(12)
            
            HStack {
                Text(label)
                    .font(.body)
                    .foregroundColor(.black)
                Spacer()
                if isEditing {
                    TextField("", text: $text)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.black)
                        .font(.body)
                        .frame(minWidth: 50)
                } else {
                    HStack(spacing: 4) {
                        Text(text.isEmpty ? "Not set" : text)
                            .font(.body)
                            .foregroundColor(.black)
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }
}

#Preview {
    DailyGoalsView(userId: "dummyUserId")
}
