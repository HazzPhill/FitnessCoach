import SwiftUI

struct EnterCodeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var code = ""
    @State private var showError = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                Color("SecondaryAccent")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Custom header with app fonts
                    Text("Join a Group")
                        .font(themeManager.headingFont(size: 30))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Code instruction text
                    Text("Enter the 6-digit code provided by your coach to join their training group")
                        .font(themeManager.bodyFont())
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    StrokedTextField(
                        text: $code,
                        label: "Enter Group Code",
                        placeholder: "ABC123",
                        strokeColor: .white,
                        textColor: .white,
                        labelColor: .white.opacity(0.9),
                        cornerRadius: 8,
                        lineWidth: 1,
                        iconName: "number"
                    )
                    .textCase(.uppercase)
                    
                    if showError {
                        Text(authManager.errorMessage ?? "Invalid code")
                            .font(themeManager.bodyFont(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Button(action: joinGroup) {
                        if authManager.isLoading {
                            ProgressView()
                                .tint(Color("Accent"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        } else {
                            Text("Join Group")
                                .font(themeManager.bodyFont(size: 16))
                                .foregroundColor(Color("Accent"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .disabled(code.isEmpty || authManager.isLoading)
                    .opacity(code.isEmpty ? 0.7 : 1)
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Custom back button that shows sign out confirmation
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(themeManager.bodyFont(size: 16))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authManager.signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func joinGroup() {
        Task {
            do {
                try await authManager.joinGroup(code: code)
            } catch {
                showError = true
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}
struct EnterCodeView_Previews: PreviewProvider {
    static var previews: some View {
        EnterCodeView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
