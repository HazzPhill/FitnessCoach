import SwiftUI

struct dayMealPlanPreview: View {
    var day: String = "Mon"
    var meal: String
    var snack: String
    var isCoach: Bool = false
    var clientId: String = ""  // New property for the client's ID
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    @Namespace private var mealviewtrans

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                    .padding(.bottom, 5)
                
                NavigationLink {
                    if isCoach {
                        // Use the clientId property instead of an undefined 'client'
                        UploadMealPlanView(clientId: clientId, day: day, mealSlot: meal)
                            .environmentObject(themeManager)
                    } else {
                        MealDetailsView(meal: nil, mealSlot: meal)
                            .environmentObject(themeManager)
                            .navigationTransition(.zoom(sourceID: "zoommeal", in: mealviewtrans))
                    }
                } label: {
                    HStack {
                        Text("\(meal)")
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            .font(.system(size: 14))
                        Spacer()
                        Image(systemName:"fork.knife")
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                    .matchedTransitionSource(id:"zoommeal", in: mealviewtrans)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
                    )
                    .background(themeManager.backgroundColor(for: colorScheme))
                    .frame(maxWidth: 220)
                }
                // You can similarly add NavigationLinks for snacks if needed.
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
            )
            .background(themeManager.cardBackgroundColor(for: colorScheme))
        }
    }
}

#Preview {
    // For preview, provide a dummy clientId if needed.
    Group {
        dayMealPlanPreview(day: "Mon", meal: "Meal 1", snack: "Snack 1", isCoach: true, clientId: "dummyClientId")
            .environmentObject(ThemeManager())
            .preferredColorScheme(.light)
        
        dayMealPlanPreview(day: "Mon", meal: "Meal 1", snack: "Snack 1", isCoach: true, clientId: "dummyClientId")
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
}
