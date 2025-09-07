import SwiftUI
import Charts
import Firebase
import FirebaseStorage

struct MonthOnMonthGraphView: View {
    let userId: String
    @StateObject private var viewModel: MonthOnMonthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: MonthOnMonthViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and time period selector
            HStack {
                Text("Monthly Progress")
                    .font(themeManager.headingFont(size: 18))
                    .foregroundColor(themeManager.textColor(for: colorScheme))
                
                Spacer()
                
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    Text("3M").tag(MonthPeriod.threeMonths)
                    Text("6M").tag(MonthPeriod.sixMonths)
                    Text("1Y").tag(MonthPeriod.oneYear)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            
            if viewModel.monthlyData.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme).opacity(0.5))
                    
                    Text("No monthly data available")
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
                // Chart view
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "C6C6C6"), lineWidth: 3)
                    .overlay {
                        Chart {
                            ForEach(viewModel.monthlyData) { entry in
                                BarMark(
                                    x: .value("Month", entry.monthLabel),
                                    y: .value("Change", entry.weightChange)
                                )
                                .foregroundStyle(entry.weightChange >= 0 ?
                                    Color.green.opacity(0.7) : Color.red.opacity(0.7))
                                .cornerRadius(4)
                                
                                // Add value labels on bars
                                BarMark(
                                    x: .value("Month", entry.monthLabel),
                                    y: .value("Change", entry.weightChange)
                                )
                                .foregroundStyle(.clear)
                                .annotation(position: entry.weightChange >= 0 ? .top : .bottom) {
                                    Text(String(format: "%+.1f", entry.weightChange))
                                        .font(.caption2)
                                        .foregroundColor(themeManager.textColor(for: colorScheme))
                                }
                            }
                            
                            // Reference line at zero
                            RuleMark(y: .value("Zero", 0))
                                .foregroundStyle(themeManager.textColor(for: colorScheme).opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                        .padding()
                        .chartXAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.clear)
                                AxisValueLabel() {
                                    if let month = value.as(String.self) {
                                        Text(month)
                                            .font(.caption)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                    .foregroundStyle(Color.gray.opacity(0.2))
                                AxisValueLabel() {
                                    if let weight = value.as(Double.self) {
                                        Text(String(format: "%.0f", weight))
                                            .font(.caption)
                                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                                    }
                                }
                            }
                        }
                        .chartYScale(domain: viewModel.yAxisDomain)
                        .chartPlotStyle { plotArea in
                            plotArea
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                        }
                    }
                .frame(height: 200)
                .background(themeManager.cardBackgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Stats summary
                HStack(spacing: 20) {
                    StatBox(
                        title: "Total Change",
                        value: String(format: "%+.1f kg", viewModel.totalChange),
                        color: viewModel.totalChange >= 0 ? .green : .red
                    )
                    .environmentObject(themeManager)
                    
                    StatBox(
                        title: "Avg Monthly",
                        value: String(format: "%+.1f kg", viewModel.averageMonthlyChange),
                        color: viewModel.averageMonthlyChange >= 0 ? .green : .red
                    )
                    .environmentObject(themeManager)
                    
                    StatBox(
                        title: "Best Month",
                        value: viewModel.bestMonth,
                        color: themeManager.accentColor(for: colorScheme)
                    )
                    .environmentObject(themeManager)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Supporting Views
struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(themeManager.captionFont(size: 10))
                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
            Text(value)
                .font(themeManager.bodyFont(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(themeManager.cardBackgroundColor(for: colorScheme))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "C6C6C6").opacity(0.5), lineWidth: 1)
        )
    }
}

// Data Models and ViewModel
struct MonthlyDataEntry: Identifiable {
    let id = UUID()
    let month: Date
    let monthLabel: String
    let averageWeight: Double
    let weightChange: Double
}

enum MonthPeriod: String, CaseIterable {
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    
    var months: Int {
        switch self {
        case .threeMonths: return 3
        case .sixMonths: return 6
        case .oneYear: return 12
        }
    }
}

class MonthOnMonthViewModel: ObservableObject {
    @Published var monthlyData: [MonthlyDataEntry] = []
    @Published var selectedPeriod: MonthPeriod = .threeMonths {
        didSet { fetchMonthlyData() }
    }
    @Published var totalChange: Double = 0
    @Published var averageMonthlyChange: Double = 0
    @Published var bestMonth: String = "N/A"
    
    private let userId: String
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    var yAxisDomain: ClosedRange<Double> {
        guard !monthlyData.isEmpty else { return -5...5 }
        let values = monthlyData.map { $0.weightChange }
        let minVal = min(values.min() ?? -5, -2)
        let maxVal = max(values.max() ?? 5, 2)
        return (minVal - 1)...(maxVal + 1)
    }
    
    init(userId: String) {
        self.userId = userId
        fetchMonthlyData()
    }
    
    private func fetchMonthlyData() {
        listener?.remove()
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .month, value: -selectedPeriod.months, to: now) ?? now
        
        listener = db.collection("updates")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThan: Timestamp(date: startDate))
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching monthly data: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Group updates by month
                var monthlyGroups: [Date: [Double]] = [:]
                
                for doc in documents {
                    let data = doc.data()
                    if let weight = data["weight"] as? Double,
                       let timestamp = data["date"] as? Timestamp {
                        let date = timestamp.dateValue()
                        let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
                        
                        if monthlyGroups[monthStart] == nil {
                            monthlyGroups[monthStart] = []
                        }
                        monthlyGroups[monthStart]?.append(weight)
                    }
                }
                
                // Calculate monthly averages and changes
                let sortedMonths = monthlyGroups.keys.sorted()
                var entries: [MonthlyDataEntry] = []
                var previousAverage: Double? = nil
                
                for month in sortedMonths {
                    guard let weights = monthlyGroups[month], !weights.isEmpty else { continue }
                    
                    let average = weights.reduce(0, +) / Double(weights.count)
                    let change = previousAverage != nil ? average - previousAverage! : 0
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM"
                    let monthLabel = formatter.string(from: month)
                    
                    entries.append(MonthlyDataEntry(
                        month: month,
                        monthLabel: monthLabel,
                        averageWeight: average,
                        weightChange: change
                    ))
                    
                    previousAverage = average
                }
                
                // Update published properties
                DispatchQueue.main.async {
                    self.monthlyData = entries
                    self.calculateStats()
                }
            }
    }
    
    private func calculateStats() {
        guard !monthlyData.isEmpty else {
            totalChange = 0
            averageMonthlyChange = 0
            bestMonth = "N/A"
            return
        }
        
        // Total change
        if let first = monthlyData.first, let last = monthlyData.last {
            totalChange = last.averageWeight - first.averageWeight
        }
        
        // Average monthly change
        let changes = monthlyData.map { $0.weightChange }
        averageMonthlyChange = changes.isEmpty ? 0 : changes.reduce(0, +) / Double(changes.count)
        
        // Best month (most positive change or least negative)
        if let best = monthlyData.max(by: { $0.weightChange < $1.weightChange }) {
            bestMonth = best.monthLabel
        }
    }
    
    deinit {
        listener?.remove()
    }
}
