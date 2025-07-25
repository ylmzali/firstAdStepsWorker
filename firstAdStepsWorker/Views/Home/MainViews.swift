import SwiftUI

struct MainViews: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        // HERO SECTION
        ZStack {
            GeometryReader { geometry in
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack {
                        HStack {
                            Image("logo-black")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150)
                            // .shadow(color: Color.black.opacity(1), radius: 15, x: 0, y: -5)
                            
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image(systemName: "heart")
                                    .font(.system(size: 24))
                            }

                            
                        }
                    }
                    .padding(.top, 70)
                    // .frame(height: max(geometry.size.height * 0.35, 0))
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 30) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Açık Hava\nReklamcılığında\nYeni Teknoloji")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .mask(MeshGradientBackground())
                                .shadow(color: Color.white, radius: 0, x: 0, y: 0)
                            
                            Text("Mobil reklam ekranlarımızla markanızı şehrin kalbine taşıyın.")
                                .font(.title3)
                                .foregroundColor(Theme.purple400.opacity(0.4))
                                .padding(.bottom, 8)
                        }
                        .foregroundColor(Theme.purple400)

                        Button(action: {
                            // TabView'da programmatik olarak tab değiştirme
                            NotificationCenter.default.post(
                                name: .navigateToTab,
                                object: nil,
                                userInfo: ["tabIndex": 1]
                            )
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("ROTALARIM")
                                    .bold()
                                    .font(.title3)
                                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                            .padding()
                            .padding(.horizontal, 30)
                            .foregroundColor(.white)
                            .background(Theme.purple400)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Gradient(colors: [Color.red, Color.green, Color.blue]), lineWidth: 3)
                                    .blur(radius: 5)
                                    .offset(y: 1)
                            )
                        }
                        .padding(.bottom, 150)
                    }
                }
                .padding(24)
                .frame(minHeight: geometry.size.height)
                .frame(height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MainViews()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
        .environmentObject(AppStateManager.shared)
}
