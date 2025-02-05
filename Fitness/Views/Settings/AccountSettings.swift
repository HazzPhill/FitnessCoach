import SwiftUI
import PhotosUI

struct AccountSettings: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingProfileImagePicker = false
    @State private var selectedProfileItem: PhotosPickerItem?
    
    var body: some View {
        Form {
            Section(header: Text("Profile Picture")
                        .foregroundColor(Color("Accent"))
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
                                    .overlay(Circle().stroke(Color("Accent"), lineWidth: 2))
                            } else if phase.error != nil {
                                // Use a system placeholder if there's an error.
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color("Accent"), lineWidth: 2))
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
                            .overlay(Circle().stroke(Color("Accent"), lineWidth: 2))
                    }
                    Button("Change Picture") {
                        showingProfileImagePicker = true
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section {
                Button("Delete Account") {
                    // TODO: Implement account deletion functionality.
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Account Settings")
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
    }
}

struct AccountSettings_Previews: PreviewProvider {
    static var previews: some View {
        AccountSettings()
            .environmentObject(AuthManager.shared)
    }
}
