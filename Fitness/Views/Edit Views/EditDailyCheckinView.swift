import SwiftUI
import PhotosUI

struct EditDailyCheckinView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var viewModel: DailyCheckinsViewModel
    @Environment(\.dismiss) var dismiss
    
    let checkin: DailyCheckin
    
    @State private var notes: String
    @State private var completedGoals: [CompletedGoal]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var existingImageUrls: [String]
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    init(checkin: DailyCheckin, userId: String) {
        self.checkin = checkin
        _notes = State(initialValue: checkin.notes ?? "")
        _completedGoals = State(initialValue: checkin.completedGoals)
        _existingImageUrls = State(initialValue: checkin.imageUrls ?? [])
        _viewModel = StateObject(wrappedValue: DailyCheckinsViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    // Goals section
                    Section(header: Text("Daily Goals")
                        .font(themeManager.headingFont(size: 16))
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))) {
                        if viewModel.goalsList.isEmpty {
                            Text("No goals set. Add goals in your profile settings.")
                                .font(themeManager.bodyFont())
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                        } else {
                            VStack(spacing: 12) {
                                // Regular goals
                                ForEach(viewModel.goalsList) { goal in
                                    createGoalToggle(for: goal)
                                }
                                
                                // Water toggle
                                createWaterToggle()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    // Notes section
                    Section(header: Text("Notes")
                        .font(themeManager.headingFont(size: 16))
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))) {
                        TextEditor(text: $notes)
                            .font(themeManager.bodyFont())
                            .frame(minHeight: 100)
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                            .scrollContentBackground(.hidden)
                            .background(themeManager.cardBackgroundColor(for: colorScheme))
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    // Existing Photos section
                    Section(header: Text("Existing Photos")
                        .font(themeManager.headingFont(size: 16))
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))) {
                        if existingImageUrls.isEmpty {
                            Text("No photos")
                                .font(themeManager.bodyFont())
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                        } else {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(existingImageUrls.indices, id: \.self) { index in
                                        if let url = URL(string: existingImageUrls[index]) {
                                            ZStack(alignment: .topTrailing) {
                                                AsyncImage(url: url) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        ProgressView()
                                                            .frame(width: 100, height: 100)
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 100, height: 100)
                                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    case .failure:
                                                        Image(systemName: "photo")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 100, height: 100)
                                                            .foregroundColor(.gray)
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                                
                                                Button {
                                                    existingImageUrls.remove(at: index)
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
                            }
                            .frame(height: 120)
                        }
                    }
                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    
                    // Add New Photos section
                    Section(header: Text("Add New Photos")
                        .font(themeManager.headingFont(size: 16))
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))) {
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
                    
                    // Error message
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") {
                            updateCheckin()
                        }
                        .disabled(completedGoals.isEmpty)
                        .font(themeManager.bodyFont())
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
            
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        deleteCheckin()
                    }
                    .font(themeManager.bodyFont())
                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selectedItems) { newValue in
                loadSelectedImages(from: newValue)
            }
            .onAppear {
                ensureWaterGoalExists()
            }
        }
    }
    
    // Helper methods for creating toggles
    private func createGoalToggle(for goal: GoalItem) -> some View {
        // Check if the goal already exists in the completedGoals array
        if let goalIndex = completedGoals.firstIndex(where: { $0.goalId == goal.id }) {
            // Direct binding for existing goal
            return PulseToggle(
                label: getGoalDisplayText(goal),
                isOn: $completedGoals[goalIndex].completed,
                accentColor: themeManager.accentColor(for: colorScheme),
                textColor: themeManager.accentOrWhiteText(for: colorScheme),
                font: themeManager.bodyFont()
            )
        } else {
            // For goals added after the check-in was created
            let goalId = goal.id
            let goalName = getGoalDisplayText(goal)
            
            // Create a simplified binding that just adds the goal when toggled on
            let binding = Binding<Bool>(
                get: { false }, // Always starts as false
                set: { newValue in
                    if newValue {
                        completedGoals.append(CompletedGoal(
                            goalId: goalId,
                            name: goalName,
                            completed: true
                        ))
                    }
                }
            )
            
            return PulseToggle(
                label: goalName,
                isOn: binding,
                accentColor: themeManager.accentColor(for: colorScheme),
                textColor: themeManager.accentOrWhiteText(for: colorScheme).opacity(0.6),
                font: themeManager.bodyFont()
            )
        }
    }
    
    private func createWaterToggle() -> some View {
        // Check if water goal exists
        if let waterIndex = completedGoals.firstIndex(where: { $0.goalId == "water" }) {
            // Use direct binding for existing water goal
            return PulseToggle(
                label: "Drank 3L water",
                isOn: $completedGoals[waterIndex].completed,
                accentColor: themeManager.accentColor(for: colorScheme),
                textColor: themeManager.accentOrWhiteText(for: colorScheme),
                font: themeManager.bodyFont()
            )
        } else {
            // Create a binding for a new water goal
            let binding = Binding<Bool>(
                get: { false },
                set: { newValue in
                    if newValue {
                        completedGoals.append(CompletedGoal(
                            goalId: "water",
                            name: "Drank 3L water",
                            completed: true
                        ))
                    }
                }
            )
            
            return PulseToggle(
                label: "Drank 3L water",
                isOn: binding,
                accentColor: themeManager.accentColor(for: colorScheme),
                textColor: themeManager.accentOrWhiteText(for: colorScheme),
                font: themeManager.bodyFont()
            )
        }
    }
    
    private func ensureWaterGoalExists() {
        // Make sure the water goal exists
        if !completedGoals.contains(where: { $0.goalId == "water" }) {
            completedGoals.append(CompletedGoal(
                goalId: "water",
                name: "Drank 3L water",
                completed: false
            ))
        }
    }
    
    // Helper function to format goal display text with value
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
    
    private func updateCheckin() {
        guard !completedGoals.isEmpty else {
            errorMessage = "Please mark at least one goal as completed or not completed."
            return
        }
        
        guard let checkinId = checkin.id else {
            errorMessage = "Invalid check-in ID"
            return
        }
        
        // Make sure the water goal is included
        ensureWaterGoalExists()
        
        isSubmitting = true
        Task {
            do {
                // First update the check-in using the view model
                try await viewModel.updateCheckin(
                    checkinId: checkinId,
                    notes: notes,
                    completedGoals: completedGoals,
                    existingImageUrls: existingImageUrls,
                    newImages: selectedImages
                )
                
                // Then force a refresh in the AuthManager
                await MainActor.run {
                    // This is the key part - force refresh after update
                    authManager.refreshDailyCheckins()
                    
                    // Add some delay to ensure Firebase has time to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
    
    private func deleteCheckin() {
        guard let checkinId = checkin.id else {
            errorMessage = "Invalid check-in ID"
            return
        }
        
        // Check if this is the last check-in
        let isLastCheckin = authManager.dailyCheckins.count == 1
        
        Task {
            do {
                try await viewModel.deleteCheckin(checkinId: checkinId)
                
                await MainActor.run {
                    // For the last check-in, manually clear the array
                    if isLastCheckin {
                        withAnimation {
                            authManager.dailyCheckins = []
                        }
                        // Print for debugging
                        print("Manually cleared dailyCheckins array after deleting last item")
                    }
                    
                    // Force a refresh (this may not work for empty collections)
                    authManager.refreshDailyCheckins()
                    
                    // Add some delay to ensure Firebase has time to update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to delete check-in: \(error.localizedDescription)"
                }
            }
        }
    }
}
