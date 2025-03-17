import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var resetMessage: String = ""
    @State private var isResettingPassword: Bool = false
    
    var body: some View {
        ZStack {
            Color("Accent")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Custom header with app fonts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(themeManager.bodyFont(size: 20))
                        .foregroundStyle(.white)
                    
                    Text("Login")
                        .font(themeManager.headingFont(size: 30))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 16)
                
                StrokedTextField(
                    text: $email,
                    label: "Email",
                    placeholder: "info@example.com",
                    strokeColor: .white,
                    textColor: .white,
                    labelColor: .white.opacity(0.9),
                    cornerRadius: 8,
                    lineWidth: 1,
                    iconName: "envelope"
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
                
                // Forgot Password Button
                HStack {
                    Spacer()
                    Button(action: forgotPassword) {
                        Text("Forgot Password?")
                            .font(themeManager.bodyFont(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.trailing, 8)
                    }
                    .disabled(isResettingPassword)
                }
                .padding(.top, -8)
                
                if showError {
                    Text(authManager.errorMessage ?? "Invalid credentials")
                        .font(themeManager.bodyFont(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Button(action: loginUser) {
                    if authManager.isLoading || isResettingPassword {
                        ProgressView()
                            .tint(Color("Accent"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                    } else {
                        Text("Log in")
                            .font(themeManager.bodyFont(size: 16))
                            .foregroundColor(Color("Accent"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(25)
                    }
                }
                .padding(.top, 8)
                .disabled(authManager.isLoading || isResettingPassword)
            }
            .padding()
            .alert("Password Reset", isPresented: $showResetAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetMessage)
                    .font(themeManager.bodyFont())
            }
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
    
    private func forgotPassword() {
        guard !email.isEmpty else {
            resetMessage = "Please enter your email address first."
            showResetAlert = true
            return
        }
        
        isResettingPassword = true
        
        Task {
            do {
                try await authManager.sendPasswordReset(email: email)
                await MainActor.run {
                    resetMessage = "If this email exists in our system, a password reset link has been sent. Please check your inbox."
                    showResetAlert = true
                    isResettingPassword = false
                }
            } catch {
                await MainActor.run {
                    resetMessage = "Error sending password reset: \(error.localizedDescription)"
                    showResetAlert = true
                    isResettingPassword = false
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
