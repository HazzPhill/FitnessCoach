//
//  GoalsView.swift
//  Coach by Wardy
//
//  Created by Harry Phillips on 20/07/2025.
//

import SwiftUI

struct GoalsView: View {
    
    let client: AuthManager.DBUser
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @State private var lastSettingsUpdate = Date()
    @Namespace private var namespace
    @Namespace private var checkinNamespace
    @State private var showEditSheet = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
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
                
                DailyGoalsGridView(userId: client.userId)
                    .environmentObject(themeManager)
                    .id("goals-grid-\(lastSettingsUpdate.timeIntervalSince1970)")
                    .transition(.opacity)
                
                // Liquid Glass Button
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit Goals")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .glassEffect(.regular.interactive().tint(Color(hex: "002E37")))
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            DailyGoalsView(userId: client.userId)
                .presentationDetents([.medium])
                .presentationBackground(.ultraThinMaterial)
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    GoalsView(client: AuthManager.DBUser(
        userId: "preview-user-123",
        firstName: "Sam",
        lastName: "Test",
        email: "sam.test@example.com",
        role: .client,
        groupId: nil,
        profileImageUrl: nil,
        createdAt: nil
    ))
}
