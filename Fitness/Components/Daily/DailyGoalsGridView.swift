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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Calories
                DailyGoalBox(label: "Calories", value: viewModel.dailyCalories.isEmpty ? "0" : viewModel.dailyCalories, userId: userId)
                    .environmentObject(themeManager)
                
                // Steps
                DailyGoalBox(label: "Steps", value: viewModel.dailySteps.isEmpty ? "0" : viewModel.dailySteps, userId: userId)
                    .environmentObject(themeManager)
                
                // Protein
                DailyGoalBox(label: "Protein", value: viewModel.dailyProtein.isEmpty ? "0" : viewModel.dailyProtein, userId: userId)
                    .environmentObject(themeManager)
                
                // Training
                Button(action: {
                    showTrainingPDFViewer = true
                }) {
                    HStack {
                        Text(viewModel.dailyTraining.isEmpty ? "0" : viewModel.dailyTraining)
                            .font(themeManager.titleFont()) // Using Stranded at 18px
                            .foregroundStyle(.black)
                        
                        Spacer()
                        
                        HStack {
                            
                            if hasPDF {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                            
                            Text("Training")
                                .font(themeManager.bodyFont(size: 16)) // Using Panoragraf at 12px
                                .foregroundColor(themeManager.textColor(for: colorScheme))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                    )
                    .background(themeManager.cardBackgroundColor(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 0)
        }
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
