import SwiftUI

struct DailyGoalBox: View {
    var label: String
    var value: String
    var userId: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Add state variables for PDF functionality
    @State private var showTrainingPDFViewer = false
    @State private var showTrainingPDFUploader = false
    @State private var hasPDF: Bool = false
    
    // Determine if we're in coach view
    @State private var isCoach: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Special handling for the Training label
            if label == "Training" {
                Button(action: {
                    // If in coach view, show uploader; otherwise show viewer
                    if isCoach {
                        showTrainingPDFUploader = true
                    } else {
                        showTrainingPDFViewer = true
                    }
                }) {
                    VStack(alignment: .leading){
                        Text(value)
                            .font(themeManager.titleFont()) // Using Stranded at 18px
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        HStack {
                            Text(label)
                                .font(themeManager.captionFont()) // Using Panoragraf at 12px
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
                            
                            // Show a small PDF icon if there's a PDF
                            if hasPDF {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth:.infinity, minHeight: 75, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                    )
                    .background(themeManager.cardBackgroundColor(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .sheet(isPresented: $showTrainingPDFViewer) {
                    TrainingPDFViewerScreen(clientId: userId, isCoachView: false)
                        .environmentObject(themeManager)
                }
                .sheet(isPresented: $showTrainingPDFUploader) {
                    TrainingPDFViewerScreen(clientId: userId, isCoachView: true)
                        .environmentObject(themeManager)
                }
            } else {
                // Original behavior for other goals (Calories, Steps, Protein)
                NavigationLink {
                   DailyGoalsView(userId: userId)
                } label: {
                    VStack(alignment: .leading){
                        Text(value)
                            .font(themeManager.titleFont()) // Using Stranded at 18px
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        Text(label)
                            .font(themeManager.captionFont()) // Using Panoragraf at 12px
                            .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
                    }
                    .padding()
                    .frame(maxWidth:.infinity, minHeight: 75, alignment: .leading)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                    )
                    .background(themeManager.cardBackgroundColor(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .onAppear {
            // Check if the current user is a coach (role comparison)
            if let currentUser = AuthManager.shared.currentUser {
                isCoach = currentUser.role == .coach
            }
            
            // Check if there's a PDF available (only for Training)
            if label == "Training" {
                TrainingPDFManager.shared.checkTrainingExists(clientId: userId) { exists in
                    DispatchQueue.main.async {
                        self.hasPDF = exists
                    }
                }
            }
        }
    }
}

#Preview {
    DailyGoalBox(label: "Calories", value: "2000", userId: "12345")
        .environmentObject(ThemeManager())
}
