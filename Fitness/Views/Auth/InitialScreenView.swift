import SwiftUI

struct InitialScreenView: View {
    @State private var showLoginSheet = false
    @State private var showRegisterSheet = false

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
                .zIndex(0)
            
            GeometryReader { geometry in
                VStack(alignment:.center,spacing: 0) {
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
                            .font(.system(size: 38))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("SecondaryAccent"))
                            .multilineTextAlignment(.leading)
                            .frame(width: 350, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .layoutPriority(1) // Gives this text view higher priority in layout
                            .padding(.bottom, 30)

                        // Login Button
                        Button(action: {
                            showLoginSheet.toggle()
                        }) {
                            Text("Log in")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 350, height: 50)
                                .background(Color("Accent"))
                                .cornerRadius(25)
                        }
                        .padding(.bottom, 20)
                        .sheet(isPresented: $showLoginSheet) {
                            LoginView()
                                .presentationDetents([.medium, .large])
                                .ignoresSafeArea(.all)
                                .presentationCornerRadius(30)
                        }
                        
                        // Sign up Hyperlink
                        HStack {
                            Text("Don’t have an account?")
                                .font(.footnote)
                                .foregroundColor(Color.gray)
                            Button(action: {
                                showRegisterSheet.toggle()
                            }) {
                                Text("Sign up")
                                    .underline() // Makes it appear as a link
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(Color.gray)
                        }
                        .padding(.bottom, 40)
                        .sheet(isPresented: $showRegisterSheet) {
                            RegisterView()
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

#Preview {
    InitialScreenView()
}
