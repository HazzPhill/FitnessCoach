import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var role: UserRole = .client
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    
    // Animation states
    @State private var animateButton = false
    @State private var formAppeared = false
    
    var body: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Custom header with app fonts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello")
                            .font(themeManager.bodyFont(size: 20))
                            .opacity(formAppeared ? 1 : 0)
                            .offset(y: formAppeared ? 0 : 20)
                        
                        Text("Register")
                            .font(themeManager.headingFont(size: 30))
                            .opacity(formAppeared ? 1 : 0)
                            .offset(y: formAppeared ? 0 : 20)
                    }
                    .padding(.bottom, 16)
                    
                    GlassTextField(
                        text: $firstName,
                        label: "First Name",
                        placeholder: "John",
                        cornerRadius: 8,
                        iconName: "person"
                    )
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 15)
                    
                    GlassTextField(
                        text: $lastName,
                        label: "Last Name",
                        placeholder: "Doe",
                        cornerRadius: 8,
                        iconName: "person"
                    )
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 15)
                    
                    GlassTextField(
                        text: $email,
                        label: "Email",
                        placeholder: "info@example.com",
                        cornerRadius: 8,
                        iconName: "envelope"
                    )
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 15)
                    
                    // Modern role selector
                    ModernRoleSelector(selectedRole: $role)
                        .padding(.vertical, 8)
                        .opacity(formAppeared ? 1 : 0)
                        .offset(y: formAppeared ? 0 : 15)
                    
                    GlassSecureField(
                        text: $password,
                        label: "Password",
                        placeholder: "••••••••",
                        cornerRadius: 8
                    )
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 15)
                    
                    GlassSecureField(
                        text: $confirmPassword,
                        label: "Confirm Password",
                        placeholder: "••••••••",
                        cornerRadius: 8
                    )
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 15)
                    
                    // Password requirements hint
                    Text("Password must be at least 6 characters long")
                        .font(themeManager.captionFont())
                        .opacity(0.7)
                        .padding(.top, 4)
                        .opacity(formAppeared ? 1 : 0)
                    
                    if showError {
                        Text(authManager.errorMessage ?? "Registration failed")
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
                        registerUser()
                    }) {
                        ZStack {
                            // Button background
                            RoundedRectangle(cornerRadius: 25)
                                .frame(height: 50)
                                .glassEffect(.regular.interactive().tint(themeManager.accentColor(for: colorScheme)))
                            
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(themeManager.accentColor(for: colorScheme))
                                    .scaleEffect(1.2)
                            } else {
                                Text("Register")
                                    .font(themeManager.bodyFont(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .disabled(authManager.isLoading)
                    .opacity(formAppeared ? 1 : 0)
                    .offset(y: formAppeared ? 0 : 20)
                    
                    // Privacy policy note
                    Text("By registering, you agree to our Terms of Service and Privacy Policy")
                        .font(themeManager.captionFont())
                        .opacity(0.7)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity)
                        .opacity(formAppeared ? 1 : 0)
                }
                .padding()
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30))
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
    
    private func registerUser() {
        guard password == confirmPassword else {
            authManager.errorMessage = "Passwords do not match"
            showError = true
            
            // Provide error haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty else {
            authManager.errorMessage = "Please fill in all fields"
            showError = true
            
            // Provide error haptic feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        Task {
            do {
                try await authManager.signUp(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    role: role,
                    password: password
                )
                
                // Success feedback if we get here
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            } catch {
                showError = true
                authManager.errorMessage = error.localizedDescription
                
                // Provide error haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegisterView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
            
            RegisterView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
        }
    }
}
