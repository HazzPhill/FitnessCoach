import SwiftUI
import CachedAsyncImage

struct UpdateDetailView: View {
    let update: AuthManager.Update
    @EnvironmentObject var authManager: AuthManager  // To access latestUpdates

    // Compute the weight difference from the immediately preceding update.
    private var weightDeltaText: String {
        guard let _ = update.date else { return "N/A" }
        let userUpdates = authManager.latestUpdates
            .filter { $0.userId == update.userId && $0.date != nil }
            .sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        if let index = userUpdates.firstIndex(where: { $0.id == update.id }), index > 0 {
            let previousUpdate = userUpdates[index - 1]
            let delta = update.weight - previousUpdate.weight
            let sign = delta >= 0 ? "+" : ""
            return sign + String(format: "%.1f KG", delta)
        }
        return "N/A"
    }
    
    // Compute the color for the weight delta:
    private var weightDeltaColor: Color {
        guard let _ = update.date else { return .gray }
        let userUpdates = authManager.latestUpdates
            .filter { $0.userId == update.userId && $0.date != nil }
            .sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
        if let index = userUpdates.firstIndex(where: { $0.id == update.id }), index > 0 {
            let previousUpdate = userUpdates[index - 1]
            let delta = update.weight - previousUpdate.weight
            return delta >= 0 ? Color("SecondaryAccent") : Color("Warning")
        }
        return .gray
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Main content
                VStack {
                    ZStack {
                        if let imageUrl = update.imageUrl, let url = URL(string: imageUrl) {
                            if let cachedImage = ImagePrefetcher.shared.image(for: url) {
                                // Use the already-prefetched image.
                                Image(uiImage: cachedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width,
                                           height: geometry.size.height / 1.5)
                                    .clipped()
                                    .zIndex(1)
                                    .overlay {
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.black.opacity(0.6),
                                                                        Color("Background").opacity(1)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(width: geometry.size.width,
                                               height: geometry.size.height / 1.5)
                                    }
                            } else {
                                // Fallback to downloading (and caching) the image.
                                CachedAsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width,
                                                   height: geometry.size.height / 1.5)
                                            .clipped()
                                            .zIndex(1)
                                            .overlay {
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.black.opacity(0.6),
                                                                                Color("Background").opacity(1)]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                                .frame(width: geometry.size.width,
                                                       height: geometry.size.height / 1.5)
                                            }
                                    case .failure(_):
                                        Image("gym_background")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: geometry.size.width,
                                                   height: geometry.size.height / 1.5)
                                            .clipped()
                                            .zIndex(1)
                                            .overlay {
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.black.opacity(0.6),
                                                                                Color("Background").opacity(1)]),
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                                .frame(width: geometry.size.width,
                                                       height: geometry.size.height / 1.5)
                                            }
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text(update.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color("SecondaryAccent"))
                        
                        HStack {
                            // Current weight box.
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.white)
                                .overlay(
                                    Text(String(format: "%.1f KG", update.weight))
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color("Accent"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("BoxStroke"), lineWidth: 2)
                                )
                                .frame(width: 165, height: 100)
                            
                            Spacer()
                            
                            // Weight delta box with conditional color.
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.white)
                                .overlay(
                                    Text(weightDeltaText)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(weightDeltaColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("BoxStroke"), lineWidth: 2)
                                )
                                .frame(width: 165, height: 100)
                        }
                        
                        if let date = update.date {
                            Text("\(date.formattedWithOrdinal())")
                                .font(.body)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .background(Color("Background"))
                .edgesIgnoringSafeArea(.top)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    let sampleUpdate = AuthManager.Update(
        id: "sample_id",
        userId: "test_user",
        name: "Sample Update",
        weight: 70.0,
        imageUrl: "https://example.com/your_optimised_image.jpg",
        date: Date()
    )
    
    return UpdateDetailView(update: sampleUpdate)
        .environmentObject(AuthManager.shared)
}






extension Date {
    func formattedWithOrdinal() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month, .year], from: self)
        guard let day = components.day,
              let month = components.month,
              let year = components.year else {
            return ""
        }
        
        // Formatter for month abbreviated and two-digit year.
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        let monthString = monthFormatter.string(from: self)
        
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yy"
        let yearString = yearFormatter.string(from: self)
        
        // Compute ordinal suffix.
        let suffix: String
        switch day {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        
        return "\(monthString) \(day)\(suffix) \(yearString)"
    }
}
