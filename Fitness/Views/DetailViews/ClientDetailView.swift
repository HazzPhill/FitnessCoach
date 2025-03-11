import SwiftUI

struct ClientDetailView: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
                
            VStack(alignment: .leading, spacing: 16) {
                Text("Client: \(client.firstName) \(client.lastName)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                // Add any additional details you'd like to display.
                // For example, you could load and show the client's updates or progress.
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Client Details")
    }
}

struct ClientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Dummy client for preview
        let dummyClient = AuthManager.DBUser(
            userId: "client123",
            firstName: "John",
            lastName: "Doe",
            email: "john.doe@example.com",
            role: .client,
            groupId: "group123",
            profileImageUrl: nil,
            createdAt: nil
        )
        ClientDetailView(client: dummyClient)
            .environmentObject(ThemeManager())
    }
}
