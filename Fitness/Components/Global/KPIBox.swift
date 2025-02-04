//
//  KPIBox.swift
//  Fitness
//
//  Created by Harry Phillips on 04/02/2025.
//

import SwiftUI

struct KPIBox: View {
    var label: String
    var figure: Int

    var body: some View {
        VStack (alignment:.leading) {
            Text("\(figure)")
                .font(.system(size: 36, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            Text("\(label)")
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(width: 164, height: 98, alignment: .leading)
        .padding(.leading,16)
        .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
        .background(Color.white)
    }
}

#Preview {
    KPIBox(label: "Clients", figure: 200)
}
