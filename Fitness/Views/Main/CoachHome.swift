import SwiftUI

struct CoachHome: View {
    @EnvironmentObject var authManager: AuthManager  // Inject AuthManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    // Add refresh state
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
                
                RefreshableScrollView(
                    onRefresh: { done in
                        refreshData()
                        // Complete the refresh after a short delay to show the spinner
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            done()
                        }
                    }
                ) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                                .font(themeManager.titleFont(size: 24))
                                .foregroundStyle(themeManager.accentOrWhiteText(for: colorScheme))
                            Spacer()
                            
                            // Add manual refresh button
                            Button(action: {
                                refreshData()
                                
                                // Add haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeManager.accentOrWhiteText(for: colorScheme))
                                    .rotationEffect(Angle(degrees: isRefreshing ? 360 : 0))
                                    .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                            }
                            .padding(.horizontal, 8)
                            
                            NavigationLink {
                                SettingsView()
                            } label: {
                                // Profile picture code…
                                if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                                   let url = URL(string: profileImageUrl) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                        } else if phase.error != nil {
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 45, height: 45)
                                                .clipShape(Circle())
                                        } else {
                                            ProgressView()
                                                .frame(width: 45, height: 45)
                                        }
                                    }
                                } else {
                                    Image(systemName: "person.circle")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 45, height: 45)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        Text("Your Summary")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        
                        // Your KPI ScrollView …
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                KPIBox(label: "Clients", figure: 200)
                                    .environmentObject(themeManager)
                                    .padding(.trailing, 20)
                                KPIBox(label: "Total Revenue", figure: 200)
                                    .environmentObject(themeManager)
                                    .padding(.trailing, 20)
                                KPIBox(label: "Total Revenue", figure: 200)
                                    .environmentObject(themeManager)
                                    .padding(.trailing, 20)
                            }
                            .padding(.vertical)
                        }
                        
                        Text("Your Clients")
                            .font(themeManager.headingFont(size: 18))
                            .foregroundStyle(themeManager.textColor(for: colorScheme))
                        
                        if let group = authManager.currentGroup, let groupId = group.id {
                            ClientListView(groupId: groupId)
                                .environmentObject(themeManager)
                                .id(isRefreshing) // Force reload when refresh state changes
                        } else {
                            Text("No group found. Please create or join a group.")
                                .font(themeManager.bodyFont())
                                .foregroundStyle(themeManager.textColor(for: colorScheme).opacity(0.6))
                                .padding(.vertical)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // Refresh data when view appears
            refreshData()
        }
    }
    
    // Function to refresh all data
    private func refreshData() {
        print("🔄 Manually refreshing coach dashboard data")
        
        withAnimation {
            isRefreshing = true
        }
        
        // Refresh all relevant data
        authManager.refreshWeeklyUpdates()
        
        // Force refresh of all client data
        Task {
            // Wait a moment for Firebase operations to complete
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Check for any pending client updates
            if let group = authManager.currentGroup {
                for clientId in group.members {
                    if clientId != authManager.currentUser?.userId {
                        // Debug each client's updates
                        await authManager.debugClientUpdates(clientId: clientId)
                    }
                }
            }
            
            // Stop the refresh animation
            await MainActor.run {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Custom Refreshable ScrollView
// This component provides pull-to-refresh functionality for iOS 14 and earlier
struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    
    var threshold: CGFloat = 80
    var onRefresh: (@escaping () -> Void) -> Void
    let content: Content

    init(onRefresh: @escaping (@escaping () -> Void) -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()
                    
                    VStack {
                        refreshHeader
                        content
                    }
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }
    
    private func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero
            
            self.scrollOffset = movingBounds.minY - fixedBounds.minY
            
            self.rotation = Angle(degrees: Double(self.scrollOffset / 20))
            
            // Crossing the threshold on the way down, we start the refresh process
            if !self.frozen && self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold {
                self.frozen = true
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                withAnimation {
                    self.rotation = .degrees(360)
                }
                
                self.onRefresh {
                    withAnimation {
                        self.frozen = false
                    }
                }
            }
            
            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }
    
    var refreshHeader: some View {
        Group {
            if self.scrollOffset > 0 || self.frozen {
                HStack {
                    Spacer()
                    
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 22, weight: .semibold))
                        .rotationEffect(self.rotation)
                        .padding()
                        .animation(.linear, value: self.rotation)
                    
                    Spacer()
                }
                .padding(.top, max(0, self.scrollOffset + (self.frozen ? -self.threshold : 0)))
                .animation(.default, value: self.scrollOffset)
            }
        }
    }
}

// MARK: - Helper Views for Refreshable ScrollView
struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }
    
    struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }
    
    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []
        
        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }
    }
}

struct MovingView: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .movingView, bounds: proxy.frame(in: .global))])
        }
    }
}

struct FixedView: View {
    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
        }
    }
}

struct CoachHome_Previews: PreviewProvider {
    static var previews: some View {
        CoachHome()
            .environmentObject(AuthManager.shared)
            .environmentObject(ThemeManager())
    }
}
