//
//  CheckinsView.swift
//  Coach by Wardy
//
//  Created by Harry Phillips on 20/07/2025.
//

import SwiftUI
import UIKit

struct CheckinsView: View {
    let client: AuthManager.DBUser
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var lastSettingsUpdate = Date()
    @Namespace private var namespace
    @Namespace private var checkinNamespace
    @State private var showEditSheet = false
    @State private var viewMode: ViewMode = .daily
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var showingAddCheckinSheet = false
    @State private var showingAddDailyCheckin = false
    @State private var showingAddWeeklyCheckin = false

    enum ViewMode: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
    }
    
    // Fixed colors that work in both light and dark mode
    private let textPrimary = Color(hex: "002E37")
    private let textSecondary = Color(hex: "666666")
    private let backgroundPrimary = Color(hex: "F5F5F5")
    private let backgroundSecondary = Color(hex: "FFFFFF")
    private let backgroundTertiary = Color(hex: "E8E8E8")
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Set a consistent background
                backgroundPrimary.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Your Checkins")
                                .font(themeManager.titleFont(size: 28))
                                .foregroundStyle(textPrimary)
                            Spacer()
                            
                            if let profileImageUrl = client.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView().frame(width: 45, height: 45)
                                    case .success(let image):
                                        image.resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    case .failure(_):
                                        Image(systemName: "person.circle")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                            .foregroundColor(textPrimary)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "person.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 45, height: 45)
                                    .clipShape(Circle())
                                    .foregroundColor(textPrimary)
                            }
                        }
                        
                        // Toggle View
                        VStack(alignment: .leading, spacing: 4) {
                            
                            Picker("View Mode", selection: $viewMode) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .glassEffect(.regular.tint(Color(hex: "002E37")))
                        }
                        
                        // Date Navigation - only for weekly
                        if viewMode == .weekly {
                            HStack {
                                Button(action: { navigateDate(.backward) }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(textPrimary)
                                        .frame(width: 30, height: 30)
                                }
                                
                                Spacer()
                                
                                Button(action: { showDatePicker.toggle() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 13))
                                        Text(dateRangeText)
                                            .font(themeManager.bodyFont(size: 13))
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(backgroundTertiary)
                                    .cornerRadius(8)
                                }
                                
                                Spacer()
                                
                                Button(action: { navigateDate(.forward) }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(textPrimary)
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                    .background(backgroundSecondary)
                    
                    // Content Area
                    ScrollView {
                        if viewMode == .daily {
                            DailyCheckinsSection(
                                selectedDate: Date(),
                                themeManager: themeManager,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                backgroundPrimary: backgroundPrimary,
                                backgroundSecondary: backgroundSecondary,
                                checkinNamespace: checkinNamespace
                            )
                        } else {
                            // Weekly Updates Section - Using real data from authManager
                            WeeklyUpdatesSection(
                                selectedDate: selectedDate,
                                themeManager: themeManager,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                backgroundPrimary: backgroundPrimary,
                                backgroundSecondary: backgroundSecondary,
                                namespace: namespace
                            )
                            .environmentObject(authManager)
                        }
                    }
                    .background(backgroundPrimary)
                }
                .sheet(isPresented: $showDatePicker) {
                    DatePickerSheet(selectedDate: $selectedDate, isPresented: $showDatePicker)
                        .preferredColorScheme(.light) // Force light mode in sheet
                }
                .sheet(isPresented: $showingAddCheckinSheet) {
                    VStack(spacing: 20) {
                        Button(action: {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            showingAddDailyCheckin = true
                            showingAddCheckinSheet = false
                        }) {
                            Text("Daily")
                                .font(themeManager.bodyFont(size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .glassEffect(.regular.interactive().tint(Color(hex: "002E37")))
                        
                        Button(action: {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            showingAddWeeklyCheckin = true
                            showingAddCheckinSheet = false
                        }) {
                            Text("Weekly")
                                .font(themeManager.bodyFont(size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                        .glassEffect(.regular.interactive().tint(Color(hex: "002E37")))
                    }
                    .padding()
                    .presentationDetents([.height(200)])
                    .preferredColorScheme(.light) // Force light mode in sheet
                }
                .sheet(isPresented: $showingAddDailyCheckin, onDismiss: {
                    authManager.refreshDailyCheckins()
                }) {
                    DailyCheckinView(userId: client.userId)
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                        .preferredColorScheme(.light) // Force light mode in sheet
                }
                .sheet(isPresented: $showingAddWeeklyCheckin, onDismiss: {
                    authManager.refreshWeeklyUpdates()
                }) {
                    AddUpdateView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                        .preferredColorScheme(.light) // Force light mode in sheet
                }
                .onAppear {
                    authManager.refreshDailyCheckins()
                    authManager.refreshWeeklyUpdates()
                }
                .onChange(of: showDatePicker) { newValue in
                    if !newValue {
                        selectedDate = selectedDate.startOfWeek
                    }
                }
                
                Button(action: {
                    showingAddCheckinSheet = true
                }) {
                    Text("Add Checkin")
                        .font(themeManager.bodyFont(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "002E37"))
                        .clipShape(Capsule())
                }
                .padding(.bottom, 16)
                .zIndex(2)
            }
            .preferredColorScheme(.light) // Force the entire view to light mode
            .onAppear {
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var dateRangeText: String {
        let weekStart = selectedDate.startOfWeek
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startStr = formatter.string(from: weekStart)
        let endStr = formatter.string(from: weekEnd)
        formatter.dateFormat = "yyyy"
        let yearStr = formatter.string(from: weekStart)
        return "\(startStr) - \(endStr), \(yearStr)"
    }
    
    // MARK: - Helper Functions
    private func navigateDate(_ direction: NavigationDirection) {
        withAnimation {
            let weekOffset = direction == .forward ? 7 : -7
            selectedDate = Calendar.current.date(byAdding: .day, value: weekOffset, to: selectedDate.startOfWeek) ?? selectedDate
        }
    }
    
    enum NavigationDirection {
        case forward, backward
    }
}

// MARK: - Daily Checkins Section
struct DailyCheckinsSection: View {
    let selectedDate: Date
    let themeManager: ThemeManager
    let textPrimary: Color
    let textSecondary: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let checkinNamespace: Namespace.ID
    
    @EnvironmentObject var authManager: AuthManager
    
    private var currentWeekCheckins: [DailyCheckin] {
        let calendar = Calendar.current
        let weekStart = selectedDate.startOfWeek
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        
        return authManager.dailyCheckins
            .filter { checkin in
                if let date = checkin.date {
                    return date >= weekStart && date < weekEnd
                }
                return false
            }
            .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if currentWeekCheckins.isEmpty {
                Text("No daily check-ins for this week.")
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(textSecondary)
                    .padding()
            } else {
                ForEach(currentWeekCheckins) { checkin in
                    NavigationLink {
                        DailyCheckinDetailView(checkin: checkin)
                            .environmentObject(authManager)
                            .environmentObject(themeManager)
                            .navigationTransition(.zoom(sourceID: checkin.id ?? "", in: checkinNamespace))
                    } label: {
                        DailyCheckinPreview(checkin: checkin)
                            .environmentObject(themeManager)
                            .matchedTransitionSource(id: checkin.id ?? "", in: checkinNamespace)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    })
                }
            }
        }
        .padding()
    }
}

// MARK: - Weekly Updates Section (NEW - Shows real data from authManager)
struct WeeklyUpdatesSection: View {
    let selectedDate: Date
    let themeManager: ThemeManager
    let textPrimary: Color
    let textSecondary: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let namespace: Namespace.ID
    
    @EnvironmentObject var authManager: AuthManager
    
    private let calendar = Calendar.current
    
    // Filter updates for the selected week
    private var weeklyUpdates: [AuthManager.Update] {
        let weekStart = selectedDate.startOfWeek
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        
        return authManager.latestUpdates.filter { update in
            guard let updateDate = update.date else { return false }
            return updateDate >= weekStart && updateDate < weekEnd
        }.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    // Group updates by week (will be single group)
    private var weeklyGroupedUpdates: [(weekRange: String, updates: [AuthManager.Update])] {
        let grouped = Dictionary(grouping: weeklyUpdates) { update -> Date in
            guard let date = update.date else { return Date() }
            return date.startOfWeek
        }
        
        return grouped.map { (weekStart, updates) in
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: weekStart)
            let endStr = formatter.string(from: weekEnd)
            let weekRange = "\(startStr) - \(endStr)"
            
            return (weekRange: weekRange, updates: updates.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) })
        }.sorted { first, second in
            // Sort by the first update's date in each group
            let firstDate = first.updates.first?.date ?? Date.distantPast
            let secondDate = second.updates.first?.date ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if weeklyUpdates.isEmpty {
                Text("No weekly check-ins for this week.")
                    .font(themeManager.bodyFont(size: 16))
                    .foregroundColor(textSecondary)
                    .padding()
            } else {
                ForEach(weeklyGroupedUpdates, id: \.weekRange) { weekData in
                    VStack(alignment: .leading, spacing: 12) {
                        // Week header
                        Text(weekData.weekRange)
                            .font(themeManager.bodyFont(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(textSecondary)
                            .padding(.horizontal)
                        
                        // Updates for this week
                        ForEach(weekData.updates) { update in
                            NavigationLink {
                                UpdateDetailView(update: update)
                                    .environmentObject(themeManager)
                                    .navigationTransition(.zoom(sourceID: update.id, in: namespace))
                            } label: {
                                UpdatePreview(
                                    label: update.name,
                                    Weight: Int(update.weight),
                                    date: update.date ?? Date(),
                                    imageUrl: update.imageUrl
                                )
                                .environmentObject(themeManager)
                                .matchedTransitionSource(id: update.id, in: namespace)
                                .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            })
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Week",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            .navigationTitle("Select Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Date Extension
extension Date {
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

// MARK: - Preview
#Preview {
    // Create a mock ThemeManager for preview
    let themeManager = ThemeManager()
    
    // Dummy user for preview
    let sampleUser = AuthManager.DBUser(
        userId: "preview123",
        firstName: "Preview",
        lastName: "User",
        email: "preview@example.com",
        role: .client,
        profileImageUrl: nil
    )
    
    return CheckinsView(client: sampleUser)
        .environmentObject(themeManager)
        .environmentObject(AuthManager())
}

