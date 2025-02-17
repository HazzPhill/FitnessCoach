import SwiftUI

struct MealRow: View {
    let clientId: String
    let day: String       // e.g. "Mon"
    let mealSlot: String  // e.g. "Meal 1"
    let isCoach: Bool
    
    @StateObject private var viewModel: DailyMealPlanViewModel
    @Namespace private var zoom
    
    @State private var showUploadSheet = false
    
    init(clientId: String, day: String, mealSlot: String, isCoach: Bool) {
        self.clientId = clientId
        self.day = day
        self.mealSlot = mealSlot
        self.isCoach = isCoach
        _viewModel = StateObject(wrappedValue: DailyMealPlanViewModel(clientId: clientId, day: day, mealSlot: mealSlot))
    }
    
    var body: some View {
        if isCoach {
            // If the user is a coach, tapping the row uploads/edits the meal
            Button {
                showUploadSheet = true
            } label: {
                mealRowLabel
            }
            .sheet(isPresented: $showUploadSheet) {
                // Coach side: upload/edit meal
                UploadMealPlanView(clientId: clientId, day: day, mealSlot: mealSlot)
            }
            .matchedTransitionSource(id: "zoom", in: zoom)
        } else {
            // If the user is a client, tapping the row navigates to meal details
            NavigationLink {
                MealDetailsView(meal: viewModel.meal, mealSlot: mealSlot)
                    .navigationTransition(.zoom(sourceID: "zoom", in: zoom))
            } label: {
                mealRowLabel
            }
            .matchedTransitionSource(id: "zoom", in: zoom)
        }
    }
    
    private var mealRowLabel: some View {
        HStack {
            Text(viewModel.meal?.mealName ?? mealSlot)
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
