//
//  DailyCheckinDetailView.swift
//  Fitness
//
//  Created by Harry Phillips on 07/03/2025.
//

import SwiftUI

struct DailyCheckinDetailView: View {
    let checkin: DailyCheckin
    @State private var showingEditSheet = false
    @EnvironmentObject var authManager: AuthManager
    
    private var completedGoalsCount: Int {
        return checkin.completedGoals.filter { $0.completed }.count
    }
    
    private var totalGoalsCount: Int {
        return checkin.completedGoals.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date and progress header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(formattedDate)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color("Accent"))
                            
                            Text("\(completedGoalsCount)/\(totalGoalsCount) Goals Completed")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Photos grid (if any)
                    if let imageUrls = checkin.imageUrls, !imageUrls.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Photos")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(imageUrls, id: \.self) { urlString in
                                        if let url = URL(string: urlString) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(width: 200, height: 200)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 200, height: 200)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 200, height: 200)
                                                        .foregroundColor(.gray)
                                                        .background(Color.gray.opacity(0.2))
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Goals section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Goals")
                            .font(.headline)
                            .foregroundColor(Color("SecondaryAccent"))
                        
                        ForEach(checkin.completedGoals) { goal in
                            HStack {
                                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(goal.completed ? .green : .gray)
                                Text(goal.name)
                                    .foregroundColor(goal.completed ? .black : .gray)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
                    // Notes section (if any)
                    if let notes = checkin.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                            Text(notes)
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .frame(minHeight: geometry.size.height)
            }
            .background(Color("Background"))
            .navigationTitle("Check-in Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let userId = authManager.currentUser?.userId {
                    EditDailyCheckinView(checkin: checkin, userId: userId)
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    var formattedDate: String {
        guard let date = checkin.date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
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
        notes: "Had a good day! I managed to stay hydrated and got a good workout in. Still working on my nutrition though.",
        imageUrls: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
        timestamp: Date()
    )
    
    return NavigationStack {
        DailyCheckinDetailView(checkin: checkin)
            .environmentObject(AuthManager.shared)
    }
}
