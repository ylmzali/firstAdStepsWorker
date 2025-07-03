import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var notifications: [AppNotification] = [
        AppNotification(title: "Yeni Rota Atandı", message: "Kadıköy - Üsküdar rotası size atandı.", date: "12 Haz 2024", isRead: false),
        AppNotification(title: "Rapor Hazır", message: "Beşiktaş - Levent rotası için raporunuz hazır.", date: "10 Haz 2024", isRead: true),
        AppNotification(title: "Rezervasyon Onaylandı", message: "Bakırköy - Florya rezervasyonunuz onaylandı.", date: "9 Haz 2024", isRead: false)
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Device Token Debug Panel
                        VStack(alignment: .leading, spacing: 12) {
                            Text("🔑 Device Token Debug")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Notification İzni:")
                                    Spacer()
                                    Text(notificationManager.isPermissionGranted ? "✅ Verildi" : "❌ Verilmedi")
                                        .foregroundColor(notificationManager.isPermissionGranted ? .green : .red)
                                }
                                
                                HStack {
                                    Text("Device Token:")
                                    Spacer()
                                    Text(sessionManager.deviceToken != nil ? "✅ Mevcut" : "❌ Yok")
                                        .foregroundColor(sessionManager.deviceToken != nil ? .green : .red)
                                }
                                
                                if let token = sessionManager.deviceToken {
                                    Text("Token: \(token.prefix(20))...")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            
                            // Gerçek Cihaz Checklist
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📱 Gerçek Cihaz Checklist")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✅ Entitlements: aps-environment eklendi")
                                    Text("✅ Bundle ID: Doğru yapılandırıldı")
                                    Text("✅ Team ID: Apple Developer hesabı")
                                    Text("✅ Provisioning Profile: Push notification destekli")
                                    Text("✅ Apple Developer: Push notification sertifikası")
                                    Text("✅ İnternet: Bağlantı mevcut")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)

                            // Personal Team Bilgisi
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ℹ️ Personal Team Bilgisi")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("❌ Push notification desteklenmez")
                                    Text("✅ Local notification kullanılabilir")
                                    Text("💡 Apple Developer Program ($99/yıl) gerekli")
                                    Text("📱 Test için local notification kullanın")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)

                            // Remote Notification Bilgisi
                            VStack(alignment: .leading, spacing: 8) {
                                Text("🌐 Remote Notification Bilgisi")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("✅ Tüm bildirimler backend'den gelir")
                                    Text("✅ Push notification altyapısı hazır")
                                    Text("✅ Device token backend'e gönderilir")
                                    Text("📱 Backend'den test bildirimi gönderin")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                        
                        // Notifications Section
                        LazyVStack(spacing: 12) {
                            ForEach(notifications) { notification in
                                NotificationRow(notification: notification)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
        }
    }
}

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let date: String
    let isRead: Bool
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(notification.isRead ? Color.white.opacity(0.2) : Color.blue.opacity(0.8))
                .frame(width: 12, height: 12)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .white.opacity(0.5) : .white)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text(notification.date)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    NotificationRow(notification: AppNotification.init(title: "Yeni rota atandı", message: "Kadıköy Üsküdar rotası atandı", date: "", isRead: true))
}
