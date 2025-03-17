import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var role: UserRole = .client
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            Color("Accent")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading) {
                    // Custom header with app fonts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello")
                            .font(themeManager.bodyFont(size: 20))
                            .foregroundStyle(.white)
                        
                        Text("Register")
                            .font(themeManager.headingFont(size: 30))
                            .foregroundStyle(.white)
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
                        
                        // Modern role selector
                        ModernRoleSelector(selectedRole: $role)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                        
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
                    }
                    
                    // Password requirements hint
                    Text("Password must be at least 6 characters long")
                        .font(themeManager.captionFont())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    
                    if showError {
                        Text(authManager.errorMessage ?? "Registration failed")
                            .font(themeManager.bodyFont(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.top, 12)
                    }
                    
                    // Register button
                    Button(action: registerUser) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(Color("Accent"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        } else {
                            Text("Register")
                                .font(themeManager.bodyFont(size: 16))
                                .foregroundColor(Color("Accent"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 20)
                    .disabled(authManager.isLoading)
                    
                    // Privacy policy note
                    Text("By registering, you agree to our Terms of Service and Privacy Policy")
                        .font(themeManager.captionFont())
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
    }
    
    private func registerUser() {
        guard password == confirmPassword else {
            authManager.errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        guard !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty else {
            authManager.errorMessage = "Please fill in all fields"
            showError = true
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
            } catch {
                showError = true
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
