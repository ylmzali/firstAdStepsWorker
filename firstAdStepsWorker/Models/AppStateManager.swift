import SwiftUI
import Combine

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var tabBarHidden: Bool = false
    @Published var isFirstLaunch: Bool
    @Published var isOnboardingCompleted: Bool
    @Published var selectedLanguage: String
    @Published var isDarkMode: Bool
    @Published var isNetworkAvailable: Bool = true
    @Published var isAppActive: Bool = true
    
    private init() {
        // İlk kurulum kontrolü
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "isFirstLaunch")
        self.isFirstLaunch = !hasLaunchedBefore
        
        // Onboarding durumu
        self.isOnboardingCompleted = UserDefaults.standard.bool(forKey: "isOnboardingCompleted")
        
        // Dil ayarı
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "tr"
        
        // Tema ayarı
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        // İlk kurulum kaydı
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        }
        
        // Network durumu dinleyicisi
        setupNetworkMonitoring()
        
        // Property observers'ları ekle
        setupPropertyObservers()
    }
    
    private func setupPropertyObservers() {
        // isFirstLaunch observer
        objectWillChange.sink { [weak self] _ in
            if let isFirstLaunch = self?.isFirstLaunch {
                UserDefaults.standard.set(isFirstLaunch, forKey: "isFirstLaunch")
            }
        }.store(in: &cancellables)
        
        // isOnboardingCompleted observer
        objectWillChange.sink { [weak self] _ in
            if let isOnboardingCompleted = self?.isOnboardingCompleted {
                UserDefaults.standard.set(isOnboardingCompleted, forKey: "isOnboardingCompleted")
            }
        }.store(in: &cancellables)
        
        // selectedLanguage observer
        objectWillChange.sink { [weak self] _ in
            if let selectedLanguage = self?.selectedLanguage {
                UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
                self?.updateLanguage()
            }
        }.store(in: &cancellables)
        
        // isDarkMode observer
        objectWillChange.sink { [weak self] _ in
            if let isDarkMode = self?.isDarkMode {
                UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
                self?.updateAppearance()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func setupNetworkMonitoring() {
        // Network durumu değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkStatusChanged,
            object: nil
        )
    }
    
    @objc private func networkStatusChanged(_ notification: Notification) {
        if let isConnected = notification.userInfo?["isConnected"] as? Bool {
            DispatchQueue.main.async {
                self.isNetworkAvailable = isConnected
            }
        }
    }
    
    private func updateLanguage() {
        // Dil değişikliğini uygula
        Bundle.setLanguage(selectedLanguage)
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    private func updateAppearance() {
        // Tema değişikliğini uygula
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    func resetAppState() {
        // Uygulama durumunu sıfırla
        isOnboardingCompleted = false
        selectedLanguage = "tr"
        isDarkMode = false
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Bundle Extension
extension Bundle {
    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, AnyLanguageBundle.self)
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle.main.path(forResource: language, ofType: "lproj"), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

var bundleKey: UInt8 = 0

class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
} 