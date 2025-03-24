//
//  ReminderBanner.swift
//  Coach by Wardy
//
//  Created by Harry Phillips on 24/03/2025.
//

import SwiftUI

struct WeeklyReminderBanner: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    var action: () -> Void
    
    // Animated properties
    @State private var animateOpacity = false
    @State private var animatePulse = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Warning icon with animation
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                
                // Warning text
                Text("You forgot to do your weekly check-in! Tap to upload now")
                    .font(themeManager.bodyFont(size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal)
            .opacity(animateOpacity ? 1.0 : 0.9)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            // Start animations when banner appears
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animateOpacity = true
            }
            
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// Add a custom button style for a nice press effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
