import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var isPermissionGranted = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    private override init() {
        super.init()
        print("🔔 NotificationManager: Başlatılıyor...")
        UNUserNotificationCenter.current().delegate = self
        // İzin kontrolü AppDelegate'te yapılıyor, burada sadece durumu güncelle
        updatePermissionStatus()
    }
    
    // MARK: - Permission Management
    
    func updatePermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
                self.authorizationStatus = settings.authorizationStatus
                print("🔔 NotificationManager: İzin durumu güncellendi - \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func requestNotificationPermission() {
        print("🔔 NotificationManager: İzin isteniyor...")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ NotificationManager: İzin verildi!")
                    self.isPermissionGranted = true
                    self.registerForRemoteNotifications()
                } else {
                    print("❌ NotificationManager: İzin reddedildi")
                    self.isPermissionGranted = false
                    if let error = error {
                        print("❌ NotificationManager: Hata: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func registerForRemoteNotifications() {
        print("🔔 NotificationManager: Remote notification kaydı yapılıyor...")
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            print("🔔 NotificationManager: registerForRemoteNotifications çağrıldı")
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 NotificationManager: Uygulama açıkken notification alındı")
        print("📋 Notification: \(notification.request.content.title)")
        
        // Uygulama açıkken de notification göster
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 NotificationManager: Notification'a tıklandı")
        print("📋 Notification: \(response.notification.request.content.title)")
        
        // Notification'a tıklandığında yapılacak işlemler
        handleNotificationTap(response.notification)
        
        completionHandler()
    }
    
    private func handleNotificationTap(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        print("🔔 NotificationManager: Notification işleniyor...")
        print("📋 UserInfo: \(userInfo)")
        
        // Deep link kontrolü
        if let deepLink = userInfo["deepLink"] as? String {
            print("🔗 Deep link tespit edildi: \(deepLink)")
            handleDeepLink(deepLink)
            return
        }
        
        // Notification tipine göre işlem yap
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "adRequestPlanReady":
                // Reklam planı hazır bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .adRequestPlanReadyTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            case "routeStarted":
                // Rota başladı bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeStartedTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            case "routeCompleted":
                // Rota tamamlandı bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeCompletedTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            case "reportReady":
                // Rapor hazır bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .reportReadyTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            case "paymentPending":
                // Ödeme bekliyor bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .paymentPendingTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            case "readyToStart":
                // Rota başlamaya hazır bildirimi
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .readyToStartTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            default:
                // Genel rota bildirimi (geriye uyumluluk)
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeNotificationTapped,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                    navigateToRoute(routeId)
                }
            }
        } else {
            // Eski format - genel rota bildirimi
            if let routeId = userInfo["routeId"] as? String {
                NotificationCenter.default.post(
                    name: .routeNotificationTapped,
                    object: nil,
                    userInfo: ["routeId": routeId]
                )
                navigateToRoute(routeId)
            }
        }
    }
    
    private func handleDeepLink(_ deepLink: String) {
        print("🔗 Deep link işleniyor: \(deepLink)")
        
        // URL formatı: firstadsteps://route/123
        if let url = URL(string: deepLink) {
            let components = url.pathComponents
            if components.count >= 2 && components[1] == "route" {
                let routeId = components[2]
                print("🔗 Route ID çıkarıldı: \(routeId)")
                navigateToRoute(routeId)
            }
        }
    }
    
    // MARK: - Remote Notifications (Backend'den Gelen Push Notifications)
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // Backend'den gelen push notification'ı işle
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "adRequestPlanReady":
                // Reklam planı hazır push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .adRequestPlanReadyReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            case "routeStarted":
                // Rota başladı push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeStartedReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            case "routeCompleted":
                // Rota tamamlandı push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeCompletedReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            case "reportReady":
                // Rapor hazır push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .reportReadyReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            case "paymentPending":
                // Ödeme bekliyor push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .paymentPendingReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            case "readyToStart":
                // Rota başlamaya hazır push notification'ı
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .readyToStartReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            default:
                // Genel rota push notification'ı (geriye uyumluluk)
                if let routeId = userInfo["routeId"] as? String {
                    NotificationCenter.default.post(
                        name: .routeNotificationReceived,
                        object: nil,
                        userInfo: ["routeId": routeId]
                    )
                }
            }
        } else {
            // Eski format - genel rota push notification'ı
            if let routeId = userInfo["routeId"] as? String {
                NotificationCenter.default.post(
                    name: .routeNotificationReceived,
                    object: nil,
                    userInfo: ["routeId": routeId]
                )
            }
        }
    }
    
    // MARK: - Notification Management
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removeNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func getPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
            }
        }
    }
    
    // MARK: - Delivered Notifications (Apple'ın Yerleşik Sistemi)
    
    func getDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                print("📱 Teslim edilen notification sayısı: \(notifications.count)")
                
                for notification in notifications {
                    print("📋 Notification: \(notification.request.content.title)")
                    print("📋 Body: \(notification.request.content.body)")
                    print("📋 UserInfo: \(notification.request.content.userInfo)")
                    print("📋 Date: \(notification.date)")
                    print("---")
                }
                
                completion(notifications)
            }
        }
    }
    
    func clearAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🗑️ Tüm teslim edilen notification'lar temizlendi")
    }
    
    func clearDeliveredNotification(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        print("🗑️ Notification temizlendi: \(identifier)")
    }
    
    // MARK: - Deep Link Navigation
    
    private func navigateToRoute(_ routeId: String) {
        print("🔗 Route'a yönlendiriliyor: \(routeId)")
        
        // Ana view'a route ID'yi gönder
        NotificationCenter.default.post(
            name: .navigateToRoute,
            object: nil,
            userInfo: ["routeId": routeId]
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    // Local Notification Tapped
    static let adRequestPlanReadyTapped = Notification.Name("adRequestPlanReadyTapped")
    static let routeStartedTapped = Notification.Name("routeStartedTapped")
    static let routeCompletedTapped = Notification.Name("routeCompletedTapped")
    static let reportReadyTapped = Notification.Name("reportReadyTapped")
    static let paymentPendingTapped = Notification.Name("paymentPendingTapped")
    static let readyToStartTapped = Notification.Name("readyToStartTapped")
    static let routeNotificationTapped = Notification.Name("routeNotificationTapped")
    
    // Remote Notification Received
    static let adRequestPlanReadyReceived = Notification.Name("adRequestPlanReadyReceived")
    static let routeStartedReceived = Notification.Name("routeStartedReceived")
    static let routeCompletedReceived = Notification.Name("routeCompletedReceived")
    static let reportReadyReceived = Notification.Name("reportReadyReceived")
    static let paymentPendingReceived = Notification.Name("paymentPendingReceived")
    static let readyToStartReceived = Notification.Name("readyToStartReceived")
    static let routeNotificationReceived = Notification.Name("routeNotificationReceived")
    
    // Deep Link ve Navigation
    static let deepLinkToRoute = Notification.Name("deepLinkToRoute")
    static let navigateToRoute = Notification.Name("navigateToRoute")
} 