import FirebaseFirestore
import FirebaseStorage
import SwiftUI
import UIKit
import PDFKit
import Photos

class PDFMealPlanManager {
    static let shared = PDFMealPlanManager()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    /// Uploads a PDF meal plan for a specific client
    func uploadPDFMealPlan(clientId: String, pdfData: Data) async throws -> String {
        print("📤 Starting PDF upload for client ID: \(clientId), PDF data size: \(pdfData.count) bytes")
        
        let fileName = "mealplans/\(clientId)/\(UUID().uuidString).pdf"
        let storageRef = storage.reference().child(fileName)
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        
        print("📤 Uploading PDF to path: \(fileName)")
        
        // Upload the PDF data
        _ = try await storageRef.putDataAsync(pdfData, metadata: metadata)
        print("✅ PDF uploaded to Firebase Storage")
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL().absoluteString
        print("🔗 Got download URL: \(downloadURL)")
        
        // Update or create the document in Firestore
        let docRef = db.collection("pdf_meal_plans").document(clientId)
        try await docRef.setData([
            "clientId": clientId,
            "pdfUrl": downloadURL,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("✅ PDF document created in Firestore for client: \(clientId)")
        
        return downloadURL
    }
    
    /// Gets the meal plan PDF URL for a specific client
    func getMealPlanURL(clientId: String) async throws -> String? {
        print("🔍 Checking for PDF URL for client: \(clientId)")
        
        let docRef = db.collection("pdf_meal_plans").document(clientId)
        let document = try await docRef.getDocument()
        
        if document.exists, let data = document.data() {
            let url = data["pdfUrl"] as? String
            print(url != nil ? "✅ Found PDF URL: \(url!)" : "❌ No PDF URL found in document")
            return url
        } else {
            print("❌ No PDF document found for client: \(clientId)")
            return nil
        }
    }
    
    /// Checks if a meal plan PDF exists for a client
    func checkMealPlanExists(clientId: String, completion: @escaping (Bool) -> Void) {
        print("🔍 Checking if PDF meal plan exists for client: \(clientId)")
        
        // Use getDocument(source: .server) to force a server check rather than using cache
        db.collection("pdf_meal_plans").document(clientId).getDocument(source: .server) { document, error in
            if let error = error {
                print("❌ Error checking for PDF: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let document = document {
                let exists = document.exists
                print(exists ? "✅ PDF document exists" : "❌ PDF document does not exist")
                
                if exists {
                    let data = document.data()
                    let hasURL = data?["pdfUrl"] != nil
                    print(hasURL ? "✅ PDF URL found in document" : "❌ No PDF URL in document")
                    completion(hasURL)
                } else {
                    completion(false)
                }
            } else {
                print("❌ No document returned when checking for PDF")
                completion(false)
            }
        }
    }
    
    /// Saves a PDF to the camera roll
    func savePDFToPhotos(pdfURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        // Check for photo library permission
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.downloadAndSavePDF(pdfURL: pdfURL, completion: completion)
                } else {
                    completion(false, NSError(domain: "PDFMealPlanManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
                }
            }
        } else if status == .authorized {
            downloadAndSavePDF(pdfURL: pdfURL, completion: completion)
        } else {
            completion(false, NSError(domain: "PDFMealPlanManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
        }
    }
    
    private func downloadAndSavePDF(pdfURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        print("📥 Downloading PDF from URL: \(pdfURL)")
        
        // Download PDF data from the URL
        URLSession.shared.dataTask(with: pdfURL) { data, response, error in
            if let error = error {
                print("❌ Failed to download PDF: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            guard let data = data else {
                print("❌ No data received when downloading PDF")
                completion(false, NSError(domain: "PDFMealPlanManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            print("✅ Successfully downloaded PDF data: \(data.count) bytes")
            
            // Convert PDF to image (first page only for simplicity)
            if let pdfDocument = PDFDocument(data: data) {
                print("✅ Successfully created PDF document, pages: \(pdfDocument.pageCount)")
                
                if let page = pdfDocument.page(at: 0) {
                    print("✅ Getting thumbnail for first page")
                    
                    // thumbnail() returns a non-optional UIImage
                    let pageImage = page.thumbnail(of: CGSize(width: 612, height: 792), for: .mediaBox)
                    print("✅ Generated thumbnail image")
                    
                    UIImageWriteToSavedPhotosAlbum(pageImage, nil, nil, nil)
                    print("✅ Saved image to photos")
                    
                    completion(true, nil)
                } else {
                    print("❌ Could not get first page from PDF")
                    completion(false, NSError(domain: "PDFMealPlanManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get first page"]))
                }
            } else {
                print("❌ Could not create PDF document from data")
                completion(false, NSError(domain: "PDFMealPlanManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF document"]))
            }
        }.resume()
    }
    
    /// Deletes a meal plan PDF for a client
    func deleteMealPlan(clientId: String) async throws {
        print("🗑️ Deleting PDF meal plan for client: \(clientId)")
        
        // Get the current URL to delete from storage too
        let docRef = db.collection("pdf_meal_plans").document(clientId)
        let document = try await docRef.getDocument()
        
        if document.exists, let data = document.data(), let pdfUrl = data["pdfUrl"] as? String {
            print("✅ Found document and URL to delete: \(pdfUrl)")
            
            // Delete from Firestore
            try await docRef.delete()
            print("✅ Deleted document from Firestore")
            
            // Delete from Storage if URL exists
            if let url = URL(string: pdfUrl) {
                let path = url.lastPathComponent
                let storageRef = storage.reference().child("mealplans/\(clientId)/\(path)")
                
                try await storageRef.delete()
                print("✅ Deleted file from Firebase Storage")
            }
        } else {
            print("❌ No document found to delete or missing URL")
        }
    }
}
