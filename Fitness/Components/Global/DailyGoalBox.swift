import SwiftUI

struct DailyGoalBox: View {
    var label: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink {
                DailyGoalsView(userId: "123")
            } label: {
                VStack{
                    Text(value)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    Text(label)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.5))
                }
                .padding()
            }
           
            .frame(width: 164, height: 80, alignment: .leading)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("BoxStroke"), lineWidth: 2)
            )
            .background(Color.white)
        }
    }
}

#Preview {
    DailyGoalBox(label: "Calories", value: "2000")
}
