import SwiftUI
import PhotosUI

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

// MARK: - IngredientAccordionView
struct IngredientAccordionView: View {
    @Binding var ingredient: Ingredient
    @Binding var isExpanded: Bool
    let onDelete: () -> Void

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    ModernTextField(placeholder: "Amount", text: $ingredient.amount)
                    ModernTextField(placeholder: "Protein", text: $ingredient.protein)
                    ModernTextField(placeholder: "Calories", text: $ingredient.calories)
                    ModernTextField(placeholder: "Carbs", text: $ingredient.carbs)
                    ModernTextField(placeholder: "Fats", text: $ingredient.fats)
                }
                .padding(.vertical, 5)
            },
            label: {
                HStack {
                    ModernTextField(placeholder: "Ingredient Name", text: $ingredient.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Color("Warning"))
                      
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 8)
                    // Custom chevron arrow using SF Symbols
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundColor(Color("SecondaryAccent"))
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
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}


// MARK: - UploadMealPlanView
struct UploadMealPlanView: View {
    var clientId: String    // The client's ID for whom this meal is being uploaded.
    var day: String         // e.g. "Monday"
    var mealType: String    // e.g. "Meal 1" or "Snack 1"
    
    @State private var mealName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var uploadStatus: String = ""
    @State private var ingredients: [Ingredient] = []
    @State private var expandedIngredientIndex: Int? = nil  // Track which ingredient is expanded
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Meal Information Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Information")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ModernTextField(placeholder: "Meal Name", text: $mealName)
                                .padding(.horizontal)
                            
                            Text("Meal Type: \(mealType)")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)
                        }
                        
                        // Meal Image Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meal Image")
                                .font(.headline)
                                .foregroundColor(.white)
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
                                        .foregroundColor(Color("SecondaryAccent"))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color("Accent").opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color("Accent"), lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Ingredients Section (Accordion)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(.white)
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
                                .foregroundColor(Color("Accent"))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color("Accent"), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // Upload Button Section
                        ModernButton(label: "Upload Meal Plan") {
                            Task {
                                do {
                                    try await MealPlanManager.shared.uploadMealPlan(
                                        clientId: clientId,
                                        day: day,
                                        mealType: mealType,
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
            .navigationTitle("\(day) \(mealType) Plan")
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct UploadMealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        UploadMealPlanView(clientId: "dummyClientId", day: "Monday", mealType: "Meal 1")
    }
}
