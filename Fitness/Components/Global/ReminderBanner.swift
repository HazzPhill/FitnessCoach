import SwiftUI

struct WeeklyReminderBanner: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    // Animated properties
    @State private var animateOpacity = false
    @State private var animatePulse = false
    
    var body: some View {
        Button(action: {
            // Check if we can submit a check-in or just dismiss the banner
            if authManager.canSubmitWeeklyCheckin() {
                // Open the check-in form
                print("🔔 User tapped banner - can submit check-in")
                NotificationCenter.default.post(name: .showAddUpdateForm, object: nil)
            } else {
                // Just dismiss the banner for missed check-ins
                print("🔔 User tapped banner - cannot submit (missed period)")
                authManager.dismissMissedCheckinBanner()
            }
            
            // Haptic feedback in either case
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            HStack(spacing: 12) {
                // Warning icon with animation
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(animatePulse ? 1.1 : 1.0)
                
                // Warning text - different based on status
                if authManager.canSubmitWeeklyCheckin() {
                    Text("Time for your weekly check-in! Tap to upload now")
                        .font(themeManager.bodyFont(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("You missed your weekly check-in! Tap to dismiss")
                        .font(themeManager.bodyFont(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                
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
                    .fill(authManager.canSubmitWeeklyCheckin() ? Color.orange : Color.red)
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

// Define the notification name
extension Notification.Name {
    static let showAddUpdateForm = Notification.Name("showAddUpdateForm")
}
