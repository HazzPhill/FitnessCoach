import SwiftUI

struct DayMealPlanCard: View {
    var day: String        // Use full day names (e.g., "Monday")
    var clientId: String
    var isCoach: Bool
    
    private let mealTypes = ["Meal 1", "Meal 2", "Meal 3", "Snack 1", "Snack 2"]
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(day)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .padding(.bottom, 5)
                ForEach(mealTypes, id: \.self) { type in
                    MealRow(clientId: clientId, day: day, mealSlot: type, isCoach: isCoach)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BoxStroke"), lineWidth: 2)
            )
        }
    }
}

#Preview {
    DayMealPlanCard(day: "Monday", clientId: "dummyClientId", isCoach: false)
}
