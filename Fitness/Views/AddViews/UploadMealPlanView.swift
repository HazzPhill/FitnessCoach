import SwiftUI
import PhotosUI

// Import ModernButton component with a custom button
struct LocalModernButton: View {
    let label: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(themeManager.accentColor(for: colorScheme))
                .cornerRadius(25)
                .padding(.horizontal)
        }
    }
}

struct UploadMealPlanView: View {
    var clientId: String    // The client's ID for whom this meal is being uploaded.
    var day: String         // e.g. "Monday"
    var mealSlot: String    // e.g. "Meal 1" or "Snack 1" (renamed from mealType)
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var mealName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var uploadStatus: String = ""
    @State private var ingredients: [Ingredient] = []
    @State private var expandedIngredientIndex: Int? = nil  // Track which ingredient is expanded
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Meal Information Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Information")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            ModernTextField(placeholder: "Meal Name", text: $mealName)
                                .environmentObject(themeManager)
                        }
                        
                        // Meal Image Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Image")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            } else {
                                Button(action: {
                                    isImagePickerPresented = true
                                }) {
                                    Text("Select Image")
                                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(themeManager.accentColor(for: colorScheme).opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(themeManager.accentColor(for: colorScheme), lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Ingredients Section (Accordion)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            ForEach(ingredients.indices, id: \.self) { index in
                                IngredientAccordionView(
                                    ingredient: $ingredients[index],
                                    isExpanded: Binding(
                                        get: { expandedIngredientIndex == index },
                                        set: { newValue in
                                            if newValue {
                                                expandedIngredientIndex = index
                                            } else if expandedIngredientIndex == index {
                                                expandedIngredientIndex = nil
                                            }
                                        }
                                    ),
                                    onDelete: {
                                        ingredients.remove(at: index)
                                        // Adjust the expanded index accordingly.
                                        if expandedIngredientIndex == index {
                                            expandedIngredientIndex = nil
                                        } else if let current = expandedIngredientIndex, current > index {
                                            expandedIngredientIndex = current - 1
                                        }
                                    }
                                )
                                .environmentObject(themeManager)
                            }
                            
                            Button(action: {
                                ingredients.append(Ingredient(name: "", amount: "", protein: "", calories: "", carbs: "", fats: ""))
                                // Open the new ingredient's accordion by default.
                                expandedIngredientIndex = ingredients.count - 1
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Ingredient")
                                }
                                .foregroundColor(themeManager.accentColor(for: colorScheme))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(themeManager.cardBackgroundColor(for: colorScheme).opacity(0.3))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.accentColor(for: colorScheme), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // Upload Button Section
                        LocalModernButton(label: "Upload Meal Plan") {
                            Task {
                                do {
                                    try await MealPlanManager.shared.updateDailyMealPlan(
                                        clientId: clientId,
                                        day: day,
                                        mealSlot: mealSlot,   // This must exactly match the key used in Firestore.
                                        mealName: mealName,
                                        ingredients: ingredients,
                                        image: selectedImage
                                    )
                                    uploadStatus = "Upload successful!"
                                } catch {
                                    uploadStatus = "Error: \(error.localizedDescription)"
                                    print(uploadStatus)
                                }
                            }
                        }
                        .environmentObject(themeManager)
                        
                        // Upload status message
                        if !uploadStatus.isEmpty {
                            Text(uploadStatus)
                                .foregroundColor(uploadStatus.contains("Error") ? .red : .green)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("\(day) – \(mealSlot) Plan")
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct UploadMealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        UploadMealPlanView(clientId: "dummyClientId", day: "Monday", mealSlot: "Meal 1")
            .environmentObject(ThemeManager())
    }
}

// MARK: - IngredientAccordionView
struct IngredientAccordionView: View {
    @Binding var ingredient: Ingredient
    @Binding var isExpanded: Bool
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    ModernTextField(placeholder: "Amount", text: $ingredient.amount)
                        .environmentObject(themeManager)
                    ModernTextField(placeholder: "Protein", text: $ingredient.protein)
                        .environmentObject(themeManager)
                    ModernTextField(placeholder: "Calories", text: $ingredient.calories)
                        .environmentObject(themeManager)
                    ModernTextField(placeholder: "Carbs", text: $ingredient.carbs)
                        .environmentObject(themeManager)
                    ModernTextField(placeholder: "Fats", text: $ingredient.fats)
                        .environmentObject(themeManager)
                }
                .padding(.vertical, 5)
            },
            label: {
                HStack {
                    ModernTextField(placeholder: "Ingredient Name", text: $ingredient.name)
                        .environmentObject(themeManager)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color.red)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                    // Custom chevron arrow using SF Symbols
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .onTapGesture {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }
                }
            }
        )
        .accentColor(.clear) // Hide the default arrow.
        .padding(.vertical, 5)
        .background(themeManager.cardBackgroundColor(for: colorScheme).opacity(0.3))
        .cornerRadius(8)
    }
}
