import SwiftUI
import PhotosUI

struct DailyCheckinView: View {
    @EnvironmentObject var authManager: AuthManager
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
            Form {
                Section(header: Text("Daily Goals")) {
                    if viewModel.goalsList.isEmpty {
                        Text("No goals set. Add goals in your profile settings.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.goalsList) { goal in
                            Toggle(getGoalDisplayText(goal), isOn: Binding(
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
                            ))
                            .tint(Color("Accent"))
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Photos")) {
                    PhotosPicker(selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
                        Label("Select Photos", systemImage: "photo.on.rectangle.angled")
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
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Daily Check-in")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Submit") {
                            submitCheckin()
                        }
                        .disabled(viewModel.goalsList.isEmpty)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
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

#Preview {
    DailyCheckinView(userId: "dummyUserId")
        .environmentObject(AuthManager.shared)
}
