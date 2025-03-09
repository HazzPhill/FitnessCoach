//
//  DailyCheckinDetailView.swift
//  Fitness
//
//  Created by Harry Phillips on 07/03/2025.
//

import SwiftUI
import CachedAsyncImage

struct DailyCheckinDetailView: View {
    let checkin: DailyCheckin
    @State private var showingEditSheet = false
    @State private var currentImageIndex = 0
    @State private var imageTimer: Timer? = nil
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    // Check if current user is the owner of this check-in
    private var isOwner: Bool {
        return authManager.currentUser?.userId == checkin.userId
    }
    
    private var completedGoalsCount: Int {
        return checkin.completedGoals.filter { $0.completed }.count
    }
    
    private var totalGoalsCount: Int {
        return checkin.completedGoals.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Image carousel
                ZStack(alignment: .bottom) {
                    if let imageUrls = checkin.imageUrls, !imageUrls.isEmpty {
                        if let url = URL(string: imageUrls[currentImageIndex]) {
                            CachedAsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 220)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipped()
                                case .failure(_):
                                    Image("gym_background")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 220)
                                        .clipped()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    } else {
                        // Fallback image if no images available
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                    }
                    
                    // Navigation controls removed
                    
                    // Subtle gradient fade at bottom
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.4),
                            .clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 80)
                }
                .ignoresSafeArea(edges: .top)
                
                // Title & Date with conditional edit button
                HStack {
                    Text(formattedDay(from: checkin.date))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("SecondaryAccent"))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if let date = checkin.date {
                            Text(date.formattedWithOrdinal())
                                .font(.footnote)
                                .foregroundColor(Color("SecondaryAccent"))
                        }
                        
                        // Edit button only shown if user owns this check-in
                        if isOwner {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(Color("Accent"))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Goal completion status
                HStack(spacing: 16) {
                    InfoBoxView(
                        title: "Goals Completed",
                        value: "\(completedGoalsCount)/\(totalGoalsCount)",
                        valueColor: Color("Accent")
                    )
                    InfoBoxView(
                        title: "Completion Rate",
                        value: String(format: "%.0f%%", Double(completedGoalsCount) / Double(totalGoalsCount) * 100),
                        valueColor: completedGoalsCount == totalGoalsCount ? Color("Accent") : Color("SecondaryAccent")
                    )
                }
                .padding(.horizontal)
                
                // Goals section styled as the scores box
                VStack(spacing: 12) {
                    HStack {
                        Text("Goals")
                            .font(.headline)
                            .foregroundColor(Color("SecondaryAccent"))
                        Spacer()
                    }
                    
                    // List of goals
                    ForEach(checkin.completedGoals) { goal in
                        HStack {
                            Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(goal.completed ? Color("Accent") : .gray)
                            Text(goal.name)
                                .foregroundColor(goal.completed ? .primary : .gray)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("BoxStroke"), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Notes section (if any) - styled as reflection box
                if let notes = checkin.notes, !notes.isEmpty {
                    ReflectionBoxView(
                        title: "Notes",
                        text: notes
                    )
                    .padding(.horizontal)
                }
                
                // Photos grid (thumbnails)
                if let imageUrls = checkin.imageUrls, imageUrls.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos")
                            .font(.headline)
                            .foregroundColor(Color("SecondaryAccent"))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<imageUrls.count, id: \.self) { index in
                                    let urlString = imageUrls[index]
                                    if let url = URL(string: urlString) {
                                        CachedAsyncImage(url: url) { phase in
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
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color("BoxStroke"), lineWidth: 1)
                                                    )
                                                    .onTapGesture {
                                                        withAnimation {
                                                            currentImageIndex = index
                                                        }
                                                        stopImageTimer()
                                                        startImageTimer()
                                                    }
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 200, height: 200)
                                                    .foregroundColor(.gray)
                                                    .background(Color.gray.opacity(0.2))
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color("BoxStroke"), lineWidth: 1)
                                                    )
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
                    .padding(.top, 8)
                }
            }
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color("Background").ignoresSafeArea())
        .sheet(isPresented: $showingEditSheet) {
            if let userId = authManager.currentUser?.userId {
                EditDailyCheckinView(checkin: checkin, userId: userId)
                    .environmentObject(authManager)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startImageTimer()
        }
        .onDisappear {
            stopImageTimer()
        }
    }
    
    // Timer methods - properly placed inside the struct
    private func startImageTimer() {
        // Only start timer if there are multiple images
        guard let imageUrls = checkin.imageUrls, imageUrls.count > 1 else { return }
        
        // Stop any existing timer first
        stopImageTimer()
        
        // Create a new timer that fires every few seconds
        imageTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            // Update the image index with animation
            withAnimation {
                self.currentImageIndex = (self.currentImageIndex + 1) % imageUrls.count
            }
        }
    }
    
    private func stopImageTimer() {
        imageTimer?.invalidate()
        imageTimer = nil
    }
    
    // Helper function to get the day name
    private func formattedDay(from date: Date?) -> String {
        guard let date = date else { return "No date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name (e.g., "Monday")
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
