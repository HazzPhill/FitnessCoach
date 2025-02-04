import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            Color("Accent")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HeaderSection(title: "Welcome back!", subtitle: "Login")
                
                StrokedTextField(
                    text: $email,
                    label: "Email",
                    placeholder: "info@example.com",
                    strokeColor: .white,
                    textColor: .white,
                    labelColor: .white.opacity(0.9),
                    cornerRadius: 8,
                    lineWidth: 1,
                    iconName: "envelope" // Changed from "eye" to a more fitting icon for email
                )
                
                StrokedSecureField(
                    text: $password,
                    label: "Password",
                    placeholder: "••••••••",
                    strokeColor: .white,
                    textColor: .white,
                    labelColor: .white.opacity(0.9),
                    cornerRadius: 8,
                    lineWidth: 1
                )
                
                if showError {
                    ErrorMessageView(message: authManager.errorMessage ?? "Invalid credentials")
                }
                
                Button(action: loginUser) {
                    ActionButton(label: "Log in", backgroundColor: Color("White"), textColor: Color("Accent"))
                }
            }
            .padding()
        }
    }
    
    private func loginUser() {
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                showError = true
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.shared)
    }
}
