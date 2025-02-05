import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: For coaches: Group settings state
    @State private var groupName: String = ""
    @State private var showingGroupImagePicker = false
    @State private var selectedGroupItem: PhotosPickerItem?
    @State private var groupImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Latest Weight view (only for clients)
                    if authManager.currentUser?.role == .client {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(Color("Accent"))
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
                            NavigationLink("Account Settings", destination: AccountSettings())
                            NavigationLink("Security", destination: SecuritySettings())
                        }
                        .listRowBackground(Color.white)
                        
                        // MARK: Group Settings (Coach Only)
                        if authManager.currentUser?.role == .coach {
                            Section(header: Text("Group Settings")
                                        .foregroundColor(Color("Accent"))
                                        .fontWeight(.bold)) {
                                TextField("Group Name", text: $groupName)
                                    .onAppear {
                                        groupName = authManager.currentGroup?.name ?? ""
                                    }
                                    .listRowBackground(Color.white)
                                
                                HStack(spacing: 16) {
                                    // Display the group photo:
                                    if let groupImage = groupImage {
                                        Image(uiImage: groupImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Accent"), lineWidth: 2))
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
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Accent"), lineWidth: 2))
                                    } else {
                                        Image("defaultGroup")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("Accent"), lineWidth: 2))
                                    }
                                    
                                    Button("Change Group Photo") {
                                        showingGroupImagePicker = true
                                    }
                                    .foregroundColor(.blue)
                                }
                                .listRowBackground(Color.white)
                                
                                Button("Show Share Code") {
                                    if let code = authManager.currentGroup?.code {
                                        let activityVC = UIActivityViewController(activityItems: [code], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }
                                }
                                .foregroundColor(.blue)
                                .listRowBackground(Color.white)
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
                        .listRowBackground(Color.white)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Settings")
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
    }
}
