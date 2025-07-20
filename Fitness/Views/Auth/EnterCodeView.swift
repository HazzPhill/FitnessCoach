import SwiftUI

struct EnterCodeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var code = ""
    @State private var showError = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                
                Image("gym_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .allowsHitTesting(false)
                
                VStack(spacing: 24) {
                    // Custom header with app fonts
                    Text("Join a Group")
                        .font(themeManager.headingFont(size: 30))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        .padding(.bottom, 8)
                    
                    // Code instruction text
                    Text("Enter the 6-digit code provided by your coach to join their training group")
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    StrokedTextField(
                        text: $code,
                        label: "Enter Group Code",
                        placeholder: "ABC123",
                        strokeColor: .primary,
                        textColor: .primary,
                        labelColor: .primary,
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
                                .tint(themeManager.accentOrWhiteText(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(themeManager.accentOrWhiteText(for: colorScheme).opacity(0.2))
                                .cornerRadius(25)
                        } else {
                            Text("Join Group")
                                .font(themeManager.bodyFont(size: 16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .glassEffect(.regular.tint(Color(hex: "002E37")))
                        }
                    }
                    .padding()
                    .disabled(code.isEmpty || authManager.isLoading)
                    .opacity(code.isEmpty ? 0.7 : 1)
                }
                .padding()
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30))
                .padding(.horizontal)
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
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .glassEffect(.regular.interactive())
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
