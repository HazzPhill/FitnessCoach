//
//  ClientHome.swift
//  Fitness
//
//  Created by Harry Phillips on 04/02/2025.
//

import SwiftUI

struct ClientHome: View {
    @EnvironmentObject var authManager: AuthManager  //
    var body: some View {
        NavigationStack{
            ZStack {
                Color ("Background")
                    .ignoresSafeArea(edges: .all)
                VStack (alignment:.leading) {
                    HStack{
                        Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Accent"))
                        Spacer()
                        
                        Image("gym_background")
                            .resizable()
                            .frame(width: 45, height: 45)
                            .clipShape(.circle)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ClientHome()
}
