import SwiftUI
import PhotosUI

struct AccountSettings: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingProfileImagePicker = false
    @State private var selectedProfileItem: PhotosPickerItem?
    
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
    }
}
