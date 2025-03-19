import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import Combine

// Model to store which elements are visible for a specific client
struct ClientVisibilitySettings: Codable, Identifiable {
    @DocumentID var id: String?
    let clientId: String
    var showWeeklyGoals: Bool = true
    var showProgressGraph: Bool = true
    var showMealPlans: Bool = true
    var showTrainingPDF: Bool = true
    var showDailyCheckins: Bool = true
    var showWeeklyCheckins: Bool = true
    @ServerTimestamp var updatedAt: Date?
    
    // Default settings constructor
    static func defaultSettings(for clientId: String) -> ClientVisibilitySettings {
        return ClientVisibilitySettings(
            clientId: clientId,
            showWeeklyGoals: true,
            showProgressGraph: true,
            showMealPlans: true,
            showTrainingPDF: true,
            showDailyCheckins: true,
            showWeeklyCheckins: true
        )
    }
}

// View model to handle fetching and updating client visibility settings
class ClientSettingsViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var settings: ClientVisibilitySettings
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessMessage = false
    
    private var clientId: String
    
    init(clientId: String) {
        self.clientId = clientId
        self.settings = ClientVisibilitySettings.defaultSettings(for: clientId)
        fetchSettings()
    }
    
    func fetchSettings() {
        isLoading = true
        errorMessage = nil
        
        db.collection("client_settings")
            .document(clientId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    // Check for permission errors specifically
                    if error.localizedDescription.contains("permission") ||
                       error.localizedDescription.contains("access") ||
                       error.localizedDescription.contains("unauthorized") {
                        print("⚠️ Firebase permission error: \(error.localizedDescription)")
                        self.errorMessage = "Permission error: You need to update Firestore rules"
                    } else {
                        self.errorMessage = "Failed to load settings: \(error.localizedDescription)"
                    }
                    
                    // Use default settings even when there's an error
                    DispatchQueue.main.async {
                        self.settings = ClientVisibilitySettings.defaultSettings(for: self.clientId)
                    }
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    do {
                        let settings = try snapshot.data(as: ClientVisibilitySettings.self)
                        DispatchQueue.main.async {
                            self.settings = settings
                        }
                    } catch {
                        print("⚠️ Settings parse error: \(error.localizedDescription)")
                        self.errorMessage = "Failed to parse settings: \(error.localizedDescription)"
                        // If we can't parse the settings, use default settings
                        DispatchQueue.main.async {
                            self.settings = ClientVisibilitySettings.defaultSettings(for: self.clientId)
                        }
                    }
                } else {
                    // If no settings document exists, use default settings
                    print("ℹ️ No settings document exists for client \(self.clientId), using defaults")
                    DispatchQueue.main.async {
                        self.settings = ClientVisibilitySettings.defaultSettings(for: self.clientId)
                    }
                }
            }
    }
    
    func updateSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create or update the settings document
            try db.collection("client_settings").document(clientId).setData(from: settings)
            
            await MainActor.run {
                isLoading = false
                showSuccessMessage = true
                
                // Hide success message after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.showSuccessMessage = false
                }
            }
        } catch {
            print("❌ Failed to save settings: \(error.localizedDescription)")
            
            await MainActor.run {
                isLoading = false
                
                // Check for specific permission errors
                if error.localizedDescription.contains("permission") ||
                   error.localizedDescription.contains("access") ||
                   error.localizedDescription.contains("unauthorized") {
                    errorMessage = "Permission denied: Update Firestore rules to allow access to 'client_settings' collection"
                } else {
                    errorMessage = "Failed to save settings: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Toggle individual settings
    func toggleSetting(_ keyPath: WritableKeyPath<ClientVisibilitySettings, Bool>) {
        var newSettings = settings
        newSettings[keyPath: keyPath].toggle()
        settings = newSettings
    }
}


struct AnimatedSettingsToggle: View {
    // Configuration
    var title: String
    var icon: String
    var description: String
    @Binding var isOn: Bool
    
    // Theme access
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Animation states
    @State private var toggleScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    @State private var iconOpacity: Double = 0.7
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    isOn.toggle()
                    
                    // Apply toggle animation
                    toggleScale = 1.2
                    iconRotation = isOn ? 360 : 0
                    iconOpacity = isOn ? 1.0 : 0.7
                    
                    // Reset scale after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            toggleScale = 1.0
                        }
                    }
                }
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }) {
                HStack(alignment: .center, spacing: 16) {
                    // Icon with animation
                    ZStack {
                        Circle()
                            .fill(isOn
                                  ? themeManager.accentColor(for: colorScheme)
                                  : themeManager.accentColor(for: colorScheme).opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isOn ? .white : themeManager.accentColor(for: colorScheme))
                            .rotationEffect(.degrees(iconRotation))
                            .opacity(iconOpacity)
                    }
                    .scaleEffect(toggleScale)
                    
                    // Title and description
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(themeManager.bodyFont(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        
                        Text(description)
                            .font(themeManager.captionFont(size: 12))
                            .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Custom toggle
                    ZStack {
                        // Track
                        Capsule()
                            .fill(isOn ? themeManager.accentColor(for: colorScheme) : Color.gray.opacity(0.3))
                            .frame(width: 50, height: 30)
                        
                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            .frame(width: 24, height: 24)
                            .offset(x: isOn ? 10 : -10)
                    }
                    .scaleEffect(toggleScale)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
        )
    }
}

struct SettingsSectionHeader: View {
    var title: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(themeManager.headingFont(size: 18))
                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            Spacer()
        }
    }
}
