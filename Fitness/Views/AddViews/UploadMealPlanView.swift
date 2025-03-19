import SwiftUI
import PhotosUI

struct UploadMealPlanView: View {
    // MARK: - Properties
    var clientId: String
    var day: String
    var mealSlot: String
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    @State private var mealName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var uploadStatus: String = ""
    @State private var ingredients: [Ingredient] = []
    @State private var expandedIngredientIndex: Int? = nil
    @State private var isUploading = false
    @State private var showSuccessAlert = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Meal Information Section
                        mealInfoSection
                        
                        // Meal Image Section
                        mealImageSection
                        
                        // Ingredients Section
                        ingredientsSection
                        
                        // Upload Button
                        uploadButton
                        
                        // Status message
                        statusMessage
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(day) – \(mealSlot)")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
            }
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Meal Plan Uploaded", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your meal plan has been successfully uploaded.")
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    // MARK: - Sections
    
    private var mealInfoSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Meal Information")
                
                EnhancedTextField(placeholder: "Meal Name", text: $mealName)
                    .environmentObject(themeManager)
            }
        }
    }
    
    private var mealImageSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Meal Image")
                
                if let image = selectedImage {
                    // Image selected view
                    imageSelectedView(image: image)
                } else {
                    // Image selection button
                    imageSelectionButton
                }
            }
        }
    }
    
    private func imageSelectedView(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            
            Button {
                isImagePickerPresented = true
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 2)
                    .padding(8)
            }
        }
    }
    
    private var imageSelectionButton: some View {
        Button {
            isImagePickerPresented = true
        } label: {
            ZStack {
                Rectangle()
                    .fill(themeManager.cardBackgroundColor(for: colorScheme))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.accentColor(for: colorScheme).opacity(0.4), lineWidth: 2)
                    )
                
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32))
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    
                    Text("Select an Image")
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
            }
        }
    }
    
    private var ingredientsSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Ingredients")
                
                if ingredients.isEmpty {
                    // Empty state
                    emptyIngredientsState
                } else {
                    // Ingredients list
                    ingredientsList
                }
                
                // Add ingredient button
                addIngredientButton
            }
        }
    }
    
    private var emptyIngredientsState: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 36))
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                
                Text("No ingredients added yet")
                    .font(themeManager.bodyFont())
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
            }
            .padding(.vertical, 30)
            Spacer()
        }
    }
    
    private var ingredientsList: some View {
        ForEach(Array(ingredients.indices), id: \.self) { index in
            VStack {
                ingredientView(for: index)
                
                if index < ingredients.count - 1 {
                    Divider()
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme).opacity(0.2))
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func ingredientView(for index: Int) -> some View {
        // Create the binding for the isExpanded state
        let isExpandedBinding = Binding<Bool>(
            get: { expandedIngredientIndex == index },
            set: { newValue in
                if newValue {
                    expandedIngredientIndex = index
                } else if expandedIngredientIndex == index {
                    expandedIngredientIndex = nil
                }
            }
        )
        
        // Create the onDelete closure
        let onDelete = {
            withAnimation {
                ingredients.remove(at: index)
                
                // Adjust the expanded index accordingly
                if expandedIngredientIndex == index {
                    expandedIngredientIndex = nil
                } else if let current = expandedIngredientIndex, current > index {
                    expandedIngredientIndex = current - 1
                }
            }
        }
        
        return ImprovedIngredientView(
            ingredient: $ingredients[index],
            isExpanded: isExpandedBinding,
            onDelete: onDelete
        )
        .environmentObject(themeManager)
    }
    
    private var addIngredientButton: some View {
        Button {
            withAnimation {
                ingredients.append(Ingredient(name: "", amount: ""))
                expandedIngredientIndex = ingredients.count - 1
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Add Ingredient")
                    .font(themeManager.bodyFont())
            }
            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(themeManager.accentColor(for: colorScheme), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .background(themeManager.accentColor(for: colorScheme).opacity(0.2))
                    )
            )
        }
    }
    
    private var uploadButton: some View {
        Button {
            uploadMealPlan()
        } label: {
            if isUploading {
                uploadingButtonContent
            } else {
                normalButtonContent
            }
        }
        .disabled(isUploading || mealName.isEmpty)
        .opacity(mealName.isEmpty ? 0.5 : 1.0)
        .padding(.top, 16)
    }
    
    private var uploadingButtonContent: some View {
        HStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .tint(Color.white)
            
            Text("Uploading...")
        }
        .font(themeManager.bodyFont(size: 16))
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(themeManager.accentColor(for: colorScheme).opacity(0.7))
        .cornerRadius(16)
        .shadow(color: themeManager.accentColor(for: colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var normalButtonContent: some View {
        Text("Upload Meal Plan")
            .font(themeManager.bodyFont(size: 16))
            .fontWeight(.semibold)
            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(themeManager.accentColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: themeManager.accentColor(for: colorScheme).opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var statusMessage: some View {
        Group {
            if !uploadStatus.isEmpty {
                Text(uploadStatus)
                    .font(themeManager.bodyFont())
                    .foregroundColor(uploadStatus.contains("Error") ? .red : .green)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Methods
    
    private func uploadMealPlan() {
        guard !mealName.isEmpty else { return }
        
        isUploading = true
        uploadStatus = "Uploading meal plan..."
        
        Task {
            do {
                try await MealPlanManager.shared.updateDailyMealPlan(
                    clientId: clientId,
                    day: day,
                    mealSlot: mealSlot,
                    mealName: mealName,
                    ingredients: ingredients,
                    image: selectedImage
                )
                
                await MainActor.run {
                    isUploading = false
                    uploadStatus = "Upload successful!"
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    uploadStatus = "Error: \(error.localizedDescription)"
                    print(uploadStatus)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
        }
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.05), radius: 8, x: 0, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(title)
            .font(themeManager.headingFont(size: 18))
            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            .padding(.bottom, 4)
    }
}

struct EnhancedTextField: View {
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
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    .padding(.horizontal, 16)
            }
            
            TextField("", text: $text)
                .font(themeManager.bodyFont())
                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(textFieldBackground)
                .overlay(textFieldBorder)
                .focused($isFocused)
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.easeInOut(duration: 0.2), value: text)
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(themeManager.cardBackgroundColor(for: colorScheme))
            .shadow(color: Color.black.opacity(isFocused ? 0.1 : 0.05), radius: isFocused ? 4 : 2, x: 0, y: 1)
    }
    
    private var textFieldBorder: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(
                isFocused ?
                    themeManager.accentColor(for: colorScheme) :
                    themeManager.textColor(for: colorScheme).opacity(0.2),
                lineWidth: isFocused ? 2 : 1
            )
    }
}

struct ImprovedIngredientView: View {
    @Binding var ingredient: Ingredient
    @Binding var isExpanded: Bool
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with name and controls
            HStack {
                TextField("Ingredient Name", text: $ingredient.name)
                    .font(themeManager.bodyFont())
                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    .padding(.vertical, 8)
                
                Spacer()
                
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding(8)
                        .background(Circle().fill((themeManager.accentOrWhiteText(for: colorScheme))))
                        .overlay(Circle().stroke(Color.red.opacity(0.3), lineWidth: 1))
                }
                
                // Expand/collapse button
                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        .font(.system(size: 22))
                }
            }
            
            // Expanded details
            if isExpanded {
                expandedContent
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(), value: isExpanded)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(themeManager.accentColor(for: colorScheme).opacity(0.3))
            
            TextField("Amount (grams)", text: $ingredient.amount)
                .font(themeManager.bodyFont())
                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                .padding(.vertical, 8)
                .keyboardType(.numberPad)
        }
        .padding(.top, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
