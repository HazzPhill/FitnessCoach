import SwiftUI

struct DailyGoalRow: View {
    let goalName: String
    let goalValue: String
    @Binding var isAchieved: Bool
    
    var body: some View {
        HStack {
            AnimatedCheckBox(isChecked: $isAchieved)
                .frame(width: 40, height: 40)
            Text("\(goalName): \(goalValue.isEmpty ? "Not Set" : goalValue)")
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct AnimatedCheckBox: View {
    @Binding var isChecked: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // Animate a pop effect when toggling.
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                scale = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0).delay(0.1)) {
                scale = 1.0
            }
            isChecked.toggle()
        }) {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isChecked ? Color("Accent") : .gray)
                .scaleEffect(scale)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DailyGoalRow_Previews: PreviewProvider {
    static var previews: some View {
        DailyGoalRow(goalName: "Calories", goalValue: "2000", isAchieved: .constant(true))
    }
}
