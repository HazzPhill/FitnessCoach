//
//  CoachHome.swift
//  Fitness
//
//  Created by Harry Phillips on 04/02/2025.
//

import SwiftUI

struct CoachHome: View {
    @EnvironmentObject var authManager: AuthManager  // Inject AuthManager
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
                    
                    Text ("Your Summary")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        
                    
                        HStack{
                            
                            KPIBox(label: "Clients", figure: 200)
                            
                                .padding(.trailing, 20)
                            
                            KPIBox(label: "Total Revenue", figure: 200)
                            
                                .padding(.trailing, 20)
                            
                            KPIBox(label: "Total Revenue", figure: 200)
                            
                                .padding(.trailing, 20)
                        }
                        .padding(.vertical)
                        
                    }
                    
                    Text ("Your Clients")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundStyle(.black)
                        
                    
                        HStack (spacing: 26) {
                            
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

#Preview {
    CoachHome()
}
