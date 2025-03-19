import SwiftUI

// MARK: - Helper Views
// Breaking complex views into separate structures to help type checking

// Function to get suggested Firestore rules
func getSuggestedFirestoreRules() -> String {
    return """
    rules_version = '2';
    service cloud.firestore {
      match /databases/{database}/documents {
        // Existing rules...
        
        // Client visibility settings collection rules
        match /client_settings/{clientId} {
          // Allow the client to read their own visibility settings
          allow read: if request.auth != null && 
                      (request.auth.uid == clientId || 
                      // Or if the reader is a coach of the client's group
                      (get(/databases/$(database)/documents/users/$(clientId)).data.groupId != null &&
                       get(/databases/$(database)/documents/groups/$(get(/databases/$(database)/documents/users/$(clientId)).data.groupId)).data.coachId == request.auth.uid));
                       
          // Allow coaches to create/update/delete visibility settings for their clients
          allow create, update, delete: if request.auth != null && 
                                         get(/databases/$(database)/documents/users/$(clientId)).data.groupId != null &&
                                         get(/databases/$(database)/documents/groups/$(get(/databases/$(database)/documents/users/$(clientId)).data.groupId)).data.coachId == request.auth.uid;
        }
      }
    }
    """
}

// Error message header view
struct ErrorMessageHeaderView: View {
    let errorMessage: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            
            Text(errorMessage)
                .font(themeManager.bodyFont(size: 14))
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.top, 4)
    }
}

// Instructions step view
struct InstructionStepView: View {
    let number: Int
    let text: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("\(number). \(text)")
            .font(themeManager.bodyFont(size: 14))
            .foregroundColor(themeManager.textColor(for: colorScheme))
    }
}

// Firestore rules view with copy button
struct FirestoreRulesView: View {
    let rulesText: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Copy button
            HStack {
                Spacer()
                Text("Copy Rules")
                    .font(themeManager.bodyFont(size: 12))
                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .stroke(themeManager.accentColor(for: colorScheme), lineWidth: 1)
                    )
            }
            
            // Rules text
            Text(rulesText)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(themeManager.textColor(for: colorScheme))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// Complete permissions fix guide
struct PermissionsFixGuideView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to fix this:")
                .font(themeManager.headingFont(size: 16))
                .foregroundColor(themeManager.textColor(for: colorScheme))
            
            InstructionStepView(number: 1, text: "Go to the Firebase Console")
                .environmentObject(themeManager)
            
            InstructionStepView(number: 2, text: "Select your project → Firestore Database → Rules tab")
                .environmentObject(themeManager)
            
            InstructionStepView(number: 3, text: "Add these rules (tap to copy):")
                .environmentObject(themeManager)
            
            // Rules with copy button as a button
            Button(action: {
                UIPasteboard.general.string = getSuggestedFirestoreRules()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Show a temporary "Copied" message using haptic feedback
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }) {
                FirestoreRulesView(rulesText: getSuggestedFirestoreRules())
                    .environmentObject(themeManager)
            }
            
            InstructionStepView(number: 4, text: "Click 'Publish' and try again")
                .environmentObject(themeManager)
                .padding(.top, 4)
        }
    }
}

// Complete error view
struct SettingsErrorView: View {
    let errorMessage: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Error header
            ErrorMessageHeaderView(errorMessage: errorMessage)
                .environmentObject(themeManager)
            
            // Permissions fix guide (only if needed)
            if errorMessage.contains("Permission") || errorMessage.contains("Firestore rules") {
                PermissionsFixGuideView()
                    .environmentObject(themeManager)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// Toggle for settings
struct VisibilityToggle: View {
    var title: String
    var icon: String
    var description: String
    @Binding var isOn: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        AnimatedSettingsToggle(
            title: title,
            icon: icon,
            description: description,
            isOn: $isOn
        )
        .environmentObject(themeManager)
        .padding(.horizontal)
    }
}

// Success message view
struct SuccessMessageView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Spacer()
            Text("Settings saved successfully!")
                .font(themeManager.bodyFont(size: 14))
                .foregroundColor(.green)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.1))
                )
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Main View
struct ClientSettingsView: View {
    let client: AuthManager.DBUser
    @StateObject private var viewModel: ClientSettingsViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    init(client: AuthManager.DBUser) {
        self.client = client
        _viewModel = StateObject(wrappedValue: ClientSettingsViewModel(clientId: client.userId))
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Client info header
                    clientHeaderView
                    
                    // Description
                    descriptionText
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        loadingIndicator
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        SettingsErrorView(errorMessage: errorMessage)
                            .environmentObject(themeManager)
                    }
                    
                    // Success message
                    if viewModel.showSuccessMessage {
                        SuccessMessageView()
                            .environmentObject(themeManager)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Toggle sections
                    goalsAndProgressSection
                    nutritionAndTrainingSection
                    checkinsSection
                    
                    // Save button
                    saveButton
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ModernBackButton()
                    .environmentObject(themeManager)
            }
            
            // Title
            ToolbarItem(placement: .principal) {
                Text("Client Settings")
                    .font(themeManager.headingFont(size: 18))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
            }
        }
        .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // MARK: - Extracted Subviews
    
    private var clientHeaderView: some View {
        HStack {
            if let profileImageUrl = client.profileImageUrl,
               let url = URL(string: profileImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().frame(width: 60, height: 60)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    case .failure(_):
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .foregroundColor(themeManager.accentColor(for: colorScheme))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(client.firstName) \(client.lastName)")
                    .font(themeManager.headingFont(size: 20))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                
                Text("Visibility Settings")
                    .font(themeManager.bodyFont(size: 14))
                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var descriptionText: some View {
        Text("Customize which elements are visible to this client in their app.")
            .font(themeManager.bodyFont(size: 14))
            .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.8))
            .padding(.horizontal)
    }
    
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
                .padding()
            Spacer()
        }
    }
    
    // MARK: - Settings Toggles Sections
    
    private var goalsAndProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(title: "Goals & Progress")
                .environmentObject(themeManager)
                .padding(.horizontal)
            
            // Weekly Goals toggle using extracted binding
            weeklyGoalsToggle
            
            // Progress Graph toggle using extracted binding
            progressGraphToggle
        }
    }
    
    private var weeklyGoalsToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showWeeklyGoals },
            set: { _ in viewModel.toggleSetting(\.showWeeklyGoals) }
        )
        
        return VisibilityToggle(
            title: "Weekly Goals",
            icon: "target",
            description: "Allow client to see their weekly goal targets",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    private var progressGraphToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showProgressGraph },
            set: { _ in viewModel.toggleSetting(\.showProgressGraph) }
        )
        
        return VisibilityToggle(
            title: "Progress Graph",
            icon: "chart.line.uptrend.xyaxis",
            description: "Show weight progress graph to client",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    private var nutritionAndTrainingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(title: "Nutrition & Training")
                .environmentObject(themeManager)
                .padding(.horizontal)
            
            // Meal Plans toggle using extracted binding
            mealPlansToggle
            
            // Training PDF toggle using extracted binding
            trainingPDFToggle
        }
    }
    
    private var mealPlansToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showMealPlans },
            set: { _ in viewModel.toggleSetting(\.showMealPlans) }
        )
        
        return VisibilityToggle(
            title: "Meal Plans",
            icon: "fork.knife",
            description: "Show daily meal plans to client",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    private var trainingPDFToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showTrainingPDF },
            set: { _ in viewModel.toggleSetting(\.showTrainingPDF) }
        )
        
        return VisibilityToggle(
            title: "Training PDF",
            icon: "doc.text.fill",
            description: "Allow client to access training PDF",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    private var checkinsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(title: "Check-ins")
                .environmentObject(themeManager)
                .padding(.horizontal)
            
            // Daily Check-ins toggle using extracted binding
            dailyCheckinsToggle
            
            // Weekly Check-ins toggle using extracted binding
            weeklyCheckinsToggle
        }
    }
    
    private var dailyCheckinsToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showDailyCheckins },
            set: { _ in viewModel.toggleSetting(\.showDailyCheckins) }
        )
        
        return VisibilityToggle(
            title: "Daily Check-ins",
            icon: "calendar.day.timeline.leading",
            description: "Show daily check-ins section to client",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    private var weeklyCheckinsToggle: some View {
        let isOn = Binding<Bool>(
            get: { viewModel.settings.showWeeklyCheckins },
            set: { _ in viewModel.toggleSetting(\.showWeeklyCheckins) }
        )
        
        return VisibilityToggle(
            title: "Weekly Check-ins",
            icon: "calendar.badge.clock",
            description: "Show weekly check-ins section to client",
            isOn: isOn
        )
        .environmentObject(themeManager)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.updateSettings()
            }
        } label: {
            Text("Save Settings")
                .font(themeManager.bodyFont(size: 16))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(themeManager.accentColor(for: colorScheme))
                .cornerRadius(12)
                .padding(.horizontal)
        }
        .padding(.top, 12)
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
    }
}
