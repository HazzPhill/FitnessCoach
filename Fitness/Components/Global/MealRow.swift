import SwiftUI

struct MealRow: View {
    var clientId: String
    var day: String
    var mealType: String
    var isCoach: Bool
    
    @StateObject private var viewModel: MealPlanViewModel
    
    init(clientId: String, day: String, mealType: String, isCoach: Bool) {
        self.clientId = clientId
        self.day = day
        self.mealType = mealType
        self.isCoach = isCoach
        _viewModel = StateObject(wrappedValue: MealPlanViewModel(clientId: clientId, day: day, mealType: mealType))
    }
    
    var body: some View {
        NavigationLink {
            if isCoach {
                UploadMealPlanView(clientId: clientId, day: day, mealType: mealType)
            } else {
                MealDetailsView(mealPlan: viewModel.mealPlan)
            }
        } label: {
            HStack {
                Text(viewModel.mealPlan?.mealName ?? mealType)
                    .font(.system(size: 14))
                Spacer()
                Image(systemName: "fork.knife")
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color("BoxStroke"), lineWidth: 2)
            )
            .background(Color("Background"))
            .frame(maxWidth: 220)
        }
    }
}
#Preview {
    MealRow(clientId: "", day: "", mealType: "", isCoach: false)
}