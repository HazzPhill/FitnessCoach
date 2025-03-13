import SwiftUI

struct ModernBackButton: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                Text("Back")
                    .font(themeManager.bodyFont(size: 16))
            }
            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Capsule()
                    .fill(themeManager.accentColor(for: colorScheme).opacity(0.2))
            )
        }
    }
}

#Preview {
    ModernBackButton()
        .environmentObject(ThemeManager())
}
