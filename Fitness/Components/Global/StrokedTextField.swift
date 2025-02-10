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
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(Color.white.opacity(0.1))
            .foregroundColor(.black)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color("Accent"), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

// MARK: - StrokedTextField
struct StrokedTextField: View {
    @Binding var text: String
    
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
                .font(.caption)
                .foregroundColor(labelColor)
            
            // TextField with optional icon
            HStack {
                TextField("", text: $text)
                    .foregroundColor(textColor)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
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
                .font(.caption)
                .foregroundColor(labelColor)
            
            // SecureField styled with padding
            SecureField("", text: $text)
                .foregroundColor(textColor)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
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
    
    var body: some View {
        Group {
            Text(title)
                .foregroundStyle(.white)
                .font(.system(size: 20, weight: .regular))
            
            Text(subtitle)
                .foregroundStyle(.white)
                .font(.system(size: 30, weight: .bold))
        }
        .padding(.horizontal)
    }
}

struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .foregroundColor(.red)
            .font(.caption)
            .padding(.horizontal)
    }
}

struct ActionButton: View {
    let label: String
    let backgroundColor: Color
    let textColor: Color
    
    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundColor)
            .cornerRadius(25)
            .padding(.horizontal)
    }
}
