//
//  dayMealPlanPere.swift
//  Fitness
//
//  Created by Harry Phillips on 06/02/2025.
//

import SwiftUI

struct dayMealPlanPreview: View {
    var day: String = "Monday"
    var meal: String
    var snack: String
    
    @Namespace private var mealviewtrans
    
    var body: some View {
        NavigationStack {
            VStack (alignment:.leading, spacing: 12) {
                Text ("\(day)")
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .padding (.bottom, 5)
                
                NavigationLink {
                    MealDetailsView()
                        .navigationTransition(.zoom(sourceID: "zoommeal" , in: mealviewtrans))
                } label: {
                    HStack {
                        
                        Text ("\(meal)")
                            .foregroundStyle(.black)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Image (systemName:"fork.knife")
                            .foregroundStyle(.black)
                    }
                    .matchedTransitionSource(id:"zoommeal", in: mealviewtrans)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("BoxStroke"), lineWidth: 2)
                    )
                    .background(Color("Background"))
                    .frame(maxWidth: 220)
                }
                
                
                HStack {
                    
                    Text ("\(snack)")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image (systemName:"fork.knife")
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
                .background(Color("Background"))
                .frame(maxWidth: 220)
                
                HStack {
                    
                    Text ("\(meal)")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image (systemName:"fork.knife")
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
                .background(Color("Background"))
                .frame(maxWidth: 220)
                
                HStack {
                    
                    Text ("\(snack)")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image (systemName:"fork.knife")
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
                .background(Color("Background"))
                .frame(maxWidth: 220)
                
                HStack {
                    
                    Text ("\(meal)")
                        .font(.system(size: 14))
                    
                    Spacer()
                    
                    Image (systemName:"fork.knife")
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("BoxStroke"), lineWidth: 2)
                )
                .background(Color("Background"))
                .frame(maxWidth: 220)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("BoxStroke"), lineWidth: 2)
            )
            .background(Color.white)
        }
        
    }
}

#Preview {
    dayMealPlanPreview(day: "Mon", meal: "Meal 1", snack: "Snack 1")
}
