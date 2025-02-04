import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Show loading indicator while data is fetched
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let user = authManager.currentUser {
                if authManager.currentGroup != nil {
                    // User has a group, go to home
                    roleBasedHomeView
                } else {
                    // User has no group, show code entry or group creation
                    roleBasedGroupActionView
                }
            } else {
                // No authenticated user, show initial screen
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
            } else {
                ClientHome()
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
