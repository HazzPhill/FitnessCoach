import SwiftUI
import PhotosUI

struct DailyCheckinView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: DailyCheckinsViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var notes = ""
    @State private var completedGoals: [CompletedGoal] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: DailyCheckinsViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Daily Goals")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))) {
                        if viewModel.goalsList.isEmpty {
                            Text("No goals set. Add goals in your profile settings.")
                                .font(themeManager.bodyFont())
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                        } else {
                            // Use VStack for custom toggles since they won't work directly in Form
                            VStack(spacing: 12) {
                                ForEach(viewModel.goalsList) { goal in
                                    PulseToggle(
                                        label: getGoalDisplayText(goal),
                                        isOn: Binding(
                                            get: {
                                                completedGoals.first(where: { $0.goalId == goal.id })?.completed ?? false
                                            },
                                            set: { newValue in
                                                if let index = completedGoals.firstIndex(where: { $0.goalId == goal.id }) {
                                                    completedGoals[index].completed = newValue
                                                } else {
                                                    // Use the formatted display name including the value
                                                    completedGoals.append(CompletedGoal(
                                                        goalId: goal.id,
                                                        name: getGoalDisplayText(goal),
                                                        completed: newValue
                                                    ))
                                                }
                                            }
                                        ),
                                        accentColor: themeManager.accentColor(for: colorScheme),
                                        textColor: themeManager.textColor(for: colorScheme),
                                        font: themeManager.bodyFont()
                                    )
                                }
                                
                                // Water intake toggle
                                PulseToggle(
                                    label: "Drank 3L water",
                                    isOn: Binding(
                                        get: {
                                            completedGoals.first(where: { $0.goalId == "water" })?.completed ?? false
                                        },
                                        set: { newValue in
                                            if let index = completedGoals.firstIndex(where: { $0.goalId == "water" }) {
                                                completedGoals[index].completed = newValue
                                            } else {
                                                completedGoals.append(CompletedGoal(
                                                    goalId: "water",
                                                    name: "Drank 3L water",
                                                    completed: newValue
                                                ))
                                            }
                                        }
                                    ),
                                    accentColor: themeManager.accentColor(for: colorScheme),
                                    textColor: themeManager.textColor(for: colorScheme),
                                    font: themeManager.bodyFont()
                                )
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    Section(header: Text("Notes")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))) {
                        TextEditor(text: $notes)
                            .font(themeManager.bodyFont())
                            .frame(minHeight: 100)
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    Section(header: Text("Photos (Required)")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))) {
                        
                        if selectedImages.isEmpty {
                            // Visual indicator that photos are required
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.red)
                                Text("At least one photo is required")
                                    .font(themeManager.bodyFont(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        PhotosPicker(selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
                            Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                                .font(themeManager.bodyFont())
                                .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        }
                        
                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(0..<selectedImages.count, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                            Button {
                                                selectedImages.remove(at: index)
                                                if index < selectedItems.count {
                                                    selectedItems.remove(at: index)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Circle().fill(Color.white))
                                            }
                                            .offset(x: 6, y: -6)
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .frame(height: 120)
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .font(themeManager.bodyFont())
                                .foregroundColor(.red)
                        }
                        .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") {
                            submitCheckin()
                        }
                        // Disable the button if goals list is empty OR no photos uploaded
                        .disabled(viewModel.goalsList.isEmpty || selectedImages.isEmpty)
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                        .opacity(selectedImages.isEmpty ? 0.5 : 1.0) // Visual indicator
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
            .onChange(of: selectedItems) { newValue in
                loadSelectedImages(from: newValue)
            }
            .onAppear {
                // Pre-populate completed goals list with all goals (initially not completed)
                if completedGoals.isEmpty && !viewModel.goalsList.isEmpty {
                    completedGoals = viewModel.goalsList.map { goal in
                        CompletedGoal(
                            goalId: goal.id,
                            name: getGoalDisplayText(goal),
                            completed: false
                        )
                    }
                    
                    // Add the water goal to the list if it doesn't exist
                    if !completedGoals.contains(where: { $0.goalId == "water" }) {
                        completedGoals.append(CompletedGoal(
                            goalId: "water",
                            name: "Drank 3L water",
                            completed: false
                        ))
                    }
                }
            }
        }
    }
    
    // Helper function to format the goal display text with the value
    private func getGoalDisplayText(_ goal: GoalItem) -> String {
        return "\(goal.name) (\(goal.value))"
    }
    
    private func loadSelectedImages(from items: [PhotosPickerItem]) {
        Task {
            var newImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    newImages.append(image)
                }
            }
            
            DispatchQueue.main.async {
                selectedImages = newImages
            }
        }
    }
    
    private func submitCheckin() {
        // Make sure we have goals to check off
        if viewModel.goalsList.isEmpty {
            errorMessage = "No goals available to check off."
            return
        }
        
        // Make sure at least one photo is included
        if selectedImages.isEmpty {
            errorMessage = "At least one photo is required."
            return
        }
        
        // Ensure all goals have been included
        for goal in viewModel.goalsList {
            if !completedGoals.contains(where: { $0.goalId == goal.id }) {
                completedGoals.append(CompletedGoal(
                    goalId: goal.id,
                    name: getGoalDisplayText(goal),
                    completed: false
                ))
            }
        }
        
        // Make sure the water goal is included
        if !completedGoals.contains(where: { $0.goalId == "water" }) {
            completedGoals.append(CompletedGoal(
                goalId: "water",
                name: "Drank 3L water",
                completed: false
            ))
        }
        
        isSubmitting = true
        Task {
            do {
                try await viewModel.addCheckin(
                    notes: notes,
                    completedGoals: completedGoals,
                    images: selectedImages
                )
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}
