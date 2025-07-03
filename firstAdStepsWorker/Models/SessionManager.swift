import SwiftUI
import Combine

final class SessionManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    
    // MARK: - Device Token
    var deviceToken: String? {
        get { UserDefaults.standard.string(forKey: UserDefaultsKeys.deviceToken) }
        set { 
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: UserDefaultsKeys.deviceToken)
            } else {
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.deviceToken)
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let user = "current_user"
        static let isAuthenticated = "is_authenticated"
        static let deviceToken = "deviceToken"
    }
    
    // MARK: - Singleton
    static let shared = SessionManager()
    
    private init() {
        print("🔐 SessionManager: Başlatılıyor...")
        loadSession()
    }
    
    // MARK: - Session Management
    private func loadSession() {
        if let userData = UserDefaults.standard.data(forKey: UserDefaultsKeys.user),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isAuthenticated)
                print("🔐 SessionManager: Oturum yüklendi - Kullanıcı: \(user.firstName) \(user.lastName)")
                print("🔐 SessionManager: Giriş durumu: \(self.isAuthenticated)")
            }
        } else {
            print("🔐 SessionManager: Kayıtlı oturum bulunamadı")
        }
    }
    
    func setUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.user)
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.isAuthenticated)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = true
                
                print("🔐 SessionManager: Kullanıcı ayarlandı - \(user.firstName) \(user.lastName)")
                print("🔐 SessionManager: Giriş durumu: \(self.isAuthenticated)")
                
                // Kullanıcı giriş yaptığında device token'ı backend'e gönder
                self.sendDeviceTokenToBackend()
            }
        }
    }
    
    func updateCurrentUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.user)
            
            DispatchQueue.main.async {
                self.currentUser = user
                print("🔐 SessionManager: Kullanıcı bilgileri güncellendi: \(user.firstName) \(user.lastName)")
            }
        }
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.user)
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.isAuthenticated)
        
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            print("🔐 SessionManager: Oturum temizlendi")
        }
    }
    
    // MARK: - Device Token Management
    
    /// Device token'ı UserDefaults'tan alır
    func getDeviceToken() -> String? {
        return UserDefaults.standard.string(forKey: UserDefaultsKeys.deviceToken)
    }
    
    /// Device token'ı UserDefaults'a kaydeder
    func saveDeviceToken(_ token: String) {
        print("💾 SessionManager: Device token kaydediliyor...")
        print("🔑 Token: \(token)")
        deviceToken = token
        print("✅ SessionManager: Device token kaydedildi")
    }
    
    /// Device token'ı backend'e gönderir (AuthService kullanarak)
    func sendDeviceTokenToBackend() {
        guard let deviceToken = getDeviceToken(), !deviceToken.isEmpty else {
            print("❌ SessionManager: Device token yok veya boş")
            return
        }
        
        guard let currentUser = currentUser else {
            print("❌ SessionManager: Kullanıcı bilgisi yok")
            return
        }
        
        print("🌐 SessionManager: Device token backend'e gönderiliyor...")
        print("🔑 Gönderilecek token: \(deviceToken)")
        print("👤 User ID: \(currentUser.id)")
        
        AuthService.shared.updateDeviceToken(
            userId: currentUser.id,
            deviceToken: deviceToken
        ) { result in
            switch result {
            case .success(let response):
                if response.status == "success" {
                    print("✅ SessionManager: Device token başarıyla backend'e gönderildi")
                } else {
                    print("❌ SessionManager: Device token gönderilirken backend hatası: \(response.error?.message ?? "Bilinmeyen hata")")
                }
            case .failure(let error):
                print("❌ SessionManager: Device token gönderimi başarısız - \(error.localizedDescription)")
            }
        }
    }
    
    /// Device token'ı temizler (çıkış yaparken)
    func clearDeviceToken() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.deviceToken)
        print("🔐 SessionManager: Device token temizlendi")
    }
}

// MARK: - Supporting Types

