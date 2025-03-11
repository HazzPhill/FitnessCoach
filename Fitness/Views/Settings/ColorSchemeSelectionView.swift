import SwiftUI

struct ColorSchemeSelectionView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Filter color schemes based on current mode
    private var lightSchemes: [ColorScheme] {
        ColorScheme.allCases.filter { $0.isLightMode }
    }
    
    private var darkSchemes: [ColorScheme] {
        ColorScheme.allCases.filter { !$0.isLightMode }
    }
    
    // Determine which schemes to show based on selected theme mode
    private var availableSchemes: [ColorScheme] {
        switch themeManager.selectedTheme {
        case .light:
            return lightSchemes
        case .dark:
            return darkSchemes
        case .system:
            // Show all schemes when in system mode
            return ColorScheme.allCases
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    Text("Select a color scheme to customise your app's appearance. The accent color will automatically adjust based on your theme selection.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    ForEach(availableSchemes) { scheme in
                        Button {
                            themeManager.selectedColorScheme = scheme
                            // Add haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        } label: {
                            SchemePreviewCell(scheme: scheme, isSelected: themeManager.selectedColorScheme.id == scheme.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Color Scheme")
    }
}

// Preview cell for a color scheme
struct SchemePreviewCell: View {
    let scheme: ColorScheme
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview of the scheme
            HStack(spacing: 0) {
                // Background color
                scheme.backgroundColor
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Background")
                            .font(.caption)
                            .foregroundColor(scheme.textColor)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8),
                        alignment: .center
                    )
                
                // Accent color
                scheme.accentColor
                    .frame(width: 150, height: 100)
                    .overlay(
                        Text("Accent")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8),
                        alignment: .center
                    )
            }
            .cornerRadius(12)
            
            // Scheme info
            HStack {
                Text(scheme.displayName)
                    .font(.headline)
                    .foregroundColor(Color.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .padding(.horizontal)
    }
}

struct ColorSchemeSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ColorSchemeSelectionView()
                .environmentObject(ThemeManager())
        }
    }
}
