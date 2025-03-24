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
        VStack {
            if weightEntries.isEmpty {
                // Show a message when there's no data
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme).opacity(0.5))
                    
                    Text("No weight data available")
                        .font(themeManager.bodyFont(size: 16))
                        .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.7))
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                )
            } else {
                // Existing chart code
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
        }
        .onAppear {
            print("📊 WeightGraphView appeared with \(weightEntries.count) entries")
            
            // For debugging - show what data exists
            if !weightEntries.isEmpty {
                print("📅 Date range: \(weightEntries.first?.date.formatted() ?? "none") to \(weightEntries.last?.date.formatted() ?? "none")")
            }
        }
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
