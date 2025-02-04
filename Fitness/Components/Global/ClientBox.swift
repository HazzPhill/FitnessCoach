//
//  KPIBox 2.swift
//  Fitness
//
//  Created by Harry Phillips on 04/02/2025.
//


import SwiftUI

struct ClientBox: View {
    var clientName: String
    var weight: Int
    var activeTime: String

    var body: some View {
        VStack (alignment:.leading) {
            HStack{
                Text("\(clientName)")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image("gym_background")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(.circle)
                
            }
            
            
            HStack {
                Image (systemName: "square.and.arrow.up.circle")
                    .foregroundStyle(Color("SecondaryAccent"))
                
                Text("\(activeTime)")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.black.opacity(0.5))
                
                Spacer()
                
                Text("\(weight)")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.black.opacity(0.5))
            }
            }
        .padding(.horizontal, 16)
        .frame(width: 164, height: 77, alignment: .leading)
        .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
        .background(Color.white)
        }
    }


#Preview {
    ClientBox(clientName: "Harry P", weight: 56, activeTime: "3 hr ago")
}
