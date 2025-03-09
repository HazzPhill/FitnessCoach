import SwiftUI
import PhotosUI

struct EditUpdateView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    let update: AuthManager.Update
    
    @State private var updateName: String
    @State private var weightText: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var keepExistingImage: Bool = true
    
    // Reflection fields
    @State private var biggestWin: String
    @State private var issues: String
    @State private var extraCoachRequest: String
    
    // Ratings fields
    @State private var caloriesRating: Int
    @State private var stepsRating: Int
    @State private var proteinRating: Int
    @State private var trainingRating: Int
    
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    
    // Initialize with the existing update data
    init(update: AuthManager.Update) {
        self.update = update
        _updateName = State(initialValue: update.name)
        _weightText = State(initialValue: String(format: "%.1f", update.weight))
        _biggestWin = State(initialValue: update.biggestWin ?? "")
        _issues = State(initialValue: update.issues ?? "")
        _extraCoachRequest = State(initialValue: update.extraCoachRequest ?? "")
        
        // Initialize ratings with existing values or defaults
        _caloriesRating = State(initialValue: Int(update.caloriesScore ?? 0))
        _stepsRating = State(initialValue: Int(update.stepsScore ?? 0))
        _proteinRating = State(initialValue: Int(update.proteinScore ?? 0))
        _trainingRating = State(initialValue: Int(update.trainingScore ?? 0))
    }
    
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
                            
                            if update.imageUrl != nil {
                                Toggle("Keep existing photo", isOn: $keepExistingImage)
                                    .padding(.horizontal)
                                    .foregroundColor(Color("SecondaryAccent"))
                            }
                            
                            if !keepExistingImage || update.imageUrl == nil {
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
                            } else if let imageUrl = update.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 200)
                                            .padding(.horizontal)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 200)
                                            .clipped()
                                            .cornerRadius(8)
                                            .padding(.horizontal)
                                    case .failure:
                                        Text("Failed to load image")
                                            .foregroundColor(.red)
                                            .padding(.horizontal)
                                    @unknown default:
                                        EmptyView()
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
                        
                        // Delete button at the bottom
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Check-in")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color("Warning"))
                                .cornerRadius(25)
                                .padding(.horizontal)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Edit Check-in")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color("Accent"))
                    } else {
                        Button("Save") {
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
            .alert("Delete Check-in", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteUpdate()
                }
            } message: {
                Text("Are you sure you want to delete this check-in? This action cannot be undone.")
            }
        }
    }
    
    private func submitUpdate() {
        guard !updateName.isEmpty,
              let weight = Double(weightText) else {
            errorMessage = "Please fill all fields correctly."
            return
        }
        
        guard let updateId = update.id else {
            errorMessage = "Invalid update ID"
            return
        }
        
        isSubmitting = true
        Task {
            do {
                // Determine which image to use
                var imageToUse: UIImage? = nil
                var existingImageUrl: String? = nil
                
                if keepExistingImage && update.imageUrl != nil {
                    existingImageUrl = update.imageUrl
                } else {
                    imageToUse = selectedImage
                }
                
                try await authManager.updateUpdate(
                    updateId: updateId,
                    name: updateName,
                    weight: weight,
                    newImage: imageToUse,
                    existingImageUrl: existingImageUrl,
                    biggestWin: biggestWin,
                    issues: issues,
                    extraCoachRequest: extraCoachRequest,
                    caloriesScore: Double(caloriesRating),
                    stepsScore: Double(stepsRating),
                    proteinScore: Double(proteinRating),
                    trainingScore: Double(trainingRating),
                    finalScore: finalScore
                )
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
    
    private func deleteUpdate() {
        guard let updateId = update.id else {
            errorMessage = "Invalid update ID"
            return
        }
        
        isSubmitting = true
        Task {
            do {
                try await authManager.deleteUpdate(updateId: updateId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete update: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
}
