import SwiftUI

struct DailyGoalBox: View {
    var label: String
    var value: String
    var userId: String // Add this parameter
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink {
               DailyGoalsView(userId: userId) // Use the passed userId
            } label: {
                VStack(alignment: .leading){
                    Text(value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                    Text(label)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
                }
                .padding()
                .frame(maxWidth:.infinity, minHeight: 75, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                )
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

#Preview {
    DailyGoalBox(label: "Calories", value: "2000", userId: "12345")
        .environmentObject(ThemeManager())
}
