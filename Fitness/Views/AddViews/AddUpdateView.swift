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
                                    .scrollContentBackground(.hidden)
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
                        
                        // Performance Ratings Section
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
                        }
                        
                        // Display error message if needed
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(themeManager.bodyFont())
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
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(themeManager.bodyFont())
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
        
        // Calculate mapped scores from raw ratings
        let caloriesScore = mapSevenRating(caloriesRating)
        let stepsScore = mapSevenRating(stepsRating)
        let proteinScore = mapSevenRating(proteinRating)
        let trainingScore = mapFiveRating(trainingRating)
        let finalScore = caloriesScore + stepsScore + proteinScore + trainingScore
        
        isSubmitting = true
        Task {
            do {
                try await authManager.addUpdate(
                    name: updateName,
                    weight: weight,
                    image: selectedImage,
                    biggestWin: biggestWin,
                    issues: issues,
                    extraCoachRequest: extraCoachRequest,
                    caloriesRating: caloriesRating,    // Raw value from dropdown
                    stepsRating: stepsRating,          // Raw value from dropdown
                    proteinRating: proteinRating,      // Raw value from dropdown
                    trainingRating: trainingRating,    // Raw value from dropdown
                    caloriesScore: caloriesScore,      // Mapped value
                    stepsScore: stepsScore,            // Mapped value
                    proteinScore: proteinScore,        // Mapped value
                    trainingScore: trainingScore,      // Mapped value
                    finalScore: finalScore             // Calculated total
                )
                
                authManager.refreshWeeklyUpdates()
                NotificationCenter.default.post(name: .weeklyCheckInStatusChanged, object: nil)
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds delay
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
