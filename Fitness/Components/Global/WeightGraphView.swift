import SwiftUI
import Charts

// A simple data model for a weight entry.
struct WeightEntry: Identifiable {
    var id = UUID()
    var date: Date
    var weight: Double
}

struct WeightGraphView: View {
    var weightEntries: [WeightEntry]
    
    var body: some View {
        
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color("BoxStroke"), lineWidth: 2)
            .overlay {
                Chart {
                    ForEach(weightEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color("Accent"))
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", entry.weight)
                        )
                        .foregroundStyle(Color("Accent"))
                    }
                }
                .padding()
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .padding(.vertical, 8) // add vertical padding inside the chart
                        .padding(.horizontal, 4) // add horizontal padding inside the chart
                }
            }
        .frame(height: 200)
        .background(Color.white)
    }
}

struct WeightGraphView_Previews: PreviewProvider {
    static var previews: some View {
        WeightGraphView(weightEntries: [
            WeightEntry(date: Date().addingTimeInterval(-86400 * 50), weight: 70),
            WeightEntry(date: Date().addingTimeInterval(-86400 * 40), weight: 70.5),
            WeightEntry(date: Date().addingTimeInterval(-86400 * 30), weight: 71),
            WeightEntry(date: Date().addingTimeInterval(-86400 * 20), weight: 70.8),
            WeightEntry(date: Date().addingTimeInterval(-86400 * 10), weight: 70)
        ])
    }
}
