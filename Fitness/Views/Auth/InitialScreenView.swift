import SwiftUI

struct InitialScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false

    var body: some View {
        ZStack {
            Image("gym_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .allowsHitTesting(false)
            
            Color.black.opacity(colorScheme == .dark ? 0.3 : 0.0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            VStack(alignment: .leading) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to")
                            .font(themeManager.headingFont(size: 36))
                            .foregroundColor(.primary)
                            .opacity(0.9)
                        
                        Text("Coach by Wardy")
                            .font(themeManager.headingFont(size: 38))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                    
                    // Glass effect button without interactive
                    Button(action: {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        showLoginSheet = true
                    }) {
                        Text("Login")
                            .font(themeManager.bodyFont(size: 18))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 320, height: 50)
                    }
                    .glassEffect(.regular.tint(Color(hex: "002E37")))
                    
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(themeManager.captionFont())
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Button(action: {
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            showRegisterSheet = true
                        }) {
                            Text("Sign up")
                                .font(themeManager.captionFont())
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .underline()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 45))
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(themeManager)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(30)
        }
        .sheet(isPresented: $showRegisterSheet) {
            RegisterView()
                .environmentObject(themeManager)
                .presentationDetents([.large])
                .presentationCornerRadius(30)
        }
    }
}


// Alternative version if you want to use the glass effect
struct InitialScreenView_Previews: PreviewProvider {
    static var previews: some View {
        InitialScreenView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.light)
        
        InitialScreenView()
            .environmentObject(ThemeManager())
            .preferredColorScheme(.dark)
    }
}
