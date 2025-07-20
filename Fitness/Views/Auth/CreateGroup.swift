import SwiftUI
import PhotosUI

struct CreateGroup: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var groupName = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showError = false
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .center) {
                
                Image("gym_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .allowsHitTesting(false)
                
                    VStack(spacing: 30) {
                        headerSection
                        imageUploadSection
                        groupNameField
                        createButton
                        
                        if showError {
                            Text(authManager.errorMessage ?? "An error occurred")
                                .font(themeManager.bodyFont(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding()
                    .glassEffect(.regular,in: RoundedRectangle(cornerRadius: 30))
                    .padding()
                
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Custom back button that shows sign out confirmation
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(themeManager.bodyFont(size: 16))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .glassEffect(.regular.interactive())
                    }
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authManager.signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Your Group")
                .font(themeManager.headingFont(size: 28))
                
            
            Text("Setup your training community")
                .font(themeManager.bodyFont())
                
        }
    }
    
    private var imageUploadSection: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(30)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(width: 200, height: 200)
            .background(Color("Accent"))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
    
    private var groupNameField: some View {
        StrokedTextField(
            text: $groupName,
            label: "Group Name",
            placeholder: "Elite Fitness Squad",
            strokeColor: .primary,
            textColor: .primary,
            labelColor: .primary,
            cornerRadius: 10,
            lineWidth: 1,
            iconName: "person.3.fill"
        )
    }
    
    private var createButton: some View {
        Button(action: createGroup) {
            if authManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .glassEffect(.regular.tint(Color(hex: "002E37")))
            } else {
                Text("Create Group")
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .glassEffect(.regular.interactive().tint(Color(hex: "002E37")))
            }
        }
        .disabled(groupName.isEmpty || authManager.isLoading)
        .opacity(groupName.isEmpty ? 0.6 : 1)
    }
    
    // MARK: - Actions
    private func createGroup() {
        guard !groupName.isEmpty else { return }
        
        Task {
            do {
                try await authManager.createGroup(name: groupName)
                if let image = selectedImage {
                    try await authManager.updateGroupPhoto(image: image)
                }
            } catch {
                showError = true
                authManager.errorMessage = error.localizedDescription
            }
        }
    }
}

struct CreateGroup_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroup()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
