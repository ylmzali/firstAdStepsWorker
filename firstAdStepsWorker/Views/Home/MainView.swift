import SwiftUI


struct MainView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @Binding var selectedTab: Int
    
    var body: some View {
            // HERO SECTION
            ZStack {
                GeometryReader { geometry in
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        
                        VStack {
                            Image("logo-white")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 120)
                                .shadow(color: Color.black.opacity(1), radius: 15, x: 0, y: -5)
                        }
                        .padding(.top, 45)
                        .frame(height: max(geometry.size.height * 0.35, 0))
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 30) {
                            VStack(alignment: .leading) {
                                Text("Açık Hava\nReklamcılığında\nYeni Teknoloji")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .mask(MeshGradientBackground())
                                    .shadow(color: Color.white, radius: 0, x: 0, y: 0)
                                
                                Text("Mobil reklam ekranlarımızla markanızı şehrin kalbine taşıyın.")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.bottom, 8)
                            }
                            
                            Button(action: {
                                selectedTab = 1
                            }) {
                                HStack {
                                    Image(systemName: "megaphone.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("REKLAMLARIM")
                                        .bold()
                                        .font(.title3)
                                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                                .padding()
                                .padding(.horizontal, 30)
                                .foregroundColor(.white.opacity(0.8))
                                // .background(MeshGradientBackgroundAnimated())
                                .background(.black)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Gradient(colors: [Color.red, Color.green, Color.blue]), lineWidth: 3)
                                        .blur(radius: 5)
                                        .offset(y: 1)
                                )
                                .mask(MeshGradientBackgroundAnimated())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                            }
                            .padding(.bottom, 150)
                            
                            /*
                            Button(action: {
                                selectedTab = 1
                            }) {
                                HStack {
                                    Image(systemName: "megaphone.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("REKLAMLARIM")
                                        .bold()
                                        .font(.title3)
                                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                                .frame(width: 300, height: 60)
                                .background(
                                    ZStack {
                                        Color(.gray.opacity(0.3))
                                        RoundedRectangle(cornerRadius: 50, style: .continuous)
                                            .foregroundColor(.white)
                                            .blur(radius: 4)
                                            .offset(x: -4, y: -4)
                                    }
                                )
                                .foregroundColor(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 20, y: 20)
                                .shadow(color: .white.opacity(0.3), radius: 20, x: -20, y: -20)
                            }
                            .padding(.bottom, 150)
                             */



                        }
                    }
                    .padding(24)
                    .frame(minHeight: geometry.size.height)
                    .frame(height: geometry.size.height)
                    .background(
                        ZStack {
                            Image("bazaar_bg")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                            
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        .clear,
                                        .black.opacity(0.6),
                                        .black
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    
                    // CONTENT SECTION
                    /*
                     VStack(spacing: 32) {
                     
                     // İstatistikler
                     HStack(spacing: 16) {
                     StatCard(
                     icon: "chart.bar.fill",
                     title: "Günlük Gösterim",
                     value: "1.2M",
                     color: .blue
                     )
                     StatCard(
                     icon: "map.fill",
                     title: "Aktif Bölge",
                     value: "12",
                     color: .green
                     )
                     }
                     .padding(.top, 16)
                     .padding()
                     
                     // Özellikler
                     VStack(alignment: .leading, spacing: 24) {
                     Text("Öne Çıkan Özellikler")
                     .font(.title2)
                     .fontWeight(.bold)
                     
                     FeatureRow(
                     icon: "location.fill",
                     title: "Gerçek Zamanlı Takip",
                     subtitle: "Ekranlarınızı canlı olarak takip edin"
                     )
                     
                     FeatureRow(
                     icon: "chart.pie.fill",
                     title: "Detaylı Raporlama",
                     subtitle: "Görüntülenme ve demografik veriler"
                     )
                     
                     FeatureRow(
                     icon: "calendar",
                     title: "Kolay Rezervasyon",
                     subtitle: "Tek tıkla rota ve tarih seçimi"
                     )
                     }
                     .padding(.horizontal)
                     // .background(MeshGradientBackground())
                     
                     }
                     .padding(.bottom, 32)
                     */
                    
                
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Helper Views
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            /*
            Image(systemName: "chevron.right")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
             */
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    MainView(selectedTab: .constant(0))
}
