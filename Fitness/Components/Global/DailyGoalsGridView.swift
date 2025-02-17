import SwiftUI

struct DailyGoalsGridView: View {
    @StateObject private var viewModel: DailyGoalsViewModel
    let userId: String
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    let columns = [
        GridItem(.fixed(170), spacing: 16),
        GridItem(.fixed(170), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            DailyGoalBox(label: "Calories", value: viewModel.dailyCalories.isEmpty ? "0" : viewModel.dailyCalories)
            DailyGoalBox(label: "Steps", value: viewModel.dailySteps.isEmpty ? "0" : viewModel.dailySteps)
            DailyGoalBox(label: "Protein", value: viewModel.dailyProtein.isEmpty ? "0" : viewModel.dailyProtein)
            DailyGoalBox(label: "Training", value: viewModel.dailyTraining.isEmpty ? "0" : viewModel.dailyTraining)
        }
    }
}

#Preview {
    DailyGoalsGridView(userId: "dummyUserId")
}
