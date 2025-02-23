import SwiftUI

struct DailyGoalsGridView: View {
    @StateObject private var viewModel: DailyGoalsViewModel
    let userId: String
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                DailyGoalBox(label: "Calories", value: viewModel.dailyCalories.isEmpty ? "0" : viewModel.dailyCalories, userId: userId)
                DailyGoalBox(label: "Steps", value: viewModel.dailySteps.isEmpty ? "0" : viewModel.dailySteps, userId: userId)
                DailyGoalBox(label: "Protein", value: viewModel.dailyProtein.isEmpty ? "0" : viewModel.dailyProtein, userId: userId)
                DailyGoalBox(label: "Training", value: viewModel.dailyTraining.isEmpty ? "0" : viewModel.dailyTraining, userId: userId)
            }
            .padding(.horizontal, 0)          // Remove horizontal padding
        }
        .edgesIgnoringSafeArea(.horizontal)   // Ignore safe area padding on sides
    }
}

#Preview {
    DailyGoalsGridView(userId: "dummyUserId")
}
