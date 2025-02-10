import SwiftUI

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
    var mealPlan: MealPlan?
    
    private var totalCalories: Int {
        mealPlan?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.calories) ?? 0)
        } ?? 0
    }
    
    private var totalProtein: Int {
        mealPlan?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.protein) ?? 0)
        } ?? 0
    }
    
    private var totalCarbs: Int {
        mealPlan?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.carbs) ?? 0)
        } ?? 0
    }
    
    private var totalFats: Int {
        mealPlan?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.fats) ?? 0)
        } ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Image Section with Floating Title
                    ZStack(alignment: .top) {
                        GeometryReader { geometry in
                            ZStack {
                                if let mealPlan = mealPlan,
                                   let imageUrl = mealPlan.imageUrl,
                                   let url = URL(string: imageUrl) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: geometry.size.width, height: geometry.size.height)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure(_):
                                            Color.gray
                                                .frame(width: geometry.size.width, height: geometry.size.height)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.6),
                                                Color("Background").opacity(1)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .zIndex(0)
                                } else {
                                    Image("salad")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geometry.size.width, height: geometry.size.height)
                                        .clipped()
                                        .overlay(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.black.opacity(0.6),
                                                    Color("Background").opacity(1)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .zIndex(0)
                                }
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundColor(Color("White"))
                                    .frame(width: geometry.size.width - 50, height: 73)
                                    .overlay {
                                        Text(mealPlan?.mealName ?? "Meal Details")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(Color("Accent"))
                                    }
                                    .offset(y: -30)
                                    .zIndex(1)
                            }
                        }
                        .frame(height: 300)
                    }
                    
                    // Ingredients & Nutrition Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(mealPlan?.mealName ?? "Meal Name")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 26)
                        Text("Ingredients & Nutrition")
                            .font(.title2)
                            .fontWeight(.semibold)
                        if let mealPlan = mealPlan, !mealPlan.ingredients.isEmpty {
                            ForEach(mealPlan.ingredients) { ingredient in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(ingredient.name) (\(ingredient.amount))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Calories: \(ingredient.calories) | Protein: \(ingredient.protein) | Carbs: \(ingredient.carbs) | Fats: \(ingredient.fats)")
                                        .font(.body)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                                Divider()
                                    .background(Color.black.opacity(0.3))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mixed Leafy Greens (50g)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Calories: 15 kcal | Protein: 2g | Carbs: 3g | Fats: 0g")
                                    .font(.body)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .offset(y: -30)
                }
            }
            .background(Color("Background"))
            
            // Sticky Bottom Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let mealPlan = mealPlan, !mealPlan.ingredients.isEmpty {
                        Text("Total Calories: \(totalCalories) kcal")
                            .font(.headline)
                        Text("Protein: \(totalProtein)g")
                        Text("Carbs: \(totalCarbs)g")
                        Text("Fats: \(totalFats)g")
                    } else {
                        Text("Total Calories: 550 kcal")
                            .font(.headline)
                        Text("Protein: 38g")
                        Text("Carbs: 42g")
                        Text("Fats: 21g")
                    }
                }
                .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 150)
            .background(Color("Accent"))
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            .ignoresSafeArea(edges: .bottom)
        }
        .edgesIgnoringSafeArea(.bottom)
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    let dummyIngredients = [
        Ingredient(name: "Grilled Chicken Breast", amount: "120g", protein: "37", calories: "198", carbs: "0", fats: "4"),
        Ingredient(name: "Mixed Leafy Greens", amount: "50g", protein: "2", calories: "15", carbs: "3", fats: "0")
    ]
    let dummyMealPlan = MealPlan(
        id: "1",
        clientId: "dummy",
        day: "Monday",
        mealType: "Meal 1",
        mealName: "Chicken Salad",
        imageUrl: "https://via.placeholder.com/400",
        ingredients: dummyIngredients,
        timestamp: Date()
    )
    
    MealDetailsView(mealPlan: dummyMealPlan)
}
