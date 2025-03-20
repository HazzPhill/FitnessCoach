import SwiftUI

struct InitialScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false
    
    // Animation states
    @State private var animateButton = false
    @State private var textAppeared = false

    var body: some View {
        ZStack {
            themeManager.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
                .zIndex(0)
            
            GeometryReader { geometry in
                VStack(alignment:.center, spacing: 0) {
                    // Top half: Gym background with gradient overlay
                    ZStack {
                        Image("gym_background")
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height / 1.5)
                            .clipped()
                            .zIndex(1)
                            .overlay {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.6),
                                        themeManager.backgroundColor(for: colorScheme).opacity(1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height / 1.5)
                            }
                    }
                    
                    // Bottom half: Content
                    VStack(alignment: .center) {
                        Text("Manage your \nfitness like a\nboss")
                            .font(themeManager.headingFont(size: 38))
                            .foregroundColor(themeManager.textColor(for: colorScheme))
                            .multilineTextAlignment(.leading)
                            .frame(width: 350, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .layoutPriority(1)
                            .padding(.bottom, 30)
                            .opacity(textAppeared ? 1 : 0)
                            .offset(y: textAppeared ? 0 : 20)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                                    textAppeared = true
                                }
                            }

                        // Login Button
                        Button(action: {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            showLoginSheet.toggle()
                        }) {
                            Text("Log in")
                                .font(themeManager.bodyFont(size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(width: 350, height: 50)
                                .background(themeManager.accentColor(for: colorScheme))
                                .cornerRadius(25)
                                .shadow(color: themeManager.accentColor(for: colorScheme).opacity(0.3), radius: 5, x: 0, y: 3)
                                .scaleEffect(animateButton ? 1.02 : 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.bottom, 20)
                        .opacity(textAppeared ? 1 : 0)
                        .offset(y: textAppeared ? 0 : 30)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                                textAppeared = true
                            }
                            
                            // Subtle pulsing animation for the button
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                animateButton = true
                            }
                        }
                        .sheet(isPresented: $showLoginSheet) {
                            LoginView()
                                .environmentObject(themeManager)
                                .presentationDetents([.medium, .large])
                                .ignoresSafeArea(.all)
                                .presentationCornerRadius(30)
                        }
                        
                        // Sign up Hyperlink
                        HStack {
                            Text("Don't have an account?")
                                .font(themeManager.captionFont())
                                .foregroundColor(themeManager.textColor(for: colorScheme).opacity(0.6))
                            
                            Button(action: {
                                let impactLight = UIImpactFeedbackGenerator(style: .light)
                                impactLight.impactOccurred()
                                showRegisterSheet.toggle()
                            }) {
                                Text("Sign up")
                                    .font(themeManager.captionFont())
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.accentColor(for: colorScheme))
                                    .underline()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.bottom, 40)
                        .opacity(textAppeared ? 1 : 0)
                        .offset(y: textAppeared ? 0 : 40)
                        .sheet(isPresented: $showRegisterSheet) {
                            RegisterView()
                                .environmentObject(themeManager)
                                .presentationDetents([.large])
                                .ignoresSafeArea(.all)
                                .presentationCornerRadius(30)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .edgesIgnoringSafeArea(.top)
            }
        }
    }
}

struct InitialScreenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InitialScreenView()
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
            
            InitialScreenView()
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
        }
    }
}
