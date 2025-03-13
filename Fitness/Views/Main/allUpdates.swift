import SwiftUI

struct allUpdatesView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    // Default selections for month and year.
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    @State private var showAll: Bool = true       // When true, show all updates (date filter irrelevant)
    @State private var showDatePicker: Bool = false // Controls visibility of the date picker wheels
    
    // Computed property for the date button title.
    var dateButtonTitle: String {
        if showDatePicker {
            return "Done"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "Date"
        }
    }
    
    // Filter updates based on toggle states.
    var filteredUpdates: [AuthManager.Update] {
        let updates: [AuthManager.Update] = {
            if showAll {
                return authManager.yearlyUpdates
            } else {
                return authManager.yearlyUpdates.filter { update in
                    guard let date = update.date else { return false }
                    let components = Calendar.current.dateComponents([.month, .year], from: date)
                    return components.month == selectedMonth && components.year == selectedYear
                }
            }
        }()
        return updates.sorted { (u1, u2) -> Bool in
            guard let d1 = u1.date, let d2 = u2.date else { return false }
            return d1 > d2  // Newest to oldest
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack {
                // Top controls: "All" toggle and Date/Done button.
                HStack {
                    Button(action: {
                        showAll.toggle()
                        // When "All" is turned on, hide the date picker.
                        if showAll {
                            showDatePicker = false
                        }
                    }) {
                        Text("All")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(showAll ? themeManager.accentColor(for: colorScheme) : themeManager.accentColor(for: colorScheme).opacity(0.5))
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation {
                            // If "All" is enabled, disable it and show the date picker.
                            if showAll {
                                showAll = false
                                showDatePicker = true
                            } else {
                                // Otherwise, just toggle the date picker visibility.
                                showDatePicker.toggle()
                            }
                        }
                    }) {
                        Text(dateButtonTitle)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(showDatePicker ? themeManager.accentColor(for: colorScheme) : themeManager.accentColor(for: colorScheme).opacity(0.5))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Date pickers appear if showDatePicker is true.
                if showDatePicker {
                    HStack(spacing: 8) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(DateFormatter().monthSymbols[month - 1])
                                    .tag(month)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 150, height: 100)
                        
                        Picker("Year", selection: $selectedYear) {
                            ForEach(2020...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                Text("\(year)")
                                    .tag(year)
                                    .foregroundColor(themeManager.textColor(for: colorScheme))
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 100)
                    }
                    .transition(.opacity)
                    .padding(.vertical)
                }
                
                // List of filtered updates.
                if filteredUpdates.isEmpty {
                    Text("No check-ins for the selected period.")
                        .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.7))
                        .padding()
                } else {
                    List(filteredUpdates) { update in
                        ZStack {
                            UpdatePreview(
                                label: update.name,
                                Weight: Int(update.weight),
                                date: update.date ?? Date(),
                                imageUrl: update.imageUrl
                            )
                            .environmentObject(themeManager)
                            .contentShape(Rectangle())
                            
                            // Invisible NavigationLink overlay.
                            NavigationLink(destination: UpdateDetailView(update: update)
                                .environmentObject(themeManager)) {
                                EmptyView()
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(0)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(PlainListStyle())
                    .background(themeManager.backgroundColor(for: colorScheme))
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ModernBackButton()
                    .environmentObject(themeManager)
            }
        }
        .navigationTitle("")
        .toolbarBackground(themeManager.backgroundColor(for: colorScheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
