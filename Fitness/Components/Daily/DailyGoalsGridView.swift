// First, update the DailyGoalsGridView in ClientHome.swift
// This is the part where clients would see and click on the Training box

import SwiftUI

struct DailyGoalsGridView: View {
    @StateObject private var viewModel: DailyGoalsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    let userId: String
    
    // Add state for showing Training PDF viewer
    @State private var showTrainingPDFViewer = false
    @State private var hasPDF = false
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: DailyGoalsViewModel(userId: userId))
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // Calories, Steps, and Protein are regular goal boxes
                DailyGoalBox(label: "Calories", value: viewModel.dailyCalories.isEmpty ? "0" : viewModel.dailyCalories, userId: userId)
                    .environmentObject(themeManager)
                DailyGoalBox(label: "Steps", value: viewModel.dailySteps.isEmpty ? "0" : viewModel.dailySteps, userId: userId)
                    .environmentObject(themeManager)
                DailyGoalBox(label: "Protein", value: viewModel.dailyProtein.isEmpty ? "0" : viewModel.dailyProtein, userId: userId)
                    .environmentObject(themeManager)
                
                // Special handling for Training goal
                Button(action: {
                    showTrainingPDFViewer = true
                }) {
                    VStack(alignment: .leading) {
                        Text(viewModel.dailyTraining.isEmpty ? "0" : viewModel.dailyTraining)
                            .font(themeManager.titleFont())
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        
                        HStack {
                            Text("Training")
                                .font(themeManager.captionFont())
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
                            
                            // Show PDF icon if available
                            if hasPDF {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 75, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                    )
                    .background(themeManager.cardBackgroundColor(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 0)
            .background(themeManager.backgroundColor(for: colorScheme))
        }
        .edgesIgnoringSafeArea(.horizontal)
        .background(themeManager.backgroundColor(for: colorScheme))
        .sheet(isPresented: $showTrainingPDFViewer) {
            TrainingPDFViewerScreen(clientId: userId, isCoachView: false)
                .environmentObject(themeManager)
        }
        .onAppear {
            // Check if there's a training PDF available
            TrainingPDFManager.shared.checkTrainingExists(clientId: userId) { exists in
                DispatchQueue.main.async {
                    self.hasPDF = exists
                }
            }
        }
    }
}

#Preview {
    DailyGoalsGridView(userId: "dummyUserId")
        .environmentObject(ThemeManager())
}
