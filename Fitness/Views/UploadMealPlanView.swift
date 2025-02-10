import SwiftUI

struct UploadMealPlanView: View {
    var clientId: String    // The client's ID for whom this meal is being uploaded.
    var day: String         // e.g. "Monday"
    var mealType: String    // e.g. "Meal 1" or "Snack 1"
    
    @State private var mealName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var uploadStatus: String = ""
    @State private var ingredients: [Ingredient] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Meal Information")) {
                    TextField("Meal Name", text: $mealName)
                    Text("Meal Type: \(mealType)")
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Meal Image")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } else {
                        Button("Select Image") {
                            isImagePickerPresented = true
                        }
                    }
                }
                
                Section(header: Text("Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        VStack(alignment: .leading) {
                            TextField("Ingredient Name", text: $ingredient.name)
                            TextField("Amount", text: $ingredient.amount)
                            TextField("Protein", text: $ingredient.protein)
                            TextField("Calories", text: $ingredient.calories)
                            TextField("Carbs", text: $ingredient.carbs)
                            TextField("Fats", text: $ingredient.fats)
                        }
                    }
                    .onDelete(perform: deleteIngredient)
                    
                    Button("Add Ingredient") {
                        ingredients.append(Ingredient(name: "", amount: "", protein: "", calories: "", carbs: "", fats: ""))
                    }
                }
                
                Section {
                    Button("Upload Meal Plan") {
                        Task {
                            do {
                                try await MealPlanManager.shared.uploadMealPlan(clientId: clientId,
                                                                                day: day,
                                                                                mealType: mealType,
                                                                                mealName: mealName,
                                                                                ingredients: ingredients,
                                                                                image: selectedImage)
                                uploadStatus = "Upload successful!"
                            } catch {
                                uploadStatus = "Error: \(error.localizedDescription)"
                                print(uploadStatus)
                            }
                        }
                    }
                }
                
                if !uploadStatus.isEmpty {
                    Text(uploadStatus)
                        .foregroundColor(uploadStatus.contains("Error") ? .red : .green)
                }
            }
            .navigationTitle("\(day) \(mealType) Plan")
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
}

#Preview {
    // For preview purposes, provide a dummy client ID.
    UploadMealPlanView(clientId: "dummyClientId", day: "Monday", mealType: "Meal 1")
}
