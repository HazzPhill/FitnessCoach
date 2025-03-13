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
                                    .font(themeManager.titleFont(size: 40))
                            } else {
                                Text("No weight recorded")
                                    .foregroundColor(.white)
                                    .font(themeManager.bodyFont(size: 18))
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
                            .font(themeManager.bodyFont())
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            
                            NavigationLink("Security", destination: SecuritySettings()
                                .environmentObject(themeManager))
                            .font(themeManager.bodyFont())
                            .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        }
                        .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                        
                        // MARK: Customization Section
                        Section(header: Text("Customisation")
                            .font(themeManager.headingFont(size: 16))
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
                                        .font(themeManager.bodyFont())
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
                                        .font(themeManager.captionFont())
                                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                }
                            }
                            .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                        }
                        
                        // MARK: Group Settings (Coach Only)
                        if authManager.currentUser?.role == .coach {
                            Section(header: Text("Group Settings")
                                .font(themeManager.headingFont(size: 16))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                .fontWeight(.bold)) {
                                
                                TextField("Group Name", text: $groupName)
                                    .font(themeManager.bodyFont())
                                    .onAppear {
                                        groupName = authManager.currentGroup?.name ?? ""
                                    }
                                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                                    .font(themeManager.bodyFont())
                                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                                }
                                .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                                
                                Button("Share Group Code") {
                                    if let code = authManager.currentGroup?.code {
                                        let shareMessage = "Come join my Coaching Group! Code: \(code)"
                                        let activityVC = UIActivityViewController(activityItems: [shareMessage], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }
                                }
                                .font(themeManager.bodyFont())
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
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
                            .font(themeManager.bodyFont())
                            .foregroundColor(.red)
                        }
                        .listRowBackground(themeManager.cardBackgroundColor(for: colorScheme))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("")
            .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
            }
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
