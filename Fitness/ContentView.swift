import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            // If still loading, OR if Firebase indicates a user but authManager hasn't updated, show loading indicator
            if authManager.isLoading || (Auth.auth().currentUser != nil && authManager.currentUser == nil) {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let _ = authManager.currentUser {
                // When authManager.currentUser is populated, show the appropriate view
                if authManager.currentGroup != nil {
                    roleBasedHomeView
                } else {
                    roleBasedGroupActionView
                }
            } else {
                // No authenticated user: show the initial screen
                InitialScreenView()
            }
        }
        .task {
            // Set up listeners when the view appears
            if let user = Auth.auth().currentUser {
                authManager.setupListeners(uid: user.uid)
            }
        }
    }
    
    private var roleBasedHomeView: some View {
        Group {
            if authManager.currentUser?.role == .coach {
                CoachHome()
            } else if let client = authManager.currentUser {
                ClientHome(client: client)
            } else {
                EmptyView()
            }
        }
    }
    
    private var roleBasedGroupActionView: some View {
        Group {
            if authManager.currentUser?.role == .coach {
                CreateGroup()
            } else {
                EnterCodeView() // Direct clients to code entry
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(AuthManager.shared)
}
