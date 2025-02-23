import SwiftUI

struct DailyGoalBox: View {
    var label: String
    var value: String
    var userId: String // Add this parameter
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink {
               DailyGoalsView(userId: userId) // Use the passed userId
            } label: {
                VStack(alignment: .leading){
                    Text(value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    Text(label)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding()
                .frame(maxWidth:.infinity, minHeight: 75,alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
                .background(Color.white)
            }
        }
    }
}

#Preview {
    DailyGoalBox(label: "Calories", value: "2000", userId: "12345")
}
