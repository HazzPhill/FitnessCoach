import SwiftUI

struct UpdatePreview: View {
    var label: String
    var Weight: Int
    var date: Date
    var imageUrl: String?
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Helper function to format the date
    private func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var backgroundView: some View {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            return AnyView(
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if phase.error != nil {
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                    } else {
                        ProgressView()
                    }
                }
            )
        } else {
            return AnyView(
                Image("gym_background")
                    .resizable()
                    .scaledToFill()
            )
        }
    }
    
    var body: some View {
        ZStack {
            backgroundView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)
                
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(themeManager.headingFont(size: 20))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                    Spacer()
                }
                
                Text("\(Weight) KG")
                    .font(themeManager.bodyFont(size: 12))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                
                HStack {
                    Spacer()
                    Text(formattedDate(from: date))
                        .font(themeManager.bodyFont(size: 12))
                        .foregroundColor(themeManager.textColor(for: colorScheme))
                }
            }
            .zIndex(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: 93)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
