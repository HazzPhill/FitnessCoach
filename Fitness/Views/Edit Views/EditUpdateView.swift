import SwiftUI
import PhotosUI

struct EditUpdateView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
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
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Update Info Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Info")
                                .font(themeManager.headingFont(size: 18))
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
                                .font(themeManager.headingFont(size: 18))
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            Text("What was your biggest win of the week?")
                                .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .scrollContentBackground(.hidden) // This is key - hides the default background
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                            
                            Text("Have you had any issues?")
                                .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                            
                            Text("Did you require anything extra from me as a coach?")
                                .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                            .frame(height: 100)
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Performance Ratings")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            // Calories Rating (1-7)
                            HStack {
                                Text("Calories")
                                    .font(themeManager.bodyFont())
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Calories", selection: $caloriesRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Steps", selection: $stepsRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Protein", selection: $proteinRating) {
                                    ForEach(1...7, id: \.self) { value in
                                        Text("\(value)")
                                            .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Picker("Training", selection: $trainingRating) {
                                    ForEach(1...5, id: \.self) { value in
                                        Text("\(value)")
                                            .font(themeManager.bodyFont())
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
                                    .font(themeManager.bodyFont())
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                Spacer()
                                Text(String(format: "%.1f / 10", finalScore))
                                    .font(themeManager.bodyFont())
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                            .padding(.horizontal)
                        }

                        
                        // Photo Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(themeManager.headingFont(size: 18))
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                .padding(.horizontal)
                            
                            if update.imageUrl != nil {
                                Toggle("Keep existing photo", isOn: $keepExistingImage)
                                    .font(themeManager.bodyFont())
                                    .padding(.horizontal)
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
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
                                            .font(themeManager.bodyFont())
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
                                            .font(themeManager.bodyFont())
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
                                .font(themeManager.bodyFont())
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Delete button at the bottom
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete Check-in")
                                .font(themeManager.bodyFont(size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(25)
                                .padding(.horizontal)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    .padding(.top)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(themeManager.accentColor(for: colorScheme))
                    } else {
                        Button("Save") {
                            submitUpdate()
                        }
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
                
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
