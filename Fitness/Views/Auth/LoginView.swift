import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var resetMessage: String = ""
    @State private var isResettingPassword: Bool = false
    
    // Animation states
    @State private var animateButton = false
    @State private var formAppeared = false
    
    var body: some View {
        ZStack {
            themeManager.accentColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Custom header with app fonts
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back!")
                        .font(themeManager.bodyFont(size: 20))
                        .foregroundStyle(.white)
                        .opacity(formAppeared ? 1 : 0)
                        .offset(y: formAppeared ? 0 : 20)
                    
                    Text("Login")
                        .font(themeManager.headingFont(size: 30))
                        .foregroundStyle(.white)
                        .opacity(formAppeared ? 1 : 0)
                        .offset(y: formAppeared ? 0 : 20)
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
                .opacity(formAppeared ? 1 : 0)
                .offset(y: formAppeared ? 0 : 15)
                
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
                .opacity(formAppeared ? 1 : 0)
                .offset(y: formAppeared ? 0 : 15)
                
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
                .opacity(formAppeared ? 1 : 0)
                
                if showError {
                    Text(authManager.errorMessage ?? "Invalid credentials")
                        .font(themeManager.bodyFont(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    loginUser()
                }) {
                    ZStack {
                        // Button background
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .frame(height: 50)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .scaleEffect(animateButton ? 1.02 : 1)
                        
                        if authManager.isLoading || isResettingPassword {
                            ProgressView()
                                .tint(themeManager.accentColor(for: colorScheme))
                                .scaleEffect(1.2)
                        } else {
                            Text("Log in")
                                .font(themeManager.bodyFont(size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.accentColor(for: colorScheme))
                        }
                    }
                }
                .padding(.top, 8)
                .disabled(authManager.isLoading || isResettingPassword)
                .opacity(formAppeared ? 1 : 0)
                .offset(y: formAppeared ? 0 : 20)
            }
            .padding()
            .alert("Password Reset", isPresented: $showResetAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resetMessage)
                    .font(themeManager.bodyFont())
            }
        }
        .onAppear {
            // Animate form elements
            withAnimation(.easeOut(duration: 0.6)) {
                formAppeared = true
            }
            
            // Subtle pulsing animation for the button
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateButton = true
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
                    
                    // Provide success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    resetMessage = "Error sending password reset: \(error.localizedDescription)"
                    showResetAlert = true
                    isResettingPassword = false
                    
                    // Provide error haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
            
            LoginView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
        }
    }
}
