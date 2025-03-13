import SwiftUI

struct ClientBox: View {
    let clientName: String
    let clientId: String
    @StateObject private var viewModel: ClientBoxViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    init(clientName: String, clientId: String) {
        self.clientName = clientName
        self.clientId = clientId
        _viewModel = StateObject(wrappedValue: ClientBoxViewModel(clientId: clientId))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Top row: Client name and the profile picture
            HStack {
                Text(clientName)
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                Spacer()
                if let urlString = viewModel.clientProfileImageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 34, height: 34)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                        case .failure(_):
                            Image(systemName: "person.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 34, height: 34)
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                }
            }
            // Bottom row: Last update info
            HStack {
               
                Text(timeAgoString(from: viewModel.latestUpdate?.date))
                    .font(themeManager.captionFont(size: 12))
                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
                Spacer()
                Text("\(Int(viewModel.latestUpdate?.weight ?? 0)) KG")
                    .font(themeManager.captionFont(size: 12))
                    .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .frame(width: 164, height: 77, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
        )
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    /// Returns a human-friendly "time ago" string from the given date.
    private func timeAgoString(from date: Date?) -> String {
        guard let date = date else { return "No entry" }
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            let seconds = Int(interval)
            return seconds == 1 ? "1 sec ago" : "\(seconds) sec ago"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 1 ? "1 min ago" : "\(minutes) min ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hr ago" : "\(hours) hr ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else {
            let weeks = Int(interval / 604800)
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        }
    }
}

struct ClientBox_Previews: PreviewProvider {
    static var previews: some View {
        ClientBox(clientName: "Harry P", clientId: "dummyClientId")
            .environmentObject(ThemeManager())
            .previewLayout(.sizeThatFits)
    }
}
