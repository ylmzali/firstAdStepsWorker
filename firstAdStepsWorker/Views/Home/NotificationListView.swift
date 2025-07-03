import SwiftUI
import UserNotifications

struct NotificationListView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var notifications: [UNNotification] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Group {
                    if isLoading {
                        VStack {
                            ProgressView("Bildirimler yükleniyor...")
                                .foregroundColor(.gray)
                                .scaleEffect(1.2)
                        }
                    } else if notifications.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Henüz bildirim yok")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Yeni bildirimler geldiğinde burada görünecek")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(notifications, id: \.request.identifier) { notification in
                                    NotificationRowView(notification: notification)
                                        .onTapGesture {
                                            handleNotificationTap(notification)
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        }
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button("Yenile") {
                            loadNotifications()
                        }
                        .foregroundColor(.blue)
                        .font(.subheadline)
                        
                        Button("Temizle") {
                            clearAllNotifications()
                        }
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .disabled(notifications.isEmpty)
                    }
                }
            }
            .onAppear {
                loadNotifications()
            }
        }
    }
    
    private func loadNotifications() {
        guard !isLoading else {
            print("📱 NotificationListView: Zaten yükleniyor, yeni istek yapılmıyor")
            return
        }
        
        isLoading = true
        print("📱 NotificationListView: Notification'lar yükleniyor...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notificationManager.getDeliveredNotifications { notifications in
                DispatchQueue.main.async {
                    self.notifications = notifications
                    self.isLoading = false
                    print("📱 NotificationListView: \(notifications.count) notification yüklendi")
                }
            }
        }
    }
    
    private func handleNotificationTap(_ notification: UNNotification) {
        print("📱 Notification'a tıklandı: \(notification.request.content.title)")
        
        // Deep link işlemi
        if let routeId = notification.request.content.userInfo["routeId"] as? String {
            navigateToRoute(routeId)
        }
    }
    
    private func navigateToRoute(_ routeId: String) {
        print("🔗 Route'a yönlendiriliyor: \(routeId)")
        
        // Ana view'a route ID'yi gönder
        NotificationCenter.default.post(
            name: .navigateToRoute,
            object: nil,
            userInfo: ["routeId": routeId]
        )
    }
    
    private func clearAllNotifications() {
        notificationManager.clearAllDeliveredNotifications()
        notifications.removeAll()
    }
}

struct NotificationRowView: View {
    let notification: UNNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(getNotificationColor())
                .frame(width: 12, height: 12)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.request.content.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(notification.request.content.body)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
                
                HStack {
                    Text(formatDate(notification.date))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if let routeId = notification.request.content.userInfo["routeId"] as? String {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                                .font(.caption2)
                            
                            Text("Rota #\(routeId)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
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
    
    private func getNotificationColor() -> Color {
        if let notificationType = notification.request.content.userInfo["notificationType"] as? String {
            switch notificationType {
            case "routeStarted":
                return .green
            case "routeCompleted":
                return .purple
            case "reportReady":
                return .orange
            case "paymentPending":
                return .red
            case "readyToStart":
                return .yellow
            case "routePlanReady":
                return .cyan
            default:
                return .white.opacity(0.8)
            }
        }
        return .white.opacity(0.8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationListView()
        .environmentObject(NotificationManager.shared)
        .preferredColorScheme(.dark)
} 