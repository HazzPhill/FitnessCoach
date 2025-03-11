import SwiftUI

struct DailyCheckinPreview: View {
    var checkin: DailyCheckin
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    private var completedGoalsCount: Int {
        return checkin.completedGoals.filter { $0.completed }.count
    }
    
    private var totalGoalsCount: Int {
        return checkin.completedGoals.count
    }
    
    private var completion: Double {
        if totalGoalsCount == 0 {
            return 0.0
        }
        return Double(completedGoalsCount) / Double(totalGoalsCount)
    }
    
    // Helper function to format the date
    private func formattedDate(from date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Helper function to get the day name
    private func formattedDay(from date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name (e.g., "Monday")
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            // Left side: First image or placeholder
            if let imageUrl = checkin.imageUrls?.first, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 83)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if phase.error != nil {
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 83)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        ProgressView()
                            .frame(width: 60, height: 83)
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(themeManager.accentColor(for: colorScheme).opacity(0.2))
                        .frame(width: 60, height: 83)
                    
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(themeManager.accentColor(for: colorScheme))
                }
            }
            
            // Right side: Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formattedDay(from: checkin.date))
                        .font(themeManager.headingFont(size: 16))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                    Spacer()
                    Text(formattedDate(from: checkin.date))
                        .font(themeManager.bodyFont(size: 14))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
                
                Text("\(completedGoalsCount)/\(totalGoalsCount) Goals Completed")
                    .font(themeManager.bodyFont(size: 14))
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(themeManager.accentOrWhiteText(for: colorScheme))
                            .frame(width: geometry.size.width * CGFloat(completion), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 93)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
        )
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
