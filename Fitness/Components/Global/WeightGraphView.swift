import SwiftUI
import Charts

// A simple data model for a weight entry.
struct WeightEntry: Identifiable {
    var id = UUID()
    var date: Date
    var weight: Double
}

import SwiftUI
import Charts

struct WeightGraphView: View {
    var weightEntries: [WeightEntry]
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
            .overlay {
                Chart {
                    ForEach(weightEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                        
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                    }
                }
                .padding()
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.3))
                        
                        AxisValueLabel() {
                            if let date = value.as(Date.self) {
                                Text(formatDate(date))
                                    .font(.caption)
                                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.3))
                        
                        AxisValueLabel() {
                            if let weight = value.as(Double.self) {
                                Text("\(Int(weight))")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            }
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                }
            }
        .frame(height: 200)
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // Helper function to format dates for the X axis
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct WeightGraphView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeightGraphView(weightEntries: [
                WeightEntry(date: Date().addingTimeInterval(-86400 * 50), weight: 70),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 40), weight: 70.5),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 30), weight: 71),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 20), weight: 70.8),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 10), weight: 70)
            ])
            .environmentObject(ThemeManager())
            .preferredColorScheme(.light)
            
            WeightGraphView(weightEntries: [
                WeightEntry(date: Date().addingTimeInterval(-86400 * 50), weight: 70),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 40), weight: 70.5),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 30), weight: 71),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 20), weight: 70.8),
                WeightEntry(date: Date().addingTimeInterval(-86400 * 10), weight: 70)
            ])
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
        }
    }
}
