import SwiftUI
import PhotosUI

struct AddUpdateView: View {
    @EnvironmentObject var authManager: AuthManager
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
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Update Info Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Info")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            
                            ModernTextField(placeholder: "Name", text: $updateName)
                            ModernTextField(placeholder: "Weight (KG)", text: $weightText, keyboardType: .decimalPad)
                        }
                        
                        // Weekly Reflection Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weekly Reflection")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            
                            Text("What was your biggest win of the week?")
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            TextEditor(text: $biggestWin)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color("SecondaryAccent").opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            
                            Text("Have you had any issues?")
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            TextEditor(text: $issues)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color("SecondaryAccent").opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            
                            Text("Did you require anything extra from me as a coach?")
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            TextEditor(text: $extraCoachRequest)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color("SecondaryAccent").opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Ratings")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
                                .padding(.horizontal)
                            
                            // Calories Rating (1-7)
                            HStack {
                                Text("Calories")
                                    .foregroundColor(Color("SecondaryAccent"))
                                Spacer()
                                Picker("Calories", selection: $caloriesRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(Color("SecondaryAccent"))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("SecondaryAccent"))
                            }
                            .padding(.horizontal)
                            
                            // Steps Rating (1-7)
                            HStack {
                                Text("Steps")
                                    .foregroundColor(Color("SecondaryAccent"))
                                Spacer()
                                Picker("Steps", selection: $stepsRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(Color("SecondaryAccent"))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("SecondaryAccent"))
                            }
                            .padding(.horizontal)
                            
                            // Protein Rating (1-7)
                            HStack {
                                Text("Protein")
                                    .foregroundColor(Color("SecondaryAccent"))
                                Spacer()
                                Picker("Protein", selection: $proteinRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(Color("SecondaryAccent"))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("SecondaryAccent"))
                            }
                            .padding(.horizontal)
                            
                            // Training Rating (1-5)
                            HStack {
                                Text("Training")
                                    .foregroundColor(Color("SecondaryAccent"))
                                Spacer()
                                Picker("Training", selection: $trainingRating) {
                                    ForEach(1...5, id: \.self) { value in
                                        Text("\(value)")
                                            .foregroundColor(Color("SecondaryAccent"))
                                            .tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color("SecondaryAccent"))
                            }
                            .padding(.horizontal)
                            
                            // Display the computed final score
                            HStack {
                                Text("Final Score:")
                                    .foregroundColor(Color("SecondaryAccent"))
                                Spacer()
                                Text(String(format: "%.1f / 10", finalScore))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("SecondaryAccent"))
                            }
                            .padding(.horizontal)
                        }

                        
                        // Photo Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(Color("SecondaryAccent"))
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
            .navigationTitle("Add Update")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color("Accent"))
                    } else {
                        Button("Submit") {
                            submitUpdate()
                        }
                        .foregroundColor(Color("Accent"))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("Accent"))
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
        AddUpdateView()
            .environmentObject(AuthManager.shared)
    }
}
