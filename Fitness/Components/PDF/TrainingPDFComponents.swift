import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct TrainingPDFViewerScreen: View {
    let clientId: String
    let isCoachView: Bool
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var pdfURL: URL? = nil
    @State private var isLoading: Bool = true
    @State private var isSaving: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showSavedConfirmation: Bool = false
    @State private var showSaveError: Bool = false
    @State private var isPDFPickerPresented: Bool = false
    
    // For document picker
    private let supportedTypes: [UTType] = [UTType.pdf]
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack {
                    // If coach mode and no PDF loaded, show upload option
                    if isCoachView && pdfURL == nil && !isLoading {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(themeManager.accentColor(for: colorScheme))
                            
                            Text("No training plan uploaded yet")
                                .font(themeManager.bodyFont(size: 18))
                                .foregroundColor(themeManager.textColor(for: colorScheme))
                            
                            Button {
                                isPDFPickerPresented = true
                            } label: {
                                Text("Upload Training PDF")
                                    .font(themeManager.bodyFont(size: 16))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(themeManager.accentColor(for: colorScheme))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    // PDF View or Loading
                    else if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(2)
                            
                            Text("Loading PDF...")
                                .font(themeManager.bodyFont(size: 16))
                                .foregroundColor(themeManager.textColor(for: colorScheme))
                                .padding(.top, 20)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let url = pdfURL {
                        PDFKitView(url: url)
                    } else {
                        Text("Could not load the PDF.")
                            .font(themeManager.bodyFont(size: 16))
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                
                // Saved confirmation overlay
                if showSavedConfirmation {
                    VStack {
                        Text("PDF Saved!")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSavedConfirmation = false
                            }
                        }
                    }
                }
                
                // Save error overlay
                if showSaveError {
                    VStack {
                        Text("Error saving PDF")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showSaveError = false
                            }
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ModernBackButton()
                        .environmentObject(themeManager)
                }
                
                // Provide title in the center
                ToolbarItem(placement: .principal) {
                    Text("Training PDF")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
                
                // Coach can delete or replace, client can save
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCoachView && pdfURL != nil {
                        HStack(spacing: 12) {
                            Button(action: {
                                isPDFPickerPresented = true
                            }) {
                                Image(systemName: "arrow.up.doc.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                            
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.red)
                            }
                        }
                    } else if !isCoachView && pdfURL != nil {
                        Button(action: {
                            savePDFToPhotos()
                        }) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 30, height: 30)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .onAppear {
                loadPDF()
            }
            .fileImporter(
                isPresented: $isPDFPickerPresented,
                allowedContentTypes: supportedTypes,
                allowsMultipleSelection: false
            ) { result in
                handlePDFSelection(result: result)
            }
            .alert("Delete Training PDF", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePDF()
                }
            } message: {
                Text("Are you sure you want to delete this training PDF? This action cannot be undone.")
            }
            .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func loadPDF() {
        isLoading = true
        
        Task {
            do {
                // Get PDF URL from manager
                if let urlString = try await TrainingPDFManager.shared.getTrainingPDFURL(clientId: clientId),
                   let url = URL(string: urlString) {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("Error loading PDF: \(error.localizedDescription)")
            }
        }
    }
    
    private func handlePDFSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            
            // Start upload process
            uploadPDF(url: selectedURL)
        case .failure(let error):
            print("PDF selection failed: \(error.localizedDescription)")
        }
    }
    
    private func uploadPDF(url: URL) {
        isLoading = true
        
        // Security-scoped resource handling
        guard url.startAccessingSecurityScopedResource() else {
            isLoading = false
            return
        }
        
        do {
            let pdfData = try Data(contentsOf: url)
            
            // Upload using TrainingPDFManager
            Task {
                do {
                    let urlString = try await TrainingPDFManager.shared.uploadTrainingPDF(clientId: clientId, pdfData: pdfData)
                    
                    if let newUrl = URL(string: urlString) {
                        await MainActor.run {
                            self.pdfURL = newUrl
                            self.isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                    }
                    print("PDF upload error: \(error.localizedDescription)")
                }
            }
        } catch {
            isLoading = false
            print("Failed to read PDF data: \(error.localizedDescription)")
        }
        
        url.stopAccessingSecurityScopedResource()
    }
    
    private func savePDFToPhotos() {
        guard let url = pdfURL else { return }
        
        isSaving = true
        
        TrainingPDFManager.shared.savePDFToPhotos(pdfURL: url) { success, error in
            DispatchQueue.main.async {
                isSaving = false
                
                if success {
                    withAnimation {
                        showSavedConfirmation = true
                    }
                } else {
                    withAnimation {
                        showSaveError = true
                    }
                    print("Error saving PDF: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    
    private func deletePDF() {
        Task {
            do {
                try await TrainingPDFManager.shared.deleteTrainingPDF(clientId: clientId)
                
                // Add a small delay before dismissing to ensure Firebase operations complete
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to delete PDF: \(error.localizedDescription)")
            }
        }
    }
}
