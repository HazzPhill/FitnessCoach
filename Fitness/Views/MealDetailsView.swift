import SwiftUI

struct MealDetailsView: View {
    var meal: Meal?
    var mealSlot: String  // e.g. "Meal 1", "Snack 1"
    
    private var totalCalories: Int {
        meal?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.calories) ?? 0)
        } ?? 0
    }
    
    private var totalProtein: Int {
        meal?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.protein) ?? 0)
        } ?? 0
    }
    
    private var totalCarbs: Int {
        meal?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.carbs) ?? 0)
        } ?? 0
    }
    
    private var totalFats: Int {
        meal?.ingredients.reduce(0) { sum, ingredient in
            sum + (Int(ingredient.fats) ?? 0)
        } ?? 0
    }
    
    struct ModernButton: View {
        let label: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(Color("Background"))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color("Accent"))
                    .cornerRadius(25)
                    .padding(.horizontal)
            }
        }
    }
    
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
        
        var body: some View {
            Group {
                if let meal = meal {
                    // Display the meal details if available.
                    ZStack(alignment: .bottom) {
                        ScrollView {
                            VStack(spacing: 0) {
                                // Top Image Section
                                ZStack(alignment: .top) {
                                    GeometryReader { geometry in
                                        ZStack {
                                            if let imageUrl = meal.imageUrl, let url = URL(string: imageUrl) {
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
                                                    Text(meal.mealName)
                                                        .font(.system(size: 28, weight: .bold))
                                                        .foregroundColor(Color("Accent"))
                                                }
                                                .offset(y: -30)
                                                .zIndex(1)
                                        }
                                    }
                                    .frame(height: 300)
                                }
                                
                                // Ingredients Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text(meal.mealName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .padding(.top, 26)
                                    Text("Ingredients & Nutrition")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    if !meal.ingredients.isEmpty {
                                        ForEach(meal.ingredients) { ingredient in
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
                                if !meal.ingredients.isEmpty {
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
                } else {
                    // Fallback view when no meal data is available.
                    VStack(spacing: 20) {
                        Text("\(mealSlot) Details")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("No meal information available.")
                            .font(.body)
                        ProgressView()
                    }
                    .padding()
                }
            }
        }
    }

