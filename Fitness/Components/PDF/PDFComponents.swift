import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// PDF Upload Box for the coach view
struct PDFUploadBox: View {
    let clientId: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var hasPDF: Bool = false
    @State private var isPDFPickerPresented: Bool = false
    @State private var isUploading: Bool = false
    @State private var isPDFViewerPresented: Bool = false
    
    // For document picker
    private let supportedTypes: [UTType] = [UTType.pdf]
    
    var body: some View {
        Button(action: {
            if hasPDF {
                isPDFViewerPresented = true
            } else {
                isPDFPickerPresented = true
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor(for: colorScheme).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: hasPDF ? "doc.fill" : "doc.badge.plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(themeManager.accentColor(for: colorScheme))
                }
                
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.0)
                } else {
                    Text(hasPDF ? "View or Replace PDF" : "Upload Meal Plan PDF")
                        .font(themeManager.bodyFont(size: 16))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer() // Push content to the left
            }
            .padding(.horizontal, 16)
            .frame(height: 60) // Reduced height
            .padding(.vertical, 10)
            .padding(.horizontal, 0) // No horizontal padding for full width
            .frame(maxWidth: .infinity) // Full width of screen
            .background(themeManager.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
            )
        }
        .disabled(isUploading)
        .fileImporter(
            isPresented: $isPDFPickerPresented,
            allowedContentTypes: supportedTypes,
            allowsMultipleSelection: false
        ) { result in
            handlePDFSelection(result: result)
        }
        .sheet(isPresented: $isPDFViewerPresented, onDismiss: {
            // Refresh PDF existence state when returning from viewer
            checkForExistingPDF()
        }) {
            PDFViewerScreen(clientId: clientId, isCoachView: true)
                .environmentObject(themeManager)
        }
        .onAppear {
            checkForExistingPDF()
        }
    }
    
    private func checkForExistingPDF() {
        PDFMealPlanManager.shared.checkMealPlanExists(clientId: clientId) { exists in
            DispatchQueue.main.async {
                self.hasPDF = exists
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
        isUploading = true
        
        // Security-scoped resource handling
        guard url.startAccessingSecurityScopedResource() else {
            isUploading = false
            return
        }
        
        do {
            let pdfData = try Data(contentsOf: url)
            
            // Upload using PDFMealPlanManager
            Task {
                do {
                    _ = try await PDFMealPlanManager.shared.uploadPDFMealPlan(clientId: clientId, pdfData: pdfData)
                    
                    await MainActor.run {
                        isUploading = false
                        hasPDF = true
                    }
                } catch {
                    await MainActor.run {
                        isUploading = false
                    }
                    print("PDF upload error: \(error.localizedDescription)")
                }
            }
        } catch {
            isUploading = false
            print("Failed to read PDF data: \(error.localizedDescription)")
        }
        
        url.stopAccessingSecurityScopedResource()
    }
}

// PDF Viewer Box for the client view - with improved visibility and debugging
struct PDFViewerBox: View {
    let clientId: String
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPDFViewerPresented: Bool = false
    @State private var hasPDF: Bool = false
    @State private var checkingStatus: String = "Checking..."
    
    var body: some View {
        Button(action: {
            if hasPDF {
                isPDFViewerPresented = true
            } else {
                // Force recheck when tapped if no PDF
                checkForExistingPDF()
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor(for: colorScheme).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: hasPDF ? "doc.fill" : "doc.badge.plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(themeManager.accentColor(for: colorScheme))
                }
                
                Text(hasPDF ? "View Meal Plan PDF" : "No meal plan PDF available")
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                    .multilineTextAlignment(.leading)
                
                Spacer() // Push content to the left
            }
            .padding(.horizontal, 16)
            .frame(height: 60) // Reduced height
            .padding(.vertical, 10)
            .padding(.horizontal, 0) // No horizontal padding for full width
            .frame(maxWidth: .infinity) // Full width of screen
            .background(themeManager.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "C6C6C6"), lineWidth: 2)
            )

        }
        .disabled(!hasPDF)
        .opacity(1.0) // Always show
        .sheet(isPresented: $isPDFViewerPresented, onDismiss: {
            // Refresh PDF existence state when returning from viewer
            checkForExistingPDF()
        }) {
            PDFViewerScreen(clientId: clientId, isCoachView: false)
                .environmentObject(themeManager)
        }
        .onAppear {
            checkForExistingPDF()
        }
    }
    
    private func checkForExistingPDF() {
        print("Checking if PDF exists for client ID: \(clientId)")
        checkingStatus = "Checking..."
        
        PDFMealPlanManager.shared.checkMealPlanExists(clientId: clientId) { exists in
            DispatchQueue.main.async {
                withAnimation {
                    self.hasPDF = exists
                    self.checkingStatus = exists ? "PDF Found" : "No PDF Available"
                    print("PDF exists for client \(clientId): \(exists)")
                }
            }
        }
    }
}

struct PDFViewerScreen: View {
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack {
                    // PDF View or Loading
                    if isLoading {
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
                    Text("Meal Plan PDF")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
                
                // Coach can delete, client can save
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCoachView {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.red)
                        }
                    } else {
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
            .alert("Delete Meal Plan PDF", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deletePDF()
                }
            } message: {
                Text("Are you sure you want to delete this meal plan PDF? This action cannot be undone.")
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
                if let urlString = try await PDFMealPlanManager.shared.getMealPlanURL(clientId: clientId),
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
    
    private func savePDFToPhotos() {
        guard let url = pdfURL else { return }
        
        isSaving = true
        
        PDFMealPlanManager.shared.savePDFToPhotos(pdfURL: url) { success, error in
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
                try await PDFMealPlanManager.shared.deleteMealPlan(clientId: clientId)
                
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

// PDFKit wrapper to display PDF with zoom capabilities
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Enable user interaction
        pdfView.isUserInteractionEnabled = true
        
        // Configure display settings
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Enable zooming
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 4.0 // Allow zoom up to 4x
        
        // Allow page navigation and other standard PDF interactions
        pdfView.usePageViewController(true)
        
        // Enable scrolling
        pdfView.displaysPageBreaks = true
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            uiView.document = document
            
            // Set initial zoom to fit the screen
            uiView.scaleFactor = uiView.scaleFactorForSizeToFit
            
            // Go to first page
            if let firstPage = document.page(at: 0) {
                uiView.go(to: PDFDestination(page: firstPage, at: CGPoint(x: 0, y: 0)))
            }
        }
    }
}


