//
//  DailyCheckinPreview.swift
//  Fitness
//
//  Created by Harry Phillips on 07/03/2025.
//

import SwiftUI

struct DailyCheckinPreview: View {
    var checkin: DailyCheckin
    
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
                        .fill(Color("Accent").opacity(0.2))
                        .frame(width: 60, height: 83)
                    
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color("Accent"))
                }
            }
            
            // Right side: Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Check-in")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Text(formattedDate(from: checkin.date))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black)
                }
                
                Text("\(completedGoalsCount)/\(totalGoalsCount) Goals Completed")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("Accent"))
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(Color("Accent"))
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
                .stroke(Color("BoxStroke"), lineWidth: 2)
        )
        .background(Color.white)
    }
}

#Preview {
    let goals = [
        CompletedGoal(goalId: "1", name: "Drink water", completed: true),
        CompletedGoal(goalId: "2", name: "Exercise", completed: true),
        CompletedGoal(goalId: "3", name: "Eat healthy", completed: false)
    ]
    
    let checkin = DailyCheckin(
        id: "1",
        userId: "user123",
        date: Date(),
        completedGoals: goals,
        notes: "Had a good day!",
        imageUrls: ["https://example.com/image.jpg"],
        timestamp: Date()
    )
    
    return DailyCheckinPreview(checkin: checkin)
}
