import SwiftUI

struct MealDetailsView: View {
    var meal: Meal?
    var mealSlot: String  // e.g. "Meal 1", "Snack 1"
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
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
        @EnvironmentObject var themeManager: ThemeManager
        @Environment(\.colorScheme) var colorScheme

        var body: some View {
            Button(action: action) {
                Text(label)
                    .font(themeManager.bodyFont(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(themeManager.accentColor(for: colorScheme))
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
                                                        themeManager.backgroundColor(for: colorScheme).opacity(1)
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
                                                            themeManager.backgroundColor(for: colorScheme).opacity(1)
                                                        ]),
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .zIndex(0)
                                        }
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(themeManager.cardBackgroundColor(for: colorScheme))
                                            .frame(width: geometry.size.width - 50, height: 73)
                                            .overlay {
                                                Text(meal.mealName)
                                                    .font(themeManager.titleFont(size: 28))
                                                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                                    .font(themeManager.titleFont(size: 24))
                                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                                    .padding(.top, 26)
                                Text("Ingredients & Nutrition")
                                    .font(themeManager.headingFont(size: 20))
                                    .foregroundStyle(themeManager.textColor(for: colorScheme))
                                if !meal.ingredients.isEmpty {
                                    ForEach(meal.ingredients.indices, id: \.self) { index in
                                        let ingredient = meal.ingredients[index]
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(ingredient.name) (\(ingredient.amount))")
                                                .font(themeManager.bodyFont(size: 16))
                                                .fontWeight(.semibold)
                                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                                            Text("Calories: \(ingredient.calories) | Protein: \(ingredient.protein) | Carbs: \(ingredient.carbs) | Fats: \(ingredient.fats)")
                                                .font(themeManager.bodyFont(size: 14))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .foregroundStyle(themeManager.textColor(for: colorScheme))
                                        }
                                        Divider()
                                            .background(themeManager.textColor(for: colorScheme).opacity(0.3))
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Grilled Chicken Breast (120g)")
                                            .font(themeManager.bodyFont(size: 16))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                        Text("Calories: 198 kcal | Protein: 37g | Carbs: 0g | Fats: 4g")
                                            .font(themeManager.bodyFont(size: 14))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                    }
                                    Divider()
                                        .background(themeManager.textColor(for: colorScheme).opacity(0.3))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Mixed Leafy Greens (50g)")
                                            .font(themeManager.bodyFont(size: 16))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                        Text("Calories: 15 kcal | Protein: 2g | Carbs: 3g | Fats: 0g")
                                            .font(themeManager.bodyFont(size: 14))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .offset(y: -30)
                        }
                    }
                    .background(themeManager.backgroundColor(for: colorScheme))
                    
                    // Sticky Bottom Bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if !meal.ingredients.isEmpty {
                                Text("Total Calories: \(totalCalories) kcal")
                                    .font(themeManager.bodyFont(size: 16))
                                    .fontWeight(.semibold)
                                Text("Protein: \(totalProtein)g")
                                    .font(themeManager.bodyFont(size: 14))
                                Text("Carbs: \(totalCarbs)g")
                                    .font(themeManager.bodyFont(size: 14))
                                Text("Fats: \(totalFats)g")
                                    .font(themeManager.bodyFont(size: 14))
                            } else {
                                Text("Total Calories: 550 kcal")
                                    .font(themeManager.bodyFont(size: 16))
                                    .fontWeight(.semibold)
                                Text("Protein: 38g")
                                    .font(themeManager.bodyFont(size: 14))
                                Text("Carbs: 42g")
                                    .font(themeManager.bodyFont(size: 14))
                                Text("Fats: 21g")
                                    .font(themeManager.bodyFont(size: 14))
                            }
                        }
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background(themeManager.accentColor(for: colorScheme))
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                    .ignoresSafeArea(edges: .bottom)
                }
                .edgesIgnoringSafeArea(.bottom)
                .edgesIgnoringSafeArea(.top)
                .navigationBarBackButtonHidden()
            } else {
                // Fallback view when no meal data is available.
                ZStack {
                    themeManager.backgroundColor(for: colorScheme)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("\(mealSlot) Details")
                            .font(themeManager.titleFont(size: 24))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        Text("No meal information available.")
                            .font(themeManager.bodyFont())
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        ProgressView()
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    MealDetailsView(meal: nil, mealSlot: "Meal 1")
        .environmentObject(ThemeManager())
}
