import SwiftUI

struct ClientBox: View {
    let clientName: String
    let clientId: String
    @StateObject private var viewModel: ClientBoxViewModel
    
    init(clientName: String, clientId: String) {
        self.clientName = clientName
        self.clientId = clientId
        _viewModel = StateObject(wrappedValue: ClientBoxViewModel(clientId: clientId))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            // Top row: Client name and an image
            HStack {
                Text(clientName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.black)
                Spacer()
                Image("gym_background")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
            }
            // Bottom row: Last update info
            HStack {
                Image(systemName: "square.and.arrow.up.circle")
                    .foregroundStyle(Color("SecondaryAccent"))
                Text(timeAgoString(from: viewModel.latestUpdate?.date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.black.opacity(0.5))
                Spacer()
                Text("\(Int(viewModel.latestUpdate?.weight ?? 0))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.black.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .frame(width: 164, height: 77, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("BoxStroke"), lineWidth: 2)
        )
        .background(Color.white)
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
        // Preview with dummy values; note that in preview mode the listener won’t fetch real data.
        ClientBox(clientName: "Harry P", clientId: "dummyClientId")
            .previewLayout(.sizeThatFits)
    }
}
