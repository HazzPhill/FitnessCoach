//
//  ClientDetailView.swift
//  Fitness
//
//  Created by Harry Phillips on 09/02/2025.
//

import SwiftUI

struct ClientDetailView: View {
    let client: AuthManager.DBUser

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client: \(client.firstName) \(client.lastName)")
                .font(.title)
                .fontWeight(.bold)
            // Add any additional details you’d like to display.
            // For example, you could load and show the client's updates or progress.
            Spacer()
        }
        .padding()
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
    }
}
