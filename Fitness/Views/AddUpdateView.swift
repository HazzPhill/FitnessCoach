import SwiftUI
import PhotosUI

// Make sure that ModernTextField is available via your shared UI components file.
// For example, if it's in a module called "SharedUI", you might need:
// import SharedUI

struct AddUpdateView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    @State private var updateName = ""
    @State private var weightText = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Set the background color
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Update Info Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Info")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            // Referencing the shared ModernTextField
                            ModernTextField(placeholder: "Name", text: $updateName)
                            ModernTextField(placeholder: "Weight (KG)", text: $weightText, keyboardType: .decimalPad)
                        }
                        
                        // Photo Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                } else {
                                    Text("Select Image")
                                        .foregroundColor(Color("SecondaryAccent"))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color("Accent").opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color("Accent"), lineWidth: 1)
                                        )
                                        .padding(.horizontal)
                                }
                            }
                            .onChange(of: selectedItem) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        selectedImage = image
                                    }
                                }
                            }
                        }
                        
                        // Display error message if needed
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Add Update")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSubmitting {
                        ProgressView()
                            .tint(Color("Accent"))
                    } else {
                        Button("Submit") {
                            submitUpdate()
                        }
                        .foregroundColor(Color("Accent"))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("Accent"))
                }
            }
        }
    }
    
    private func submitUpdate() {
        guard !updateName.isEmpty,
              let weight = Double(weightText) else {
            errorMessage = "Please fill all fields correctly."
            return
        }
        
        isSubmitting = true
        Task {
            do {
                try await authManager.addUpdate(name: updateName, weight: weight, image: selectedImage)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

struct AddUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        AddUpdateView()
            .environmentObject(AuthManager.shared)
    }
}
