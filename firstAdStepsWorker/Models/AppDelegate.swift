import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("🚀 AppDelegate: Uygulama başlatılıyor...")
        
        // Uygulama başlangıç ayarları
        setupAppearance()
        
        // Notification izinlerini kontrol et ve gerekirse iste
        checkAndRequestNotificationPermissions()
        
        return true
    }
    
    private func setupAppearance() {
        print("🎨 AppDelegate: Görünüm ayarları yapılıyor...")
        // Navigation bar görünümü
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color("Background"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    // MARK: - Notification Permission Management
    
    private func checkAndRequestNotificationPermissions() {
        print("🔔 AppDelegate: Notification izinleri kontrol ediliyor...")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("🔔 AppDelegate: Mevcut izin durumu: \(settings.authorizationStatus.rawValue)")
                
                switch settings.authorizationStatus {
                case .notDetermined:
                    print("🔔 AppDelegate: İzin henüz belirlenmemiş, izin isteniyor...")
                    self.requestNotificationPermission()
                    
                case .denied:
                    print("🔔 AppDelegate: İzin reddedilmiş")
                    // Kullanıcıya ayarlardan izin vermesi için bilgi verilebilir
                    
                case .authorized:
                    print("🔔 AppDelegate: İzin zaten verilmiş, remote notification kaydı yapılıyor...")
                    self.registerForRemoteNotifications()
                    
                case .provisional:
                    print("🔔 AppDelegate: Geçici izin var, remote notification kaydı yapılıyor...")
                    self.registerForRemoteNotifications()
                    
                case .ephemeral:
                    print("🔔 AppDelegate: Geçici izin var, remote notification kaydı yapılıyor...")
                    self.registerForRemoteNotifications()
                    
                @unknown default:
                    print("🔔 AppDelegate: Bilinmeyen izin durumu")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        print("🔔 AppDelegate: Notification izni isteniyor...")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ AppDelegate: Notification izni verildi!")
                    self.registerForRemoteNotifications()
                } else {
                    print("❌ AppDelegate: Notification izni reddedildi")
                    if let error = error {
                        print("❌ AppDelegate: İzin hatası: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        print("🔔 AppDelegate: registerForRemoteNotifications çağrılıyor...")
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            print("🔔 AppDelegate: registerForRemoteNotifications çağrıldı")
        }
    }
    
    // MARK: - Device Token Management
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ AppDelegate: Device token alındı!")
        
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("🔑 Device Token: \(tokenString)")
        
        // SessionManager'a kaydet
        SessionManager.shared.saveDeviceToken(tokenString)
        
        // Backend'e gönder
        SessionManager.shared.sendDeviceTokenToBackend()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ AppDelegate: Remote notification kaydı başarısız!")
        print("❌ Hata: \(error.localizedDescription)")
        
        // Detaylı hata analizi
        let nsError = error as NSError
        print("🔍 Hata Domain: \(nsError.domain)")
        print("🔍 Hata Code: \(nsError.code)")
        print("🔍 Hata Description: \(nsError.localizedDescription)")
        
        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            print("🔍 Alt Hata Domain: \(underlyingError.domain)")
            print("🔍 Alt Hata Code: \(underlyingError.code)")
            print("🔍 Alt Hata Description: \(underlyingError.localizedDescription)")
        }
        
        // Yaygın hata kodları ve çözümleri
        switch nsError.code {
        case 3000:
            print("🚨 Hata 3000: Geçersiz provisioning profile")
            print("💡 Çözüm: Xcode'da Signing & Capabilities'i kontrol edin")
        case 3001:
            print("🚨 Hata 3001: Geçersiz bundle identifier")
            print("💡 Çözüm: Bundle ID'yi kontrol edin")
        case 3002:
            print("🚨 Hata 3002: Geçersiz team identifier")
            print("💡 Çözüm: Team ID'yi kontrol edin")
        case 3003:
            print("🚨 Hata 3003: Push notification capability eksik")
            print("💡 Çözüm: Xcode'da Push Notifications capability'sini ekleyin")
        case 3004:
            print("🚨 Hata 3004: Network bağlantı sorunu")
            print("💡 Çözüm: İnternet bağlantısını kontrol edin")
        default:
            print("🚨 Bilinmeyen hata kodu: \(nsError.code)")
        }
        
        print("📱 Gerçek cihaz tespit edildi - Hata analizi yukarıda gösterildi")
        print("💡 Öneriler:")
        print("   1. Xcode'da Signing & Capabilities'i kontrol edin")
        print("   2. Push Notifications capability'sinin ekli olduğundan emin olun")
        print("   3. Provisioning profile'ın doğru olduğunu kontrol edin")
        print("   4. Bundle ID'nin doğru olduğunu kontrol edin")
        print("   5. İnternet bağlantısını kontrol edin")
        print("   6. Apple Developer hesabınızda push notification sertifikası olduğundan emin olun")
    }
    
    // MARK: - Remote Notification Handling
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔔 AppDelegate: Remote notification alındı")
        print("📋 UserInfo: \(userInfo)")
        
        // NotificationManager'a gönder
        NotificationManager.shared.handleRemoteNotification(userInfo)
        
        completionHandler(.newData)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("🔚 AppDelegate: Uygulama kapatılıyor...")
        // Uygulama kapatılırken yapılacak temizlik işlemleri
        // Örneğin: Log dosyalarını kapatma, geçici dosyaları temizleme vb.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("⬇️ AppDelegate: Uygulama arka plana alındı")
        // Uygulama arka plana alındığında
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("⬆️ AppDelegate: Uygulama ön plana geldi")
        // Uygulama ön plana geldiğinde
    }
    
    // MARK: - Deep Link Handling
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("🔗 AppDelegate: Deep link alındı: \(url)")
        
        // URL'den route ID'yi çıkar
        if let routeId = extractRouteId(from: url) {
            handleDeepLink(routeId: routeId)
        }
        
        return true
    }
    
    private func extractRouteId(from url: URL) -> String? {
        print("🔗 AppDelegate: URL analiz ediliyor: \(url)")
        
        // URL formatı: firstadsteps://route/123
        let components = url.pathComponents
        print("🔗 URL Components: \(components)")
        
        if components.count >= 2 && components[1] == "route" {
            let routeId = components[2]
            print("🔗 AppDelegate: Route ID çıkarıldı: \(routeId)")
            return routeId
        }
        
        print("🔗 AppDelegate: Route ID bulunamadı")
        return nil
    }
    
    private func handleDeepLink(routeId: String) {
        print("🔗 AppDelegate: Route ID: \(routeId) için deep link işleniyor")
        
        // NotificationCenter ile route'a yönlendir
        NotificationCenter.default.post(
            name: .deepLinkToRoute,
            object: nil,
            userInfo: ["routeId": routeId]
        )
    }
} 