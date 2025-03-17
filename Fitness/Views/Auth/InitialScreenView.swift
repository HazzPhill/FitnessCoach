import SwiftUI

struct InitialScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false

    var body: some View {
        ZStack {
            Color("Background")
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
                                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color("Background").opacity(1)]),
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
                            .foregroundColor(Color("SecondaryAccent"))
                            .multilineTextAlignment(.leading)
                            .frame(width: 350, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .layoutPriority(1)
                            .padding(.bottom, 30)

                        // Login Button
                        Button(action: {
                            showLoginSheet.toggle()
                        }) {
                            Text("Log in")
                                .font(themeManager.bodyFont(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 350, height: 50)
                                .background(Color("Accent"))
                                .cornerRadius(25)
                        }
                        .padding(.bottom, 20)
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
                                .foregroundColor(Color.gray)
                            
                            Button(action: {
                                showRegisterSheet.toggle()
                            }) {
                                Text("Sign up")
                                    .font(themeManager.captionFont())
                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(Color.gray)
                        }
                        .padding(.bottom, 40)
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
        InitialScreenView()
            .environmentObject(ThemeManager())
    }
}
