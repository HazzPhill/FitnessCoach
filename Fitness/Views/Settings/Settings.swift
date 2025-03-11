import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: For coaches: Group settings state
    @State private var groupName: String = ""
    @State private var showingGroupImagePicker = false
    @State private var selectedGroupItem: PhotosPickerItem?
    @State private var groupImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Latest Weight view (only for clients)
                    if authManager.currentUser?.role == .client {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(themeManager.accentColor(for: colorScheme))
                                .frame(height: 60)
                            if let latestWeight = authManager.latestUpdates.first?.weight {
                                Text("\(latestWeight, specifier: "%.1f") KG")
                                    .foregroundColor(.white)
                                    .font(.system(size: 40))
                            } else {
                                Text("No weight recorded")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Form
                    Form {
                        // MARK: Navigation Links Section
                        Section {
                            NavigationLink("Account Settings", destination: AccountSettings()
                                .environmentObject(themeManager))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            NavigationLink("Security", destination: SecuritySettings()
                                .environmentObject(themeManager))
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        }
                        .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                        
                        // MARK: Customization Section
                        Section(header: Text("Customisation")
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                    .fontWeight(.bold)) {
                            
                                        AnimatedThemePicker(selectedTheme: $themeManager.selectedTheme, themeManager: themeManager)
                                            .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                                            .padding(.vertical)
                            
                            // Color scheme selection
                            NavigationLink(destination: ColorSchemeSelectionView()
                                .environmentObject(themeManager)) {
                                HStack {
                                    Text("Color Scheme")
                                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                    Spacer()
                                    
                                    // Preview of current scheme
                                    HStack(spacing: 4) {
                                        // Background preview
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(themeManager.backgroundColor(for: colorScheme))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        
                                        // Accent preview
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(themeManager.accentColor(for: colorScheme))
                                            .frame(width: 20, height: 20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                    }
                                    .padding(.trailing, 4)
                                    
                                    Text(themeManager.activeColorScheme(for: colorScheme).displayName)
                                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                }
                            }
                            .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                        }
                        
                        // MARK: Group Settings (Coach Only)
                        if authManager.currentUser?.role == .coach {
                            Section(header: Text("Group Settings")
                                        .foregroundColor(themeManager.accentColor(for: colorScheme))
                                        .fontWeight(.bold)) {
                                TextField("Group Name", text: $groupName)
                                    .onAppear {
                                        groupName = authManager.currentGroup?.name ?? ""
                                    }
                                    .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                                
                                HStack(spacing: 16) {
                                    // Display the group photo:
                                    if let groupImage = groupImage {
                                        Image(uiImage: groupImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                                    } else if let groupImageUrl = authManager.currentGroup?.groupImageUrl,
                                              let url = URL(string: groupImageUrl) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else if phase.error != nil {
                                                Image("defaultGroup")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            } else {
                                                ProgressView()
                                            }
                                        }
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                                    } else {
                                        Image("defaultGroup")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(themeManager.accentColor(for: colorScheme), lineWidth: 2))
                                    }
                                    
                                    Button("Change Group Photo") {
                                        showingGroupImagePicker = true
                                    }
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                                }
                                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                                
                                Button("Show Share Code") {
                                    if let code = authManager.currentGroup?.code {
                                        let activityVC = UIActivityViewController(activityItems: [code], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }
                                }
                                .foregroundColor(themeManager.accentColor(for: colorScheme))
                                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                            }
                        }
                        
                        // MARK: Account Actions Section
                        Section {
                            Button("Log Out") {
                                do {
                                    try authManager.signOut()
                                } catch {
                                    print("Error logging out: \(error.localizedDescription)")
                                }
                            }
                            .foregroundColor(.red)
                        }
                        .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("")
            // MARK: Group image picker (for coaches)
            .photosPicker(isPresented: $showingGroupImagePicker, selection: $selectedGroupItem, matching: .images)
            .onChange(of: selectedGroupItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        self.groupImage = image
                        try await authManager.updateGroupPhoto(image: image)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
