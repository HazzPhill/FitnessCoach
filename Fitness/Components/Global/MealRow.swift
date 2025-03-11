import SwiftUI

struct MealRow: View {
    let clientId: String
    let day: String       // e.g. "Mon"
    let mealSlot: String  // e.g. "Meal 1"
    let isCoach: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
                    .environmentObject(themeManager)
            }
            .matchedTransitionSource(id: "zoom", in: zoom)
        } else {
            // If the user is a client, tapping the row navigates to meal details
            NavigationLink {
                MealDetailsView(meal: viewModel.meal, mealSlot: mealSlot)
                    .environmentObject(themeManager)
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
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            Spacer()
            Image(systemName: "fork.knife")
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
        )
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .frame(maxWidth: 220)
    }
}

#Preview {
    Group {
        MealRow(clientId: "test123", day: "Mon", mealSlot: "Meal 1", isCoach: false)
            .environmentObject(ThemeManager())
            .preferredColorScheme(.light)
        
        MealRow(clientId: "test123", day: "Mon", mealSlot: "Meal 1", isCoach: false)
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
}
