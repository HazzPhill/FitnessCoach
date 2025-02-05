import SwiftUI

struct SecuritySettings: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var resetMessage: String?
    
    var body: some View {
        Form {
            Section(header: Text("Reset Password")
                        .foregroundColor(Color("Accent"))
                        .fontWeight(.bold)) {
                Text("Enter your email to receive a password reset link.")
                    .font(.subheadline)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
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
                if let message = resetMessage {
                    Text(message)
                        .foregroundColor(.blue)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Security")
    }
}

struct SecuritySettings_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettings()
            .environmentObject(AuthManager.shared)
    }
}
