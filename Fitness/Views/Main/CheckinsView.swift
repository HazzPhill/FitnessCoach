//
//  CheckinsView.swift
//  Coach by Wardy
//
//  Created by Harry Phillips on 20/07/2025.
//

import SwiftUI

struct CheckinsView: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var lastSettingsUpdate = Date()
    @Namespace private var namespace
    @Namespace private var checkinNamespace
    @State private var showEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Section
            HStack {
                Text("Daily Goals")
                    .font(themeManager.titleFont(size: 24))
                    .foregroundStyle(.black)
                Spacer()
                
                if let profileImageUrl = client.profileImageUrl,
                   let url = URL(string: profileImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(width: 45, height: 45)
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        case .failure(_):
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 45, height: 45)
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
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
    }
}

#Preview {
    // Dummy user for preview
    let sampleUser = AuthManager.DBUser(
        userId: "preview123",
        firstName: "Preview",
        lastName: "User",
        email: "preview@example.com",
        role: .client,
        profileImageUrl: nil
    )
    return CheckinsView(client: sampleUser)
}
