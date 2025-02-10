import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
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
            
            ScrollView {
                VStack(alignment: .leading) {
                    HeaderSection(title: "Hello", subtitle: "Register")
                    
                    StrokedTextField(
                        text: $firstName,
                        label: "First Name",
                        placeholder: "John",
                        strokeColor: .white,
                        textColor: .white,
                        labelColor: .white.opacity(0.9),
                        cornerRadius: 8,
                        lineWidth: 1, iconName: "eye"
                    )
                    
                    StrokedTextField(
                        text: $lastName,
                        label: "Last Name",
                        placeholder: "Doe",
                        strokeColor: .white,
                        textColor: .white,
                        labelColor: .white.opacity(0.9),
                        cornerRadius: 8,
                        lineWidth: 1, iconName: "eye"
                    )
                    
                    StrokedTextField(
                        text: $email,
                        label: "Email",
                        placeholder: "info@example.com",
                        strokeColor: .white,
                        textColor: .white,
                        labelColor: .white.opacity(0.9),
                        cornerRadius: 8,
                        lineWidth: 1, iconName: "eye"
                    )
                    
                    RolePicker(selectedRole: $role)
                    
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
                    
                    if showError {
                        ErrorMessageView(message: authManager.errorMessage ?? "Registration failed")
                    }
                    
                    Button(action: registerUser) {
                        ActionButton(label: "Register", backgroundColor: Color("White"), textColor: Color("Accent"))
                    }
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


struct RolePicker: View {
    @Binding var selectedRole: UserRole
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Role")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            
            Picker("Select Role", selection: $selectedRole) {
                ForEach(UserRole.allCases, id: \.self) { role in
                    Text(role.rawValue.capitalized)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
}
