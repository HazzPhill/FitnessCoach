import SwiftUI

struct SecuritySettings: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var email: String = ""
    @State private var resetMessage: String?
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("Reset Password")
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            .font(themeManager.headingFont(size: 16))
                            .fontWeight(.bold)) {
                    Text("Enter your email to receive a password reset link.")
                        .font(themeManager.bodyFont(size: 14))
                        .foregroundStyle(themeManager.textColor(for: colorScheme))
                    TextField("Email", text: $email)
                        .font(themeManager.bodyFont())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .foregroundStyle(themeManager.textColor(for: colorScheme))
                    Button("Send Reset Link") {
                        Task {
                            do {
                                try await authManager.sendPasswordReset(email: email)
                                resetMessage = "Reset link sent. Check your email."
                            } catch {
                                resetMessage = "Error: \(error.localizedDescription)"
                            }
                        }
                    }
                    .font(themeManager.bodyFont())
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    if let message = resetMessage {
                        Text(message)
                            .foregroundStyle(message.contains("Error") ? .red : themeManager.accentColor(for: colorScheme))
                            .font(themeManager.captionFont())
                    }
                }
                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecuritySettings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SecuritySettings()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
        }
    }
}
