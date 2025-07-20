import SwiftUI
import FirebaseAuth
import UserNotifications

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isLoading || (Auth.auth().currentUser != nil && authManager.currentUser == nil) {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("Background"))
            } else if let _ = authManager.currentUser {
                if authManager.currentGroup != nil {
                    roleBasedHomeView
                } else {
                    roleBasedGroupActionView
                }
            } else {
                InitialScreenView()
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    scheduleWeeklyNotification()
                    scheduleDailyNotification()
                } else {
                    print("Notification permission denied.")
                }
            }
        }
        .task {
            if let user = Auth.auth().currentUser {
                authManager.setupListeners(uid: user.uid)
            }
        }
    }
    
    func scheduleWeeklyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Checkin"
        content.body = "Have you done your weekly checkin?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklyCheckin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling weekly notification: \(error)")
            }
        }
    }
    
    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Checkin"
        content.body = "Daily checkin"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckin", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error)")
            }
        }
    }
    
    private var roleBasedHomeView: some View {
        Group {
            if authManager.currentUser?.role == .coach {
                CoachHome()
            } else if let client = authManager.currentUser {
                ClientTabView(client: client)
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
                EnterCodeView()
            }
        }
    }
}

struct ClientTabView: View {
    let client: AuthManager.DBUser // Use AuthManager.DBUser instead of User
    
    var body: some View {
        TabView {
            ClientHome(client: client) // Ensure ClientHome accepts AuthManager.DBUser
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            GoalsView(client: client)
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            
            MealsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
            
            CheckinsView(client: client)
                .tabItem {
                    Label("Checkins", systemImage: "checkmark.square")
                }
        }
        .glassTabBarStyle()
    }
}


struct MealsView: View {
    var body: some View {
        Text("Meals")
    }
}

extension View {
    func glassTabBarStyle() -> some View {
        self.modifier(GlassTabBarModifier())
    }
}

struct GlassTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

#Preview {
    ContentView().environmentObject(AuthManager.shared)
}

