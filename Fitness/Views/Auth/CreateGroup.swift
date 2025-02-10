import SwiftUI
import PhotosUI

struct CreateGroup: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var groupName = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .center){
                Color("SecondaryAccent")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        imageUploadSection
                        groupNameField
                        createButton
                    }
                    .padding()
                }
            }
            .navigationBarBackButtonHidden()
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        VStack {
            Text("Create Your Group")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
            
            Text("Setup your training community")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
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
            strokeColor: .white,
            textColor: .white,
            labelColor: .white.opacity(0.9),
            cornerRadius: 10,
            lineWidth: 1,
            iconName: "person.3.fill"
        )
    }
    
    private var createButton: some View {
        Button(action: createGroup) {
            Text("Create Group")
                .font(.headline)
                .foregroundColor(Color("Accent"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(Capsule())
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
    }
}
