import SwiftUI
import FirebaseStorage
import FirebaseFirestore
import CachedAsyncImage

struct ClientHome: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAddUpdate = false  // Controls presentation of AddUpdateView
    @Namespace private var namespace
    
    // Compute weight entries from the realtime updates in AuthManager for the current year.
    var weightEntries: [WeightEntry] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return authManager.latestUpdates.compactMap { update in
            if let date = update.date, calendar.component(.year, from: date) == currentYear {
                return WeightEntry(date: date, weight: update.weight)
            }
            return nil
        }
        .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea(edges: .all)
                ScrollView {
                    VStack(alignment: .leading) {
                        // Header Section
                        HStack {
                            Text("Welcome \(authManager.currentUser?.firstName ?? "")")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color("Accent"))
                            Spacer()
                            // Use a cached profile image if available.
                            NavigationLink {
                                SettingsView()
                            } label: {
                                if let profileImageUrl = authManager.currentUser?.profileImageUrl,
                                   let url = URL(string: profileImageUrl) {
                                    if let cachedProfile = ImagePrefetcher.shared.image(for: url) {
                                        Image(uiImage: cachedProfile)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 45, height: 45)
                                            .clipShape(Circle())
                                    } else {
                                        CachedAsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 45, height: 45)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 45, height: 45)
                                                    .clipShape(Circle())
                                            case .failure(_):
                                                Image(systemName: "person.circle")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 45, height: 45)
                                                    .clipShape(Circle())
                                            @unknown default:
                                                EmptyView()
                                            }
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
                        
                        Text("Your Progress")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        
                        // Graph view of weight entries
                        WeightGraphView(weightEntries: weightEntries)
                        
                        Text("Your Plan")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundStyle(.black)
                        
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                                    dayMealPlanPreview(day: day, meal: "Meal 1", snack: "Snack 1")
                                        .frame(width: 260)
                                        .scrollTransition(.animated, transition: { content, phase in
                                            content
                                                .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                        })
                                }
                            }
                            .padding(.vertical)
                        }
                        .scrollIndicators(.hidden)
                        
                        HStack {
                            Text("Updates")
                                .font(.title2)
                                .fontWeight(.regular)
                                .foregroundStyle(.black)
                            Spacer()
                            Button {
                                showingAddUpdate = true
                            } label: {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(Color("Accent"))
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundStyle(.white)
                                    )
                            }
                        }
                        
                        // Latest updates list
                        ScrollView {
                            if authManager.latestUpdates.isEmpty {
                                Text("No updates yet.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(authManager.latestUpdates) { update in
                                    NavigationLink {
                                        UpdateDetailView(update: update)
                                            .navigationTransition(.zoom(sourceID: update.id, in: namespace))
                                    } label: {
                                        UpdatePreview(
                                            label: update.name,
                                            Weight: Int(update.weight),
                                            date: update.date ?? Date(),
                                            imageUrl: update.imageUrl
                                        )
                                        .matchedTransitionSource(id: update.id, in: namespace)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingAddUpdate) {
                AddUpdateView()
                    .environmentObject(authManager)
            }
        }
    }
}

#Preview {
    ClientHome()
        .environmentObject(AuthManager.shared)
}
