import SwiftUI

struct EnterCodeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var code = ""
    @State private var showError = false
    
    var body: some View {
        ZStack (alignment: .center){
            Color("SecondaryAccent")
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Join a Group")
                    .font(.title)
                    .foregroundColor(.white)
                
                StrokedTextField(
                    text: $code,
                    label: "Enter Group Code",
                    placeholder: "ABC-123",
                    strokeColor: .white,
                    textColor: .white,
                    labelColor: .white.opacity(0.9),
                    cornerRadius: 8,
                    lineWidth: 1,
                    iconName: "number" // Use an appropriate icon if needed
                )
                .textCase(.uppercase)
                
                if showError {
                    Text(authManager.errorMessage ?? "Invalid code")
                        .foregroundColor(.red)
                }
                
                Button(action: joinGroup) {
                    Text("Join Group")
                        .font(.headline)
                        .foregroundColor(Color("Accent"))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color("White"))
                        .cornerRadius(25)
                }
                .padding()
            }
            .padding()
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
    }
}
