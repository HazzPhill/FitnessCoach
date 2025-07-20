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
    
    private var backgroundView: some View {
        if let imageUrl = checkin.imageUrls?.first, let url = URL(string: imageUrl) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Image("gym_background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                    }
                }
            )
        } else {
            return AnyView(
                Image("gym_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            )
        }
    }
    
    var body: some View {
        ZStack {
            backgroundView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(formattedDay(from: checkin.date))
                        .font(themeManager.headingFont(size: 20))
                    Spacer()
                }
                
                Text("\(completedGoalsCount)/\(totalGoalsCount) Goals Completed")
                    .font(themeManager.bodyFont(size: 12))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(themeManager.accentOrWhiteText(for: colorScheme))
                            .frame(width: geometry.size.width * CGFloat(completion), height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                
                HStack {
                    Spacer()
                    Text(formattedDate(from: checkin.date))
                        .font(themeManager.bodyFont(size: 12))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: 93)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}


#Preview {
    let sampleGoals = [
        CompletedGoal(goalId: "1", name: "Calories", completed: true),
        CompletedGoal(goalId: "2", name: "Steps", completed: false),
        CompletedGoal(goalId: "3", name: "Protein", completed: true)
    ]
    let sampleCheckin = DailyCheckin(
        id: "1",
        userId: "user123",
        date: Date(),
        completedGoals: sampleGoals,
        notes: "Sample notes",
        imageUrls: nil,
        timestamp: Date()
    )
    return DailyCheckinPreview(checkin: sampleCheckin)
        .environmentObject(ThemeManager())
        .padding()
        .background(Color(hex: "F9F8F4"))
}
