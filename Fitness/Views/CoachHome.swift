import SwiftUI

struct CoachHome: View {
    @EnvironmentObject var authManager: AuthManager  // Inject AuthManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea(edges: .all)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Accent"))
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
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                    
                    // Your KPI ScrollView …
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            KPIBox(label: "Clients", figure: 200)
                                .padding(.trailing, 20)
                            KPIBox(label: "Total Revenue", figure: 200)
                                .padding(.trailing, 20)
                            KPIBox(label: "Total Revenue", figure: 200)
                                .padding(.trailing, 20)
                        }
                        .padding(.vertical)
                    }
                    
                    Text("Your Clients")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                    
                    if let group = authManager.currentGroup, let groupId = group.id {
                        ClientListView(groupId: groupId)
                    } else {
                        Text("No group found. Please create or join a group.")
                            .foregroundColor(.gray)
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
    }
}
