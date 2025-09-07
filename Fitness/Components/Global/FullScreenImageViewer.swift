import SwiftUI
import CachedAsyncImage

struct FullScreenImageViewer: View {
    let imageUrls: [String]
    @State var currentIndex: Int
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
                .opacity(0.95)
            
            // Image viewer with gestures
            TabView(selection: $currentIndex) {
                ForEach(0..<imageUrls.count, id: \.self) { index in
                    if let url = URL(string: imageUrls[index]) {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .offset(x: offset.width + dragOffset.width,
                                           y: offset.height + dragOffset.height)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = lastScale * value
                                            }
                                            .onEnded { _ in
                                                withAnimation(.spring()) {
                                                    if scale < 1 {
                                                        scale = 1
                                                        offset = .zero
                                                    } else if scale > 5 {
                                                        scale = 5
                                                    }
                                                }
                                                lastScale = scale
                                            }
                                    )
                                    .simultaneousGesture(
                                        DragGesture()
                                            .updating($dragOffset) { value, state, _ in
                                                if scale > 1 {
                                                    state = value.translation
                                                }
                                            }
                                            .onEnded { value in
                                                if scale > 1 {
                                                    offset.width += value.translation.width
                                                    offset.height += value.translation.height
                                                }
                                            }
                                    )
                                    .onTapGesture(count: 2) {
                                        withAnimation(.spring()) {
                                            if scale > 1 {
                                                scale = 1
                                                offset = .zero
                                                lastScale = 1
                                            } else {
                                                scale = 2
                                                lastScale = 2
                                            }
                                        }
                                    }
                            case .failure:
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Failed to load image")
                                        .foregroundColor(.gray)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: imageUrls.count > 1 ? .always : .never))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Top controls
            VStack {
                HStack {
                    // Close button
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    
                    Spacer()
                    
                    // Image counter
                    if imageUrls.count > 1 {
                        Text("\(currentIndex + 1) / \(imageUrls.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                    }
                    
                    // Share button
                    Button {
                        shareImage()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onChange(of: currentIndex) { _ in
            // Reset zoom when switching images
            withAnimation {
                scale = 1
                lastScale = 1
                offset = .zero
                lastOffset = .zero
            }
        }
    }
    
    private func shareImage() {
        guard currentIndex < imageUrls.count,
              let url = URL(string: imageUrls[currentIndex]) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        let activityVC = UIActivityViewController(
                            activityItems: [image],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let rootVC = windowScene.windows.first?.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    }
                }
            } catch {
                print("Failed to share image: \(error)")
            }
        }
    }
}
