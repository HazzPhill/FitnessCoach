import SwiftUI

extension View {
    // Custom modifier to apply appropriate title colors
    func themedNavigationTitle(_ title: String, themeManager: ThemeManager, colorScheme: SwiftUI.ColorScheme) -> some View {
        self.navigationTitle(title)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbarBackground(
                themeManager.backgroundColor(for: colorScheme),
                for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // Update the navigation title color
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(themeManager.backgroundColor(for: colorScheme))
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor(colorScheme == .dark ? .white : themeManager.accentColor(for: colorScheme))
                ]
                appearance.largeTitleTextAttributes = [
                    .foregroundColor: UIColor(colorScheme == .dark ? .white : themeManager.accentColor(for: colorScheme))
                ]
                
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}
