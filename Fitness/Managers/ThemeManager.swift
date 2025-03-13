import SwiftUI
import Combine


// Define mode selection
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// Define color scheme combinations
enum ColorScheme: String, CaseIterable, Identifiable {
    // Light mode schemes
    case defaultLight = "default_light"
    case purpleLight = "purple_light"
    case redLight = "red_light"
    case yellowLight = "yellow_light"
    
    // Dark mode schemes
    case defaultDark = "default_dark"
    case purpleDark = "purple_dark"
    case redDark = "red_dark"
    case yellowDark = "yellow_dark"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        // Light mode names
        case .defaultLight: return "Default"
        case .purpleLight: return "Purple"
        case .redLight: return "Red"
        case .yellowLight: return "Yellow"
        
        // Dark mode names
        case .defaultDark: return "Default"
        case .purpleDark: return "Purple"
        case .redDark: return "Red"
        case .yellowDark: return "Yellow"
        }
    }
    
    var isLightMode: Bool {
        self == .defaultLight || self == .purpleLight || self == .redLight || self == .yellowLight
    }
    
    // Background color for this scheme
    var backgroundColor: Color {
        switch self {
        // Light mode backgrounds
        case .defaultLight: return Color(hex: "F9F8F4")
        case .purpleLight: return Color(hex: "FBF2FF")
        case .redLight: return Color(hex: "FFF6F6")
        case .yellowLight: return Color(hex: "FFFFEC")
        
        // Dark mode backgrounds
        case .defaultDark: return Color(hex: "262626")
        case .purpleDark: return Color(hex: "14001C")
        case .redDark: return Color(hex: "1F0000")
        case .yellowDark: return Color(hex: "1A1A00")
        }
    }
    
    // Accent color for this scheme
    var accentColor: Color {
        switch self {
        // Light mode accents
        case .defaultLight: return Color(hex: "5A7D7C")
        case .purpleLight: return Color(hex: "7E00B6")
        case .redLight: return Color(hex: "1F0000") // For red light, accent is actually dark
        case .yellowLight: return Color(hex: "464400")
        
        // Dark mode accents
        case .defaultDark: return Color(hex: "383E3E")
        case .purpleDark: return Color(hex: "39293F")
        case .redDark: return Color(hex: "3F2929")
        case .yellowDark: return Color(hex: "464400")
        }
    }
    
    // Secondary accent (used for some UI elements)
    var secondaryAccentColor: Color {
        switch self {
        case .defaultLight, .defaultDark:
            return Color(hex: "344E4D")
        default:
            return accentColor.opacity(0.8)
        }
    }
    
    // Get the appropriate text color for this color scheme
    var textColor: Color {
        switch self {
        // Light schemes have dark text
        case .defaultLight, .purpleLight, .redLight, .yellowLight:
            return Color.black
        
        // Dark schemes have light text
        case .defaultDark, .purpleDark, .redDark, .yellowDark:
            return Color.white
        }
    }
    
    // Card/detail box background color
    var cardBackgroundColor: Color {
        switch self {
        // Light mode detail backgrounds
        case .defaultLight, .purpleLight, .redLight, .yellowLight:
            return Color.white
            
        // Dark mode detail backgrounds
        case .defaultDark, .purpleDark, .redDark, .yellowDark:
            return Color.gray.opacity(0.2)
        }
    }
    
    // Convert between light and dark versions of the same theme
    func toggleLightDark() -> ColorScheme {
        switch self {
        // Light to dark
        case .defaultLight: return .defaultDark
        case .purpleLight: return .purpleDark
        case .redLight: return .redDark
        case .yellowLight: return .yellowDark
        
        // Dark to light
        case .defaultDark: return .defaultLight
        case .purpleDark: return .purpleLight
        case .redDark: return .redLight
        case .yellowDark: return .yellowLight
        }
    }
}

// Theme manager class to handle theme preferences
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var selectedColorScheme: ColorScheme {
        didSet {
            UserDefaults.standard.set(selectedColorScheme.rawValue, forKey: "selectedColorScheme")
        }
    }
    
    init() {
        // Load saved preferences or use defaults
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.system.rawValue
        let savedColorScheme = UserDefaults.standard.string(forKey: "selectedColorScheme") ?? ColorScheme.defaultLight.rawValue
        
        self.selectedTheme = AppTheme(rawValue: savedTheme) ?? .system
        self.selectedColorScheme = ColorScheme(rawValue: savedColorScheme) ?? .defaultLight
    }
    
    // Get the appropriate color scheme based on system and user preferences
    func activeColorScheme(for systemColorScheme: SwiftUI.ColorScheme) -> ColorScheme {
        switch selectedTheme {
        case .system:
            // Follow system, but keep color family
            let baseScheme = selectedColorScheme
            return systemColorScheme == .dark ?
                (baseScheme.isLightMode ? baseScheme.toggleLightDark() : baseScheme) :
                (baseScheme.isLightMode ? baseScheme : baseScheme.toggleLightDark())
            
        case .light:
            // Force light mode, but keep color family
            return selectedColorScheme.isLightMode ?
                selectedColorScheme :
                selectedColorScheme.toggleLightDark()
            
        case .dark:
            // Force dark mode, but keep color family
            return selectedColorScheme.isLightMode ?
                selectedColorScheme.toggleLightDark() :
                selectedColorScheme
        }
    }
    
    // Get the background color
    func backgroundColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        activeColorScheme(for: colorScheme).backgroundColor
    }
    
    // Get the accent color
    func accentColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        activeColorScheme(for: colorScheme).accentColor
    }
    
    // Get the secondary accent color
    func secondaryAccentColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        activeColorScheme(for: colorScheme).secondaryAccentColor
    }
    
    // Get the text color
    func textColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        activeColorScheme(for: colorScheme).textColor
    }
    
    // Get accent text color that should be white in dark mode
    // and accent in light mode - critical for charts and special text
    func accentOrWhiteText(for colorScheme: SwiftUI.ColorScheme) -> Color {
        // Explicitly force white in dark mode
        if colorScheme == .dark || selectedTheme == .dark {
            return .white
        }
        // Use accent color in light mode
        return accentColor(for: colorScheme)
    }
    
    // Get axis label color that should be white in dark mode
    // and gray in light mode - specifically for chart axes
    func chartAxisColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        // Force white in dark mode, no conditions or checks
        if colorScheme == .dark {
            return .white
        }
        // In light mode, use accent color
        return accentColor(for: colorScheme)
    }
    
    // Get the card background color
    func cardBackgroundColor(for colorScheme: SwiftUI.ColorScheme) -> Color {
        activeColorScheme(for: colorScheme).cardBackgroundColor
    }
}


// Helper extension to create colors from hex strings
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


struct AnimatedThemePicker: View {
    @Binding var selectedTheme: AppTheme
    @Environment(\.colorScheme) var systemColorScheme
    @ObservedObject var themeManager: ThemeManager
    
    // Animation properties
    @State private var animateIndicator = false
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .center) {
            // Background card
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor(for: systemColorScheme))
                .frame(height: 40)
            
            // Theme options in horizontal layout
            HStack(spacing: 0) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOption(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        themeManager: themeManager,
                        systemColorScheme: systemColorScheme,
                        namespace: animation
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTheme = theme
                            
                            // Trigger indicator animation
                            animateIndicator = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    animateIndicator = true
                                }
                            }
                            
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                }
            }
            .padding(4)
        }
        .padding(.horizontal)
        .onAppear {
            // Initial animation when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    animateIndicator = true
                }
            }
        }
    }
}

struct ThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let themeManager: ThemeManager
    let systemColorScheme: SwiftUI.ColorScheme
    var namespace: Namespace.ID
    
    var body: some View {
        ZStack {
            // Selected indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeAccentColor)
                    .matchedGeometryEffect(id: "SelectedBackground", in: namespace)
                    .shadow(color: themeAccentColor.opacity(0.5), radius: 5, x: 0, y: 0)
            }
            
            // Content
            HStack(spacing: 8) {
                // Theme icon
                Image(systemName: themeIconName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : themeManager.textColor(for: systemColorScheme).opacity(0.8))
                
                Text(theme.displayName)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : themeManager.textColor(for: systemColorScheme).opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
    
    // Get appropriate icon for each theme
    private var themeIconName: String {
        switch theme {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
    
    // Get accent color for each theme that matches the theme colors
    private var themeAccentColor: Color {
        switch theme {
        case .system:
            // Use the default accent color
            return themeManager.activeColorScheme(for: systemColorScheme).accentColor
        case .light:
            // Use a light mode accent color
            return themeManager.activeColorScheme(for: .light).accentColor
        case .dark:
            // Use a dark mode accent color
            return themeManager.activeColorScheme(for: .dark).accentColor
        }
        
    }
}

extension ThemeManager {
    // Get the title font (Stranded)
    func titleFont(size: CGFloat = 24) -> Font {
        return .manfieldSemiBold(size: size)
    }
    
    // Get the heading font (Stranded)
    func headingFont(size: CGFloat = 24) -> Font {
        return .manfieldSemiBold(size: size)
    }
    
    // Get the body font (Macaria)
    func bodyFont(size: CGFloat = 16) -> Font {
        return .Mansfield(size: size)
    }
    
    // Get the caption font (Macaria)
    func captionFont(size: CGFloat = 12) -> Font {
        return .Mansfield(size: size)
    }
}
