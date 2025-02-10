import SwiftUI

struct MealRow: View {
    var clientId: String
    var day: String
    var mealType: String
    var isCoach: Bool
    
    @StateObject private var viewModel: MealPlanViewModel
    @Namespace private var zoom
    @State private var showUploadSheet = false  // Controls sheet presentation for coach
    
    init(clientId: String, day: String, mealType: String, isCoach: Bool) {
        self.clientId = clientId
        self.day = day
        self.mealType = mealType
        self.isCoach = isCoach
        _viewModel = StateObject(wrappedValue: MealPlanViewModel(clientId: clientId, day: day, mealType: mealType))
    }
    
    var body: some View {
        if isCoach {
            Button {
                showUploadSheet = true
            } label: {
                mealRowLabel
            }
            .sheet(isPresented: $showUploadSheet) {
                UploadMealPlanView(clientId: clientId, day: day, mealType: mealType)
            }
            .matchedTransitionSource(id: "zoom", in: zoom)
        } else {
            NavigationLink {
                MealDetailsView(mealPlan: viewModel.mealPlan)
                    .navigationTransition(.zoom(sourceID: "zoom", in: zoom))
            } label: {
                mealRowLabel
            }
            .matchedTransitionSource(id: "zoom", in: zoom)
        }
    }
    
    // Extract the common label view.
    private var mealRowLabel: some View {
        HStack {
            Text(viewModel.mealPlan?.mealName ?? mealType)
                .font(.system(size: 14))
                .foregroundStyle(Color("SecondaryAccent"))
            Spacer()
            Image(systemName: "fork.knife")
                .foregroundStyle(Color("SecondaryAccent"))
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

#Preview {
    MealRow(clientId: "dummyClientId", day: "Monday", mealType: "Meal 1", isCoach: true)
}
