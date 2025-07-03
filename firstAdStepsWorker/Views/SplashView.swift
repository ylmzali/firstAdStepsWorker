import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager

    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                ZStack {
                    VStack {
                        Image("logo-white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 120)
                    }
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Uygulama başlangıç kontrolleri
            Task {
                // Session kontrolü
                if sessionManager.isAuthenticated {
                    // Ana ekrana yönlendir
                    navigationManager.goToHome()
                } else {
                    // Telefon doğrulama ekranına yönlendir
                    navigationManager.goToPhoneVerification()
                }
            }
            
        }
    }
} 

#Preview {
    SplashView()
}
