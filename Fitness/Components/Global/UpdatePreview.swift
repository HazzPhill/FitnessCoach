import SwiftUI

struct UpdatePreview: View {
    var label: String
    var Weight: Int
    var date: Date  // Changed from Int to Date
    var imageUrl: String?  // New property for the image URL

    // Helper function to get the ordinal for the day
    private func dayOrdinal(from day: Int) -> String {
        switch day {
        case 11, 12, 13:
            return "\(day)th"
        default:
            switch day % 10 {
            case 1:
                return "\(day)st"
            case 2:
                return "\(day)nd"
            case 3:
                return "\(day)rd"
            default:
                return "\(day)th"
            }
        }
    }
    
    // Computed property to format the date as "Jan 5th 24"
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM" // Month abbreviation
        let month = formatter.string(from: date)
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date) % 100 // last two digits
        return "\(month) \(dayOrdinal(from: day)) \(year)"
    }
    
    var body: some View {
        HStack {
                if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else if phase.error != nil {
                            Image("gym_background")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            ProgressView()
                                .frame(width: 60, height: 60)
                        }
                    }
                } else {
                    Image("gym_background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 83)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                    Spacer()
                    Text(formattedDate)  // Display the formatted date
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                }
                Text("\(Weight) KG")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("Accent"))
            }
        }
        .frame(maxWidth: .infinity,maxHeight: 93)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("BoxStroke"), lineWidth: 3)
        )
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    // Use current date for preview demonstration
    UpdatePreview(label: "Feeling Good", Weight: 53, date: Date(), imageUrl: "https://via.placeholder.com/150")
}
