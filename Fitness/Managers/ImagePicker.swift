import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    // Binding to store the selected image.
    @Binding var image: UIImage?
    // Environment variable to dismiss the picker.
    @Environment(\.presentationMode) var presentationMode

    // Create and configure the UIImagePickerController.
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    // No update logic required.
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // Create the coordinator to handle delegate callbacks.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class to handle UIImagePickerControllerDelegate methods.
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // Called when an image is selected.
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // Called if the user cancels the picker.
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
