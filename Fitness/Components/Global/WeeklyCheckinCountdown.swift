import SwiftUI

struct WeeklyCheckinCountdown: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Timer to update the countdown
    @State private var timeRemaining: String = ""
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        // Only show countdown if user has already checked in this week
        if hasCompletedCheckIn() {
            Text(timeRemaining)
                .font(themeManager.captionFont(size: 10))
                .foregroundColor(themeManager.accentColor(for: colorScheme))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(themeManager.accentColor(for: colorScheme).opacity(0.1))
                )
                .onAppear(perform: updateTimeRemaining)
                .onReceive(timer) { _ in
                    updateTimeRemaining()
                }
        }
    }
    
    // Check if user has already completed check-in this week
    private func hasCompletedCheckIn() -> Bool {
        return authManager.hasCompletedWeeklyCheckinThisWeek()
    }
    
    // Calculate and format time until next check-in
    private func updateTimeRemaining() {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        // Calculate days until next Saturday
        var daysUntilSaturday = 7 - weekday
        if daysUntilSaturday == 0 { daysUntilSaturday = 7 } // If today is Saturday, count to next Saturday
        
        // If we're on Sunday, set days until Saturday to 6
        if weekday == 1 {
            daysUntilSaturday = 6
        }
        
        // Calculate hours remaining until midnight
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let hoursRemaining = calendar.dateComponents([.hour], from: now, to: endOfDay).hour ?? 0
        
        // Format the countdown text
        if daysUntilSaturday > 1 {
            timeRemaining = "\(daysUntilSaturday)d"
        } else if daysUntilSaturday == 1 {
            timeRemaining = "\(hoursRemaining + 1)h"
        } else {
            // We're on Saturday, check hours
            if weekday == 7 {
                // If it's Saturday, count hours until end of day
                timeRemaining = "\(hoursRemaining)h"
            } else {
                // For any other day
                timeRemaining = "\(daysUntilSaturday)d"
            }
        }
    }
}
