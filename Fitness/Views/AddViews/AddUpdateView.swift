import SwiftUI
import PhotosUI

struct AddUpdateView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var updateName = ""
    @State private var weightText = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // New state variables for the questions
    @State private var biggestWin = ""
    @State private var issues = ""
    @State private var extraCoachRequest = ""
    
    // New state variables for the ratings
    @State private var caloriesRating: Int = 1  // Out of 7
    @State private var stepsRating: Int = 1     // Out of 7
    @State private var proteinRating: Int = 1   // Out of 7
    @State private var trainingRating: Int = 1  // Out of 5
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    // Helper functions to map the ratings
    private func mapSevenRating(_ rating: Int) -> Double {
        switch rating {
        case 1: return 0.4
        case 2: return 0.7
        case 3: return 1.1
        case 4: return 1.4
        case 5: return 1.8
        case 6: return 2.1
        case 7: return 2.5
        default: return 0.0
        }
    }
    
    private func mapFiveRating(_ rating: Int) -> Double {
        return Double(rating) * 0.5
    }
    
    // Computed final score out of 10
    private var finalScore: Double {
        let caloriesScore = mapSevenRating(caloriesRating)
        let stepsScore = mapSevenRating(stepsRating)
        let proteinScore = mapSevenRating(proteinRating)
        let trainingScore = mapFiveRating(trainingRating)
        return caloriesScore + stepsScore + proteinScore + trainingScore
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Update Info Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Info")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            ModernTextField(placeholder: "Name", text: $updateName)
                                .environmentObject(themeManager)
                            ModernTextField(placeholder: "Weight (KG)", text: $weightText, keyboardType: .decimalPad)
                                .environmentObject(themeManager)
                        }
                        
                        // Weekly Reflection Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Reflection")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            Text("What was your biggest win of the week?")
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            ZStack {
                                themeManager.cardBackgroundColor(for: colorScheme)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                                    )
                                
                                TextEditor(text: $biggestWin)
                                    .scrollContentBackground(.hidden) // This is key - hides the default background
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                            
                            Text("Have you had any issues?")
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            ZStack {
                                themeManager.cardBackgroundColor(for: colorScheme)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                                    )
                                
                                TextEditor(text: $issues)
                                    .scrollContentBackground(.hidden) // This is key - hides the default background
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                            
                            Text("Did you require anything extra from me as a coach?")
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            ZStack {
                                themeManager.cardBackgroundColor(for: colorScheme)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                                    )
                                
                                TextEditor(text: $extraCoachRequest)
                                    .scrollContentBackground(.hidden) // This is key - hides the default background
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Ratings")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            // Calories Rating (1-7)
                            HStack {
                                Text("Calories")
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Calories", selection: $caloriesRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(themeManager.textColor(for: colorScheme))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                            
                            // Steps Rating (1-7)
                            HStack {
                                Text("Steps")
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Steps", selection: $stepsRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(themeManager.textColor(for: colorScheme))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                            
                            // Protein Rating (1-7)
                            HStack {
                                Text("Protein")
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Protein", selection: $proteinRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(themeManager.textColor(for: colorScheme))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                            
                            // Training Rating (1-5)
                            HStack {
                                Text("Training")
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Training", selection: $trainingRating) {
                                    ForEach(1...5, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(themeManager.textColor(for: colorScheme))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                            
                            // Display the computed final score
                            HStack {
                                Text("Final Score:")
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Text(String(format: "%.1f / 10", finalScore))
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                        }

                        
                        // Photo Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                } else {
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
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        selectedImage = image
                                    }
                                }
                            }
                        }
                        
                        // Display error message if needed
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") {
                            submitUpdate()
                        }
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                }
            }
        }
    }
    
    private func submitUpdate() {
        guard !updateName.isEmpty,
              let weight = Double(weightText) else {
            errorMessage = "Please fill all fields correctly."
            return
        }
        
        isSubmitting = true
        Task {
            do {
                // Note: You'll need to update the addUpdate method in AuthManager to accept finalScore.
                try await authManager.addUpdate(
                    name: updateName,
                    weight: weight,
                    image: selectedImage,
                    biggestWin: biggestWin,
                    issues: issues,
                    extraCoachRequest: extraCoachRequest,
                    finalScore: finalScore
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

struct AddUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddUpdateView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
            
            AddUpdateView()
                .environmentObject(AuthManager.shared)
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
        }
    }
}
