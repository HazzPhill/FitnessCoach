import SwiftUI

struct KPIBox: View {
    var label: String
    var figure: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack (alignment:.leading) {
            Text("\(figure)")
                .font(.system(size: 36, weight: .semibold, design: .default))
                .foregroundColor(themeManager.textColor(for: colorScheme))
            
            Text("\(label)")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
        }
        .frame(width: 164, height: 98, alignment: .leading)
        .padding(.leading,16)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
        )
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    KPIBox(label: "Clients", figure: 200)
        .environmentObject(ThemeManager())
}
