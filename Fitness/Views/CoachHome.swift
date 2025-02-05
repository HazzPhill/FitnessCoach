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
                        // Replace the gym_background image with the user's profile picture.
                        NavigationLink {
                            SettingsView()
                        } label: {
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
                    
                    HStack(spacing: 26) {
                        ClientBox(clientName: "Harry P", weight: 56, activeTime: "3hr ago")
                        ClientBox(clientName: "Harry P", weight: 56, activeTime: "3hr ago")
                    }
                    .padding(.vertical)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct CoachHome_Previews: PreviewProvider {
    static var previews: some View {
        // Use environmentObject to inject the AuthManager instance
        CoachHome()
            .environmentObject(AuthManager.shared)
    }
}
