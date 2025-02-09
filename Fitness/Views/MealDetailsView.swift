//
//  MealDetailsView.swift
//  Fitness
//
//  Created by Harry Phillips on 07/02/2025.
//

import SwiftUI

// Custom shape to round specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MealDetailsView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Image Section with Floating Title
                    ZStack(alignment: .top) {
                        GeometryReader { geometry in
                            ZStack {
                                // Salad image behind everything
                                Image("salad")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height)
                                    .clipped()
                                    .overlay {
                                        // Dark overlay gradient to fade into background
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.6),
                                                Color("Background").opacity(1)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(width: geometry.size.width,
                                               height: geometry.size.height)
                                    }
                                    .zIndex(0)
                                
                                // Floating white rectangle with meal title
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(Color("White"))
                                    .frame(width: geometry.size.width - 50,
                                           height: 73)
                                    .overlay {
                                        Text("Monday Meal 1")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundStyle(Color("Accent"))
                                    }
                                    .offset(y: -30)
                                    .zIndex(1)
                            }
                        }
                        .frame(height: 300) // Adjust height as needed
                    }
                    
                    // Ingredients & Nutrition Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Salad Bowl")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 26)
                        
                        Text("Ingredients & Nutrition")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading) {
                            Text("Grilled Chicken Breast (120g)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Calories: 198 kcal | Protein: 37g | Carbs: 0g | Fats: 4g")
                                .font(.body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        
                        Divider()
                            .background(Color.black.opacity(0.3))
                            .frame(height: 5)
                        
                        VStack(alignment: .leading) {
                            Text("Mixed Leafy Greens (50g)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Calories: 15 kcal | Protein: 2g | Carbs: 3g | Fats: 0g")
                                .font(.body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                    .padding(.horizontal)
                    // Bring the ingredients view up to overlap the bottom of the image a little
                    .offset(y: -30)
                }
            }
            .background(Color("Background"))
            
            // ===== Sticky Bar at the Bottom using an Overlay =====
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Calories: 550 kcal")
                        .font(.headline)
                    Text("Protein: 38g")
                    Text("Carbs: 42g")
                    Text("Fats: 21g")
                }
                .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity,maxHeight:150)
            .background(Color("Accent"))
            .ignoresSafeArea(edges: .bottom) // Extend accent to the bottom edge
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
        }
        .edgesIgnoringSafeArea(.bottom)
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    MealDetailsView()
}
