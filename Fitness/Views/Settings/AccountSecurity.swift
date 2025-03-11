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
                            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            .fontWeight(.bold)) {
                    Text("Enter your email to receive a password reset link.")
                        .font(.subheadline)
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .foregroundColor(themeManager.textColor(for: colorScheme))
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
                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    if let message = resetMessage {
                        Text(message)
                            .foregroundColor(message.contains("Error") ? .red : themeManager.accentColor(for: colorScheme))
                            .font(.footnote)
                    }
                }
                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Security")
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
