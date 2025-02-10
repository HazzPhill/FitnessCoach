import SwiftUI

struct dayMealPlanPreview: View {
    var day: String = "Monday"
    var meal: String
    var snack: String
    var isCoach: Bool = false
    var clientId: String = ""  // New property for the client's ID

    @Namespace private var mealviewtrans

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .padding(.bottom, 5)
                
                NavigationLink {
                    if isCoach {
                        // Use the clientId property instead of an undefined 'client'
                        UploadMealPlanView(clientId: clientId, day: day, mealType: meal)
                    } else {
                        MealDetailsView()
                            .navigationTransition(.zoom(sourceID: "zoommeal", in: mealviewtrans))
                    }
                } label: {
                    HStack {
                        Text("\(meal)")
                            .foregroundStyle(.black)
                            .font(.system(size: 14))
                        Spacer()
                        Image(systemName:"fork.knife")
                            .foregroundStyle(.black)
                    }
                    .matchedTransitionSource(id:"zoommeal", in: mealviewtrans)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("BoxStroke"), lineWidth: 2)
                    )
                    .background(Color("Background"))
                    .frame(maxWidth: 220)
                }
                // You can similarly add NavigationLinks for snacks if needed.
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BoxStroke"), lineWidth: 2)
            )
            .background(Color.white)
        }
    }
}

#Preview {
    // For preview, provide a dummy clientId if needed.
    dayMealPlanPreview(day: "Mon", meal: "Meal 1", snack: "Snack 1", isCoach: true, clientId: "dummyClientId")
}
