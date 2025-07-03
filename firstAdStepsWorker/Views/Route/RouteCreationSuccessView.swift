import SwiftUI

struct RouteCreationSuccessView: View {
    let route: Route
    let onNewRoute: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    @State private var animateCheckmark = false
    @State private var showNextSteps = false
    
    var body: some View {
        ZStack {
            // Arka plan
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Başarı ikonu ve animasyon
                    ZStack {
                        // Arka plan daire
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.3),
                                        Color.green.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .scaleEffect(showConfetti ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showConfetti)
                        
                        // Checkmark ikonu
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .scaleEffect(animateCheckmark ? 1.1 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateCheckmark)
                    }
                    .padding(.top, 50)
                    
                    // Başlık
                    VStack(spacing: 12) {
                        Text("Reklam Talebiniz Alındı!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Reklam talebiniz başarıyla sisteme kaydedildi. Uzman ekibimiz en kısa sürede sizinle iletişime geçecek.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Reklam Detayları Kartı
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "megaphone.circle.fill")
                                .foregroundColor(.blue)
                            Text("Reklam Detayları")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            SuccessInfoRow(title: "Reklam Başlığı", value: route.title)
                            SuccessInfoRow(title: "Talep Durumu", value: "İnceleniyor")
                            
                            if let assignedDate = route.formattedAssignedDate {
                                SuccessInfoRow(title: "Hedef Tarih", value: assignedDate)
                            }
                            
                            if route.shareWithEmployees {
                                SuccessInfoRow(title: "Ekip Paylaşımı", value: "Aktif")
                                if !route.sharedEmployeeIds.isEmpty {
                                    SuccessInfoRow(title: "Paylaşılan Kişi", value: "\(route.sharedEmployeeIds.count) kişi")
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Sonraki Adımlar Bölümü
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.green)
                            Text("Sonraki Adımlar")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            NextStepRow(
                                icon: "clock.circle.fill",
                                title: "24 Saat İçinde",
                                description: "Uzman ekibimiz reklam talebinizi inceleyecek ve size özel teklif hazırlayacak",
                                color: .blue
                            )
                            
                            NextStepRow(
                                icon: "envelope.circle.fill",
                                title: "E-posta Bildirimi",
                                description: "Teklif hazır olduğunda e-posta ile bilgilendirileceksiniz",
                                color: .orange
                            )
                            
                            NextStepRow(
                                icon: "doc.text.circle.fill",
                                title: "Teklif İnceleme",
                                description: "Teklifi inceleyip onayladıktan sonra ödeme işlemi gerçekleştirilecek",
                                color: .purple
                            )
                            
                            NextStepRow(
                                icon: "calendar.circle.fill",
                                title: "Reklam Başlangıcı",
                                description: "Ödeme sonrası reklamınız belirlenen tarihte yayına başlayacak",
                                color: .green
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // İletişim Bilgileri
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "phone.circle.fill")
                                .foregroundColor(.yellow)
                            Text("İletişim")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 12) {
                            SuccessContactInfoRow(
                                icon: "phone.fill",
                                title: "Telefon",
                                value: "+90 212 555 0123",
                                action: { /* Telefon arama */ }
                            )
                            
                            SuccessContactInfoRow(
                                icon: "envelope.fill",
                                title: "E-posta",
                                value: "destek@buisyurur.com",
                                action: { /* E-posta gönderme */ }
                            )
                            
                            SuccessContactInfoRow(
                                icon: "message.fill",
                                title: "WhatsApp",
                                value: "+90 532 555 0123",
                                action: { /* WhatsApp mesajı */ }
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.yellow.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Bilgilendirme kartı
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Önemli Bilgiler")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("• Reklam talebiniz 24 saat içinde incelenecek\n• Teklif e-posta ile gönderilecek\n• Sorularınız için yukarıdaki iletişim kanallarını kullanabilirsiniz\n• Reklam durumunuzu ana sayfadan takip edebilirsiniz")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    
                    // Butonlar
                    VStack(spacing: 16) {
                        Button(action: {
                            onNewRoute?()
                            dismiss()
                        }) {
                            Text("Reklam Listesine Dön")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            showConfetti = true
            animateCheckmark = true
        }
    }
}

// MARK: - Supporting Views

struct NextStepRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
}

struct SuccessContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuccessInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    RouteCreationSuccessView(route: Route.preview, onNewRoute: nil)
} 
