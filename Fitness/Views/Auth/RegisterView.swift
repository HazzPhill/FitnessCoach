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
    @State private var currentAnimationSection = 0
    
    var body: some View {
        ZStack {
            themeManager.accentColor(for: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading) {
                    // Custom header with app fonts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello")
                            .font(themeManager.bodyFont(size: 20))
                            .foregroundStyle(.white)
                            .opacity(formAppeared && currentAnimationSection >= 0 ? 1 : 0)
                            .offset(y: formAppeared && currentAnimationSection >= 0 ? 0 : 20)
                        
                        Text("Register")
                            .font(themeManager.headingFont(size: 30))
                            .foregroundStyle(.white)
                            .opacity(formAppeared && currentAnimationSection >= 0 ? 1 : 0)
                            .offset(y: formAppeared && currentAnimationSection >= 0 ? 0 : 20)
                    }
                    .padding(.bottom, 20)
                    
                    // Personal information section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PERSONAL INFORMATION")
                            .font(themeManager.captionFont())
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.5)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 4)
                            .opacity(formAppeared && currentAnimationSection >= 1 ? 1 : 0)
                        
                        StrokedTextField(
                            text: $firstName,
                            label: "First Name",
                            placeholder: "John",
                            strokeColor: .white,
                            textColor: .white,
                            labelColor: .white.opacity(0.9),
                            cornerRadius: 8,
                            lineWidth: 1,
                            iconName: "person"
                        )
                        .opacity(formAppeared && currentAnimationSection >= 1 ? 1 : 0)
                        .offset(y: formAppeared && currentAnimationSection >= 1 ? 0 : 15)
                        
                        StrokedTextField(
                            text: $lastName,
                            label: "Last Name",
                            placeholder: "Doe",
                            strokeColor: .white,
                            textColor: .white,
                            labelColor: .white.opacity(0.9),
                            cornerRadius: 8,
                            lineWidth: 1,
                            iconName: "person"
                        )
                        .opacity(formAppeared && currentAnimationSection >= 1 ? 1 : 0)
                        .offset(y: formAppeared && currentAnimationSection >= 1 ? 0 : 15)
                    }
                    .padding(.bottom, 20)
                    
                    // Login information section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ACCOUNT INFORMATION")
                            .font(themeManager.captionFont())
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.5)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 4)
                            .opacity(formAppeared && currentAnimationSection >= 2 ? 1 : 0)
                        
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
                        .opacity(formAppeared && currentAnimationSection >= 2 ? 1 : 0)
                        .offset(y: formAppeared && currentAnimationSection >= 2 ? 0 : 15)
                        
                        // Modern role selector
                        ModernRoleSelector(selectedRole: $role)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .opacity(formAppeared && currentAnimationSection >= 2 ? 1 : 0)
                            .offset(y: formAppeared && currentAnimationSection >= 2 ? 0 : 15)
                        
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
                        .opacity(formAppeared && currentAnimationSection >= 3 ? 1 : 0)
                        .offset(y: formAppeared && currentAnimationSection >= 3 ? 0 : 15)
                        
                        StrokedSecureField(
                            text: $confirmPassword,
                            label: "Confirm Password",
                            placeholder: "••••••••",
                            strokeColor: .white,
                            textColor: .white,
                            labelColor: .white.opacity(0.9),
                            cornerRadius: 8,
                            lineWidth: 1
                        )
                        .opacity(formAppeared && currentAnimationSection >= 3 ? 1 : 0)
                        .offset(y: formAppeared && currentAnimationSection >= 3 ? 0 : 15)
                    }
                    
                    // Password requirements hint
                    Text("Password must be at least 6 characters long")
                        .font(themeManager.captionFont())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        .opacity(formAppeared && currentAnimationSection >= 3 ? 1 : 0)
                    
                    if showError {
                        Text(authManager.errorMessage ?? "Registration failed")
                            .font(themeManager.bodyFont(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(8)
                            .padding(.top, 12)
                            .padding(.horizontal, 8)
                    }
                    
                    // Register button
                    Button(action: {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        registerUser()
                    }) {
                        ZStack {
                            // Button background
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                                .frame(height: 50)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .scaleEffect(animateButton ? 1.02 : 1)
                            
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(themeManager.accentColor(for: colorScheme))
                                    .scaleEffect(1.2)
                            } else {
                                Text("Register")
                                    .font(themeManager.bodyFont(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 20)
                    .disabled(authManager.isLoading)
                    .opacity(formAppeared && currentAnimationSection >= 4 ? 1 : 0)
                    .offset(y: formAppeared && currentAnimationSection >= 4 ? 0 : 20)
                    
                    // Privacy policy note
                    Text("By registering, you agree to our Terms of Service and Privacy Policy")
                        .font(themeManager.captionFont())
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity)
                        .opacity(formAppeared && currentAnimationSection >= 4 ? 1 : 0)
                }
                .padding()
            }
        }
        .onAppear {
            // Staggered animation for form sections
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    formAppeared = true
                    currentAnimationSection = 0
                }
                
                // Animate personal info section
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        currentAnimationSection = 1
                    }
                    
                    // Animate account info section
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            currentAnimationSection = 2
                        }
                        
                        // Animate password section
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                currentAnimationSection = 3
                            }
                            
                            // Animate button and footer
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    currentAnimationSection = 4
                                }
                                
                                // Start button animation
                                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                    animateButton = true
                                }
                            }
                        }
                    }
                }
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
