import SwiftUI
import PhotosUI

struct AccountSettings: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingProfileImagePicker = false
    @State private var selectedProfileItem: PhotosPickerItem?
    
    // Add state variables for first and last name
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving = false
    @State private var showSuccessMessage = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            Form {
                Section(header: Text("Profile Picture")
                            .font(themeManager.headingFont(size: 16))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            .fontWeight(.bold)) {
                    HStack {
                        if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                           let url = URL(string: profileImageUrl) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                                } else if phase.error != nil {
                                    // Use a system placeholder if there's an error.
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                                } else {
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                }
                            }
                        } else {
                            // Fallback to a placeholder system image.
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                        }
                        Button("Change Picture") {
                            showingProfileImagePicker = true
                        }
                        .font(themeManager.bodyFont())
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                
                // Add section for name editing
                Section(header: Text("Personal Information")
                            .font(themeManager.headingFont(size: 16))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            .fontWeight(.bold)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(themeManager.captionFont())
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        
                        TextField("", text: $firstName)
                            .font(themeManager.bodyFont())
                            .padding(10)
                            .background(themeManager.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                            )
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(themeManager.captionFont())
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                        
                        TextField("", text: $lastName)
                            .font(themeManager.bodyFont())
                            .padding(10)
                            .background(themeManager.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "C6C6C6"), lineWidth: 1)
                            )
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(themeManager.captionFont())
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                    
                    if showSuccessMessage {
                        Text("Your information has been updated!")
                            .font(themeManager.captionFont())
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    }
                    
                    // Save button
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Save Changes")
                                .font(themeManager.bodyFont())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.accentColor(for: colorScheme))
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isSaving || (firstName.isEmpty || lastName.isEmpty))
                    .opacity((firstName.isEmpty || lastName.isEmpty) ? 0.5 : 1.0)
                }
                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                
                Section {
                    Button("Delete Account") {
                        // TODO: Implement account deletion functionality.
                    }
                    .font(themeManager.bodyFont())
                    .foregroundColor(.red)
                }
                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
            }
            .scrollContentBackground(.hidden)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ModernBackButton()
                    .environmentObject(themeManager)
            }
        }
        .navigationTitle("")
        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .photosPicker(isPresented: $showingProfileImagePicker, selection: $selectedProfileItem, matching: .images)
        .onChange(of: selectedProfileItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Update the profile picture in Firebase.
                    try await authManager.updateProfilePicture(image: image)
                }
            }
        }
        .onAppear {
            // Initialize fields with current user data
            if let user = authManager.currentUser {
                firstName = user.firstName
                lastName = user.lastName
            }
        }
    }
    
    // Function to save name changes
    private func saveChanges() {
        // Validate input
        guard !firstName.isEmpty && !lastName.isEmpty else {
            errorMessage = "Please enter both first and last name"
            return
        }
        
        // Reset messages
        errorMessage = nil
        showSuccessMessage = false
        isSaving = true
        
        Task {
            do {
                try await authManager.updateUserName(firstName: firstName, lastName: lastName)
                
                await MainActor.run {
                    isSaving = false
                    showSuccessMessage = true
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSuccessMessage = false
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update: \(error.localizedDescription)"
                }
            }
        }
    }
}
