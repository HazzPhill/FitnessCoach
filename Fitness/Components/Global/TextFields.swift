//
//  TextFields.swift
//  Coach by Wardy
//
//  Created by Harry Phillips on 19/07/2025.
//

import SwiftUI

struct GlassTextField: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let placeholder: String
    let cornerRadius: CGFloat
    let iconName: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(themeManager.captionFont())
               
            
            HStack {
                TextField("", text: $text)
                    .font(themeManager.bodyFont())
                    .foregroundColor(.black)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .font(themeManager.bodyFont())
                           
                    }
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                if let iconName = iconName {
                    Image(systemName: iconName)
                
                }
            }
            .padding()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
        .padding(.vertical, 4)
    }
}

struct GlassSecureField: View {
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    
    let label: String
    let placeholder: String
    let cornerRadius: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(themeManager.captionFont())
            
            SecureField("", text: $text)
                .font(themeManager.bodyFont())
                .foregroundColor(.black)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .font(themeManager.bodyFont())
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GlassTextField(
        text: .constant(""),
        label: "Label",
        placeholder: "Enter text",
        cornerRadius: 12,
        iconName: "pencil"
    )
    .environmentObject(ThemeManager())
}
