import SwiftUI

struct CoachHome: View {
    @EnvironmentObject var authManager: AuthManager  // Inject AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                VStack(alignment: .leading) {
                    HStack {
                        Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                            .font(themeManager.titleFont(size: 24))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        Spacer()
                        NavigationLink {
                            SettingsView()
                        } label: {
                            // Profile picture code…
                            if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } else if phase.error != nil {
                                        Image(systemName: "person.circle")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } else {
                                        ProgressView()
                                            .frame(width: 45, height: 45)
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    Text("Your Summary")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundStyle(themeManager.textColor(for: colorScheme))
                    
                    // Your KPI ScrollView …
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            KPIBox(label: "Clients", figure: 200)
                                .environmentObject(themeManager)
                                .padding(.trailing, 20)
                            KPIBox(label: "Total Revenue", figure: 200)
                                .environmentObject(themeManager)
                                .padding(.trailing, 20)
                            KPIBox(label: "Total Revenue", figure: 200)
                                .environmentObject(themeManager)
                                .padding(.trailing, 20)
                        }
                        .padding(.vertical)
                    }
                    
                    Text("Your Clients")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundStyle(themeManager.textColor(for: colorScheme))
                    
                    if let group = authManager.currentGroup, let groupId = group.id {
                        ClientListView(groupId: groupId)
                            .environmentObject(themeManager)
                    } else {
                        Text("No group found. Please create or join a group.")
                            .font(themeManager.bodyFont())
                            .foregroundStyle(themeManager.textColor(for: colorScheme).opacity(0.6))
                            .padding(.vertical)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct CoachHome_Previews: PreviewProvider {
    static var previews: some View {
        CoachHome()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
