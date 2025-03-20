import SwiftUI

// MARK: - Custom View Extension for Placeholder
extension View {
    @ViewBuilder func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
            ZStack(alignment: alignment) {
                if shouldShow {
                    placeholder()
                }
                self
            }
        }
}

// MARK: - ModernTextField
struct ModernTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme: SwiftUI.ColorScheme
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(themeManager.bodyFont())
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme).opacity(0.5))
                    .padding(.horizontal)
            }
            
            TextField("", text: $text)
                .font(themeManager.bodyFont())
                .keyboardType(keyboardType)
                .padding()
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                )
                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
        }
        .padding(.horizontal)
    }
}

// MARK: - StrokedTextField
struct StrokedTextField: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    // Customisable properties
    let label: String
    let placeholder: String
    let strokeColor: Color
    let textColor: Color
    let labelColor: Color
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let iconName: String? // Optional icon
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(themeManager.captionFont())
                .foregroundColor(labelColor)
            
            // TextField with optional icon
            HStack {
                TextField("", text: $text)
                    .font(themeManager.bodyFont())
                    .foregroundColor(textColor)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .font(themeManager.bodyFont())
                            .foregroundColor(.white) // Custom placeholder color
                    }
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(textColor)
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - StrokedSecureField
struct StrokedSecureField: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let placeholder: String
    let strokeColor: Color
    let textColor: Color
    let labelColor: Color
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(themeManager.captionFont())
                .foregroundColor(labelColor)
            
            // SecureField styled with padding
            SecureField("", text: $text)
                .font(themeManager.bodyFont())
                .foregroundColor(textColor)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .font(themeManager.bodyFont())
                        .foregroundColor(.white) // Custom placeholder color
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting UI Components
struct HeaderSection: View {
    let title: String
    let subtitle: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            Text(title)
                .font(themeManager.bodyFont(size: 20))
                .foregroundStyle(.white)
            
            Text(subtitle)
                .font(themeManager.headingFont(size: 30))
                .foregroundStyle(.white)
        }
    }
}

struct ErrorMessageView: View {
    let message: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(message)
            .font(themeManager.bodyFont(size: 14))
            .foregroundColor(.red)
            .padding(.horizontal)
    }
}

struct ActionButton: View {
    let label: String
    let backgroundColor: Color
    let textColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Text(label)
            .font(themeManager.bodyFont(size: 16))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundColor)
            .cornerRadius(25)
            .padding(.horizontal)
    }
}

// MARK: - Loading Button
struct LoadingButton: View {
    let label: String
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    let isLoading: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .tint(accentColor)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(backgroundColor)
                    .cornerRadius(25)
            } else {
                Text(label)
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(backgroundColor)
                    .cornerRadius(25)
            }
        }
        .disabled(isLoading)
        .padding(.horizontal)
    }
}


struct ModernRoleSelector: View {
    @Binding var selectedRole: UserRole
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme: SwiftUI.ColorScheme
    
    // Animation state
    @Namespace private var animation
    @State private var animateSelection = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I am a")
                .font(themeManager.captionFont())
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 4)
            
            // Custom segmented control
            ZStack(alignment: .center) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 60)
                
                // Selection tabs
                HStack(spacing: 0) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        RoleOption(
                            role: role,
                            isSelected: selectedRole == role,
                            namespace: animation,
                            animateSelection: animateSelection,
                            swiftUIColorScheme: colorScheme
                        )
                        .environmentObject(themeManager)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = role
                                
                                // Trigger animation sequence
                                animateSelection = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        animateSelection = true
                                    }
                                }
                                
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                    }
                }
                .padding(5)
            }
        }
        .onAppear {
            // Initial animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    animateSelection = true
                }
            }
        }
    }
}

struct RoleOption: View {
    let role: UserRole
    let isSelected: Bool
    var namespace: Namespace.ID
    var animateSelection: Bool
    var swiftUIColorScheme: SwiftUI.ColorScheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Selected background
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .matchedGeometryEffect(id: "SelectedBackground", in: namespace)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 0)
            }
            
            // Content
            HStack(spacing: 10) {
                // Role icon
                Image(systemName: roleIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .opacity(animateSelection || !isSelected ? 1 : 0)
                    .scaleEffect(animateSelection || !isSelected ? 1 : 0.7)
                
                // Role name
                Text(role.rawValue.capitalized)
                    .font(themeManager.bodyFont())
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
        }
        .contentShape(Rectangle())
        .scaleEffect(isSelected && animateSelection ? 1.02 : 1)
    }
    
    // Get icon for each role
    private var roleIcon: String {
        switch role {
        case .client:
            return "figure.run"
        case .coach:
            return "figure.strengthtraining.traditional"
        }
    }
    
    // Get appropriate text color based on selection state and color scheme
    private var textColor: Color {
        if isSelected {
            // When selected, use dark color for better contrast against white background
            return themeManager.accentColor(for: swiftUIColorScheme)
        } else {
            // When not selected, always use white for contrast against the accent background
            return .white.opacity(0.7)
        }
    }
    
    // Get appropriate icon color based on selection state and color scheme
    private var iconColor: Color {
        if isSelected {
            // When selected, use accent color for better contrast against white background
            return themeManager.accentColor(for: swiftUIColorScheme)
        } else {
            // When not selected, always use white for contrast against the accent background
            return .white.opacity(0.7)
        }
    }
}

// MARK: - Preview
struct ModernRoleSelector_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color("Accent")
                .ignoresSafeArea()
            
            ModernRoleSelector(selectedRole: .constant(.client))
                .environmentObject(ThemeManager())
                .padding()
        }
    }
}
