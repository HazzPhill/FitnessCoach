// StrokedTextField.swift
import SwiftUI

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
    let iconName: String? // optional icon
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(labelColor)
            
            // Text Field with optional icon
            HStack {
                TextField(placeholder, text: $text)
                    .foregroundColor(textColor)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .foregroundColor(textColor)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )
        }
        .padding()
    }
}

// StrokedSecureField.swift
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
            Text(label)
                .font(.caption)
                .foregroundColor(labelColor)
            
            SecureField(placeholder, text: $text)
                .foregroundColor(textColor)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(strokeColor, lineWidth: lineWidth)
                )
        }
        .padding(.vertical, 4)
    }
}

// UI Components
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
