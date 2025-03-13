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
                .font(themeManager.bodyFont(size: 16))
                .fontWeight(.semibold)
                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            ModernTextField(placeholder: "Meal Name", text: $mealName)
                                .environmentObject(themeManager)
                        }
                        
                        // Meal Image Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Image")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                                        .font(themeManager.bodyFont())
                                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                        .padding()
                                        .frame(maxWidth: .infinity, minHeight: 50)
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
                                .font(themeManager.headingFont(size: 18))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                                        .font(themeManager.bodyFont())
                                }
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(themeManager.accentColor(for: colorScheme).opacity(0.1))
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
                                .font(themeManager.bodyFont())
                                .foregroundStyle(uploadStatus.contains("Error") ? .red : .green)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("\(day) – \(mealSlot) Plan")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
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
                    CustomTextField(placeholder: "Amount", text: $ingredient.amount)
                        .environmentObject(themeManager)
                    CustomTextField(placeholder: "Protein", text: $ingredient.protein)
                        .environmentObject(themeManager)
                    CustomTextField(placeholder: "Calories", text: $ingredient.calories)
                        .environmentObject(themeManager)
                    CustomTextField(placeholder: "Carbs", text: $ingredient.carbs)
                        .environmentObject(themeManager)
                    CustomTextField(placeholder: "Fats", text: $ingredient.fats)
                        .environmentObject(themeManager)
                }
                .padding(.vertical, 5)
            },
            label: {
                HStack {
                    CustomTextField(placeholder: "Ingredient Name", text: $ingredient.name)
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
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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

// Custom TextField with proper styling
struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(themeManager.bodyFont())
                    .foregroundStyle(placeholderColor)
                    .padding(.horizontal)
            }
            
            TextField("", text: $text)
                .font(themeManager.bodyFont())
                .foregroundStyle(themeManager.textColor(for: colorScheme))
                .padding()
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ?
                                themeManager.accentColor(for: colorScheme) :
                                Color(hex: "C6C6C6"),
                                lineWidth: isFocused ? 3 : 2)
                )
                .focused($isFocused)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
    
    // Compute placeholder color based on mode
    private var placeholderColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.8)
        } else {
            return Color.white.opacity(0.8)
        }
    }
}
