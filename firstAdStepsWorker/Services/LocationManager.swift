import Foundation
import CoreLocation
import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let locationUpdated = Notification.Name("locationUpdated")
    static let routeLocationUpdated = Notification.Name("routeLocationUpdated")
}

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private let activeTrackingKey = "ActiveTrackingInfo"
    
    // MARK: - Properties
    @Published var currentLocation: CLLocation?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRouteTracking = false
    @Published var activeScheduleId: String?
    @Published var currentRoute: Assignment?
    @Published var trackingStartDate: Date?
    @Published var routeLocations: [LocationData] = []
    @Published var lastLocationUpdate: Date?
    
    // WorkTimeManager entegrasyonu
    private let workTimeManager = WorkTimeManager.shared
    
    // Background task management
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer?
    
    // Route completion timer
    private var routeCompletionTimer: Timer?
    
    // Location history for tracking
    private var locationHistory: [CLLocation] = []
    
    // Pending location data kaldırıldı - artık toplu gönderim sistemi kullanılıyor
    
    // Toplu konum gönderimi için buffer
    private var locationBuffer: [LocationPoint] = []
    private let maxBufferSize = 15 // Maksimum 15 konum tut
    private var bulkSendTimer: Timer?
    private let bulkSendInterval: TimeInterval = 30.0 // 30 saniyede bir gönder
    private var locationCollectionTimer: Timer?
    private let locationCollectionInterval: TimeInterval = 5.0 // 5 saniyede bir konum topla
    
    // Konum gruplandırma için geçici buffer
    private var tempLocationBuffer: [LocationPoint] = []
    private let groupingDistanceThreshold: Double = 10.0 // 10 metre içindeki konumları grupla
    private let groupingTimeThreshold: TimeInterval = 60.0 // 60 saniye içindeki konumları grupla
    private let minSpeedThreshold: Double = 1.0 // 1 m/s altındaki hızları durma olarak kabul et
    
    // Public property for pending location data count (kaldırıldı)
    var pendingLocationDataCount: Int {
        return 0 // Artık kullanılmıyor
    }
    
    // Public property for smart filtering status
    var smartFilteringEnabled: Bool {
        get { return isSmartFilteringEnabled }
        set(newValue) {
            isSmartFilteringEnabled = newValue
            // UserDefaults'a kaydet
            UserDefaults.standard.set(newValue, forKey: "smartFilteringEnabled")
            print("🔧 [LocationManager] Smart filtering \(newValue ? "açıldı" : "kapatıldı")")
        }
    }
    
    // Public property for route pause status
    var isRoutePaused: Bool {
        guard let currentRoute = currentRoute else { return false }
        return currentRoute.workStatus == "paused"
    }
    
    // Public property for total distance
    var totalDistance: Double {
        return calculateTotalDistance() / 1000.0 // metre'den km'ye çevir
    }
    
    // Public property for average speed
    var averageSpeed: Double {
        guard !locationHistory.isEmpty else { return 0.0 }
        let totalDistance = calculateTotalDistance()
        let totalTime = locationHistory.last?.timestamp.timeIntervalSince(locationHistory.first?.timestamp ?? Date()) ?? 0
        return totalTime > 0 ? (totalDistance / totalTime) * 3.6 : 0.0 // m/s'den km/h'ye çevir
    }
    
    // MARK: - Smart Location Filtering
    private var lastSentLocation: CLLocation?
    private var lastSentHeading: Double = 0.0
    private var lastSentSpeed: Double = 0.0
    private var lastSentTime: Date?
    
    // Smart filtering configuration
    @Published private var isSmartFilteringEnabled: Bool = true
    private var minDistanceForSending: Double = 3.0 // 3 metre
    private var minHeadingChange: Double = 15.0 // 15 derece
    private var minSpeedChange: Double = 2.0 // 2 m/s
    private var maxTimeInterval: TimeInterval = 60.0 // 60 saniye
    private var minAccuracy: Double = 20.0 // 20 metre
    
    override init() {
        super.init()
        setupLocationManager()
        setupNotificationObservers()
        loadSmartFilteringSettings()
        checkExistingTrackingStatus()
        setupBulkSendTimer()
        setupLocationCollectionTimer()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc public func appDidEnterBackground() {
        print("🔄 [LocationManager] Uygulama background'a geçiyor")
        
        if isRouteTracking {
            // Background task başlat
            startBackgroundTask()
            startBackgroundMonitoring()
            
            // Background'da konum güncellemelerini devam ettir
            print("🔄 [LocationManager] Background'da konum takibi devam ediyor")
            locationManager.startUpdatingLocation()
            
            // İlk konum gönderimini hemen yap
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.sendLocationToServer()
            }
        }
    }
    
    @objc public func appWillEnterForeground() {
        endBackgroundTask()
        
        // Artık pending location data kullanılmıyor, toplu gönderim sistemi kullanılıyor
        print("ℹ️ [LocationManager] Uygulama foreground'a geldi, toplu gönderim sistemi aktif")
    }
    
    @objc private func appWillTerminate() {
        if isRouteTracking {
            saveActiveTrackingInfo(ActiveTrackingInfo(
                routeId: currentRoute?.routeId ?? "",
                assignmentId: currentRoute?.assignmentId ?? "",
                employeeId: currentRoute?.assignmentEmployeeId ?? "",
                startTime: trackingStartDate ?? Date(),
                endTime: getRouteEndDate() ?? Date(),
                status: "working",
                lastLocationUpdate: lastLocationUpdate
            ))
            
            // Son konum gönderimi
            sendLocationToServer()
        }
    }
    
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "RouteTracking") {
            print("⚠️ [LocationManager] Background task süresi doldu")
            self.endBackgroundTask()
        }
        
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
        print("🔄 [LocationManager] Background task başlatıldı: \(backgroundTaskID.rawValue), kalan süre: \(remainingTime) saniye")
        LogManager.shared.log("Background task başlatıldı: \(backgroundTaskID.rawValue), kalan süre: \(remainingTime) saniye")
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
            LogManager.shared.log("Background task sonlandırıldı")
        }
    }
    
    private func startBackgroundMonitoring() {
        print("🔄 [LocationManager] startBackgroundMonitoring çağrıldı")
        print("🔄 [LocationManager] Mevcut background timer: \(backgroundTimer != nil ? "Aktif" : "Nil")")
        
        stopBackgroundMonitoring()
        
        print("🔄 [LocationManager] Yeni background timer oluşturuluyor...")
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.checkActiveTrackingInBackground()
        }
        
        print("🔄 [LocationManager] Background timer oluşturuldu: \(backgroundTimer != nil ? "Başarılı" : "Başarısız")")
        
        // İlk kontrolü hemen yap
        print("🔄 [LocationManager] İlk background kontrolü yapılıyor...")
        checkActiveTrackingInBackground()
        
        LogManager.shared.log("Background monitoring başlatıldı")
    }
    
    private func stopBackgroundMonitoring() {
        print("🛑 [LocationManager] stopBackgroundMonitoring çağrıldı")
        print("🛑 [LocationManager] Background timer durumu: \(backgroundTimer != nil ? "Aktif" : "Nil")")
        
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        
        print("🛑 [LocationManager] Background timer durduruldu")
        LogManager.shared.log("Background monitoring durduruldu")
    }
    
    private func checkActiveTrackingInBackground() {
        print("🔍 [LocationManager] checkActiveTrackingInBackground çağrıldı")
        
        guard let info = loadActiveTrackingInfo() else {
            print("❌ [LocationManager] Active tracking info bulunamadı")
            return
        }
        
        print("🔍 [LocationManager] Active tracking info durumu:")
        print("🔍 [LocationManager] - Status: \(info.status)")
        print("🔍 [LocationManager] - Is Expired: \(info.isExpired)")
        print("🔍 [LocationManager] - Is Time Active: \(info.isTimeActive)")
        
        guard info.status == "working",
              !info.isExpired,
              info.isTimeActive else {
            print("❌ [LocationManager] Background tracking koşulları sağlanmıyor")
            
            // Eğer zaman dolmuşsa otomatik tamamla
            if info.isExpired || !info.isTimeActive {
                print("⏰ [LocationManager] Rota zamanı dolmuş, background'da otomatik tamamlama")
                autoCompleteRoute()
            }
            return
        }
        
        print("✅ [LocationManager] Background tracking koşulları sağlandı")
        
        // Son güncelleme zamanını kontrol et (10 saniye minimum aralık)
        if let lastUpdate = info.lastLocationUpdate {
            let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
            print("🔍 [LocationManager] Son güncelleme: \(timeSinceLastUpdate) saniye önce")
            
            if timeSinceLastUpdate < 10 {
                print("⏳ [LocationManager] Çok yakın zamanda güncelleme yapılmış, bekleniyor")
                return
            }
        }
        
        print("✅ [LocationManager] Konum gönderme koşulları sağlandı")
        
        // Konum gönder (zaten mevcut konum varsa)
        if currentLocation != nil {
            print("📍 [LocationManager] Mevcut konum var, gönderiliyor")
            LogManager.shared.log("Background'da konum gönderiliyor")
            sendLocationToServer()
        } else {
            print("📍 [LocationManager] Mevcut konum yok, konum güncellemeleri başlatılıyor")
            LogManager.shared.log("Background'da konum yok, konum güncellemeleri başlatılıyor")
            locationManager.startUpdatingLocation()
            
            // 5 saniye sonra tekrar dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if self.currentLocation != nil {
                    print("📍 [LocationManager] Konum alındı, gönderiliyor")
                    LogManager.shared.log("Konum alındı, gönderiliyor")
                    self.sendLocationToServer()
                } else {
                    print("❌ [LocationManager] 5 saniye sonra konum alınamadı")
                }
            }
        }
    }
    
    private func completeTrackingFromBackground() {
        LogManager.shared.log("Background'dan tracking tamamlanıyor")
        updateAssignmentWorkStatus(status: "completed")
        clearActiveTrackingInfo()
        isRouteTracking = false
        activeScheduleId = nil
        stopBackgroundMonitoring()
    }
    
    // MARK: - Public Methods
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    func startRouteTracking(route: Assignment) {
        print("🚀 [LocationManager] startRouteTracking çağrıldı")
        print("🚀 [LocationManager] Route ID: \(route.id)")
        print("🚀 [LocationManager] Assignment ID: \(route.assignmentId)")
        print("🚀 [LocationManager] Employee ID: \(route.assignmentEmployeeId)")
        
        currentRoute = route
        activeScheduleId = route.id
        isRouteTracking = true
        trackingStartDate = Date()
        
        print("🚀 [LocationManager] State güncellendi - isRouteTracking: \(isRouteTracking)")
        
        // WorkTimeManager ile çalışma zamanını başlat
        workTimeManager.startWork(assignment: route)
        
        locationManager.startUpdatingLocation()
        print("🚀 [LocationManager] Location updates başlatıldı")
        
        // ActiveTrackingInfo kaydet
        let trackingInfo = ActiveTrackingInfo(
            routeId: route.routeId,
            assignmentId: route.assignmentId,
            employeeId: route.assignmentEmployeeId,
            startTime: getRouteStartDate() ?? Date(),
            endTime: getRouteEndDate() ?? Date(),
            status: "working"
        )
        saveActiveTrackingInfo(trackingInfo)
        print("🚀 [LocationManager] ActiveTrackingInfo kaydedildi")
        
        // Work status güncelle
        print("🚀 [LocationManager] Work status güncelleniyor...")
        updateAssignmentWorkStatus(status: "working")
        
        startBackgroundMonitoring()
        print("🚀 [LocationManager] Background monitoring başlatıldı")
        
        // Konum toplama timer'ını başlat
        startLocationCollectionTimer()
        print("🚀 [LocationManager] Konum toplama timer'ı başlatıldı")
        
        // Toplu konum gönderimi timer'ını başlat
        startBulkSendTimer()
        print("🚀 [LocationManager] Toplu konum gönderimi timer'ı başlatıldı")
        
        // Rota tamamlama timer'ını başlat
        startRouteCompletionTimer()
        print("🚀 [LocationManager] Rota tamamlama timer'ı başlatıldı")
        
        LogManager.shared.log("Schedule tracking başlatıldı - Schedule ID: \(route.id), Assignment ID: \(route.assignmentId)")
    }
    
    func stopRouteTracking() {
        // Buffer'daki konumları hemen gönder
        sendBulkLocations(status: "paused")
        
        // WorkTimeManager ile çalışmayı duraklat
        workTimeManager.pauseWork()
        
        updateActiveTrackingInfo(status: "paused")
        isRouteTracking = false
        activeScheduleId = nil
        stopBackgroundMonitoring()
        stopLocationCollectionTimer()
        stopBulkSendTimer()
        stopRouteCompletionTimer()
        
        updateAssignmentWorkStatus(status: "paused")
        
        LogManager.shared.log("Route tracking duraklatıldı")
    }
    
    func completeRouteTracking() {
        print("🔴 [LocationManager] completeRouteTracking çağrıldı")
        
        // Buffer'daki konumları hemen gönder
        sendBulkLocations(status: "completed")
        
        // WorkTimeManager ile çalışmayı tamamla
        workTimeManager.completeWork()
        
        updateAssignmentWorkStatus(status: "completed")
        clearActiveTrackingInfo()
        isRouteTracking = false
        activeScheduleId = nil
        stopBackgroundMonitoring()
        stopLocationCollectionTimer()
        stopBulkSendTimer()
        stopRouteCompletionTimer()
        
        LogManager.shared.log("Route tracking tamamlandı")
        print("🔴 [LocationManager] completeRouteTracking tamamlandı")
    }
    
    func sendLocationToServer(status: String = "active") {
        // Eski tek tek gönderim sistemi kapatıldı
        // Artık sadece toplu gönderim sistemi kullanılıyor
        print("ℹ️ [LocationManager] Eski tek tek gönderim sistemi kapatıldı, toplu gönderim sistemi kullanılıyor")
        
        // Sadece durma/tamamlama durumlarında hemen gönderim yap
        if status == "paused" || status == "completed" {
            print("🚨 [LocationManager] Acil durum gönderimi - Status: \(status)")
            sendBulkLocations(status: status)
        }
    }
    
    // Eski tek tek gönderim metodu kaldırıldı - artık toplu gönderim kullanılıyor
    
    // MARK: - Pending Location Data Management (Kaldırıldı - Artık Kullanılmıyor)
    
    private func loadSmartFilteringSettings() {
        let savedValue = UserDefaults.standard.bool(forKey: "smartFilteringEnabled")
        isSmartFilteringEnabled = savedValue
        print("🔧 [LocationManager] Smart filtering ayarı yüklendi: \(isSmartFilteringEnabled ? "Açık" : "Kapalı")")
    }
    
    private func updateAssignmentWorkStatus(status: String) {
        print("📡 [LocationManager] updateAssignmentWorkStatus çağrıldı - Status: \(status)")
        
        guard let currentRoute = currentRoute else {
            print("❌ [LocationManager] currentRoute bulunamadı")
            LogManager.shared.log("Work status güncelleme için gerekli veriler eksik")
            return
        }
        
        guard let employeeId = SessionManager.shared.currentUser?.id else {
            print("❌ [LocationManager] employeeId bulunamadı")
            LogManager.shared.log("Work status güncelleme için gerekli veriler eksik")
            return
        }
        
        print("✅ [LocationManager] Gerekli veriler mevcut")
        print("📡 [LocationManager] Employee ID: \(employeeId)")
        print("📡 [LocationManager] Assignment ID: \(currentRoute.assignmentId)")
        print("📡 [LocationManager] Work Status: \(status)")
        
        let parameters: [String: Any] = [
            "employee_id": employeeId,
            "assignment_id": currentRoute.assignmentId,
            "work_status": status
        ]
        
        print("📡 [LocationManager] API parametreleri hazırlandı: \(parameters)")
        sendWorkStatusToAPI(parameters: parameters)
        
        // Notification gönder
        print("📡 [LocationManager] WorkStatusUpdated notification gönderiliyor")
        NotificationCenter.default.post(
            name: NSNotification.Name("WorkStatusUpdated"),
            object: nil,
            userInfo: [
                "schedule_id": currentRoute.id,
                "work_status": status
            ]
        )
    }
    
    private func sendWorkStatusToAPI(parameters: [String: Any]) {
        print("🌐 [LocationManager] sendWorkStatusToAPI çağrıldı")
        
        let endpoint = AppConfig.API.baseURL + AppConfig.Endpoints.updateAssignmentWorkStatus
        print("🌐 [LocationManager] Endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("❌ [LocationManager] Geçersiz URL: \(endpoint)")
            LogManager.shared.log("Geçersiz work status URL")
            return
        }
        
        print("✅ [LocationManager] URL geçerli: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.API.appToken, forHTTPHeaderField: "app_token")

        print("🌐 [LocationManager] Request headers:")
        print("🌐 [LocationManager] Content-Type: \(request.value(forHTTPHeaderField: "Content-Type") ?? "nil")")
        print("🌐 [LocationManager] Authorization: \(request.value(forHTTPHeaderField: "Authorization")?.prefix(20) ?? "nil")...")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            print("✅ [LocationManager] JSON data hazırlandı: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
            LogManager.shared.log("Work status gönderiliyor: \(parameters["work_status"] ?? "")")
            
            print("🌐 [LocationManager] API çağrısı başlatılıyor...")
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    print("🌐 [LocationManager] API yanıtı alındı")
                    
                    if let error = error {
                        print("❌ [LocationManager] Network hatası: \(error.localizedDescription)")
                        LogManager.shared.log("Work status güncelleme hatası: \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 [LocationManager] HTTP Status Code: \(httpResponse.statusCode)")
                        LogManager.shared.log("Work status yanıtı: \(httpResponse.statusCode)")
                        
                        if let data = data {
                            print("📡 [LocationManager] Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                        }
                        
                        // Work status başarıyla güncellendiğinde rotaları yenilemek için notification gönder
                        if httpResponse.statusCode == 200 {
                            print("✅ [LocationManager] Work status başarıyla güncellendi")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("WorkStatusUpdated"),
                                object: nil,
                                userInfo: [
                                    "assignment_id": parameters["assignment_id"] as? String ?? "",
                                    "status": parameters["work_status"] as? String ?? ""
                                ]
                            )
                        }
                    }
                }
            }.resume()
            print("✅ [LocationManager] API çağrısı başlatıldı")
        } catch {
            print("❌ [LocationManager] JSON encode hatası: \(error)")
            LogManager.shared.log("Work status encode hatası: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func getRouteStartDate() -> Date? {
        guard let currentRoute = currentRoute else { return nil }
        let dateTimeString = "\(currentRoute.scheduleDate) \(currentRoute.startTime)"
        return DateFormatter.dateFromDateTime(dateTimeString)
    }
    
    private func getRouteEndDate() -> Date? {
        guard let currentRoute = currentRoute else { return nil }
        let dateTimeString = "\(currentRoute.scheduleDate) \(currentRoute.endTime)"
        return DateFormatter.dateFromDateTime(dateTimeString)
    }
    
    private func isRouteTimeActive() -> Bool {
        guard let startDate = getRouteStartDate(),
              let endDate = getRouteEndDate() else {
            return false
        }
        
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    private func checkRouteTimeAndAutoComplete() {
        if !isRouteTimeActive() && isRouteTracking {
            LogManager.shared.log("Rota zamanı doldu, otomatik tamamlama")
            completeRouteTracking()
        }
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return formatter.string(from: date)
    }
    
    private func getSignalStrength() -> Int {
        return 4 // Default değer
    }
    
    private func calculateActualDuration() -> Int {
        guard let startDate = trackingStartDate else { return 0 }
        return Int(Date().timeIntervalSince(startDate) / 60)
    }
    
    private func calculateDistanceFromPrevious() -> Double {
        guard locationHistory.count >= 2 else { return 0 }
        let previous = locationHistory[locationHistory.count - 2]
        return currentLocation?.distance(from: previous) ?? 0
    }
    
    private func calculateTotalDistance() -> Double {
        guard locationHistory.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 0..<(locationHistory.count - 1) {
            total += locationHistory[i].distance(from: locationHistory[i + 1])
        }
        return total
    }
    
    func getRouteLocations() -> [LocationData] {
        return [] // Şimdilik boş döndür
    }
    
    // MARK: - Local Storage Methods
    func saveActiveTrackingInfo(_ info: ActiveTrackingInfo) {
        do {
            let data = try JSONEncoder().encode(info)
            UserDefaults.standard.set(data, forKey: activeTrackingKey)
            LogManager.shared.log("Active tracking info kaydedildi: \(info.routeId)")
        } catch {
            LogManager.shared.log("Active tracking info kaydetme hatası: \(error)")
        }
    }
    
    func loadActiveTrackingInfo() -> ActiveTrackingInfo? {
        guard let data = UserDefaults.standard.data(forKey: activeTrackingKey) else {
            LogManager.shared.log("Active tracking info bulunamadı")
            return nil
        }
        
        do {
            let info = try JSONDecoder().decode(ActiveTrackingInfo.self, from: data)
            LogManager.shared.log("Active tracking info yüklendi: \(info.routeId)")
            return info
        } catch {
            LogManager.shared.log("Active tracking info decode hatası: \(error)")
            return nil
        }
    }
    
    func clearActiveTrackingInfo() {
        UserDefaults.standard.removeObject(forKey: activeTrackingKey)
        LogManager.shared.log("Active tracking info temizlendi")
    }
    
    func clearLocationData() {
        // State'leri temizle
        currentLocation = nil
        isRouteTracking = false
        activeScheduleId = nil
        currentRoute = nil
        trackingStartDate = nil
        lastLocationUpdate = nil
        locationHistory.removeAll()
        
        // Buffer'ları temizle
        locationBuffer.removeAll()
        tempLocationBuffer.removeAll()
        
        // Location manager'ı durdur
        locationManager.stopUpdatingLocation()
        
        // Background monitoring'i durdur
        stopBackgroundMonitoring()
        
        // Konum toplama timer'ını durdur
        stopLocationCollectionTimer()
        
        // Toplu konum gönderimi timer'ını durdur
        stopBulkSendTimer()
        
        LogManager.shared.log("Location data temizlendi")
    }
    
    func updateActiveTrackingInfo(status: String, lastLocationUpdate: Date? = nil) {
        guard let info = loadActiveTrackingInfo() else { return }
        
        let updatedInfo = ActiveTrackingInfo(
            routeId: info.routeId,
            assignmentId: info.assignmentId,
            employeeId: info.employeeId,
            startTime: info.startTime,
            endTime: info.endTime,
            status: status,
            lastLocationUpdate: lastLocationUpdate ?? info.lastLocationUpdate
        )
        
        saveActiveTrackingInfo(updatedInfo)
    }
    
    private func checkExistingTrackingStatus() {
        if let info = loadActiveTrackingInfo(),
           info.status == "working" {
            
            print("🔍 [LocationManager] Mevcut tracking kontrol ediliyor:")
            print("🔍 [LocationManager] - Status: \(info.status)")
            print("🔍 [LocationManager] - Is Expired: \(info.isExpired)")
            print("🔍 [LocationManager] - Is Time Active: \(info.isTimeActive)")
            print("🔍 [LocationManager] - End Time: \(info.endTime)")
            print("🔍 [LocationManager] - Current Time: \(Date())")
            
            // Zaman kontrolü
            if info.isExpired || !info.isTimeActive {
                LogManager.shared.log("Mevcut tracking'in zamanı dolmuş, otomatik tamamlama")
                print("⏰ [LocationManager] Rota zamanı dolmuş, hemen tamamlanıyor")
                autoCompleteRoute()
            } else {
                LogManager.shared.log("Mevcut tracking bulundu, devam ediliyor")
                startBackgroundMonitoring()
            }
        } else {
            print("ℹ️ [LocationManager] Aktif tracking bulunamadı")
        }
    }
    
    // MARK: - Smart Location Filtering Methods
    
    /// Akıllı filtreleme durumunu döndürür
    var smartFilteringStatus: String {
        return isSmartFilteringEnabled ? "Açık" : "Kapalı"
    }
    
    /// Akıllı konum filtreleme sistemini açıp kapatır
    func setSmartFilteringEnabled(_ enabled: Bool) {
        isSmartFilteringEnabled = enabled
        LogManager.shared.log("Akıllı konum filtreleme: \(enabled ? "Açık" : "Kapalı")")
    }
    
    /// Akıllı filtreleme ayarlarını günceller
    func updateSmartFilteringSettings(
        minDistance: Double? = nil,
        minHeadingChange: Double? = nil,
        minSpeedChange: Double? = nil,
        maxTimeInterval: TimeInterval? = nil,
        minAccuracy: Double? = nil
    ) {
        if let minDistance = minDistance { self.minDistanceForSending = minDistance }
        if let minHeadingChange = minHeadingChange { self.minHeadingChange = minHeadingChange }
        if let minSpeedChange = minSpeedChange { self.minSpeedChange = minSpeedChange }
        if let maxTimeInterval = maxTimeInterval { self.maxTimeInterval = maxTimeInterval }
        if let minAccuracy = minAccuracy { self.minAccuracy = minAccuracy }
        
        LogManager.shared.log("Akıllı filtreleme ayarları güncellendi")
    }
    
    /// Yeni konumun gönderilip gönderilmeyeceğini belirler
    private func shouldSendLocation(_ newLocation: CLLocation) -> Bool {
        // Smart filtering kapalıysa her zaman gönder
        guard isSmartFilteringEnabled else {
            print("🔍 [SmartFilter] Filtreleme kapalı - konum gönderiliyor")
            return true
        }
        
        print("🔍 [SmartFilter] Akıllı filtreleme kontrolü başlatıldı")
        
        // 1. İlk konum ise mutlaka gönder
        guard let lastSent = lastSentLocation else {
            print("✅ [SmartFilter] İlk konum - gönderiliyor")
            return true
        }
        
        // 2. Mesafe kontrolü
        let distance = newLocation.distance(from: lastSent)
        print("🔍 [SmartFilter] Mesafe: \(String(format: "%.1f", distance)) metre")
        
        if distance < minDistanceForSending {
            print("❌ [SmartFilter] Mesafe çok yakın (\(String(format: "%.1f", distance))m < \(minDistanceForSending)m)")
            return false
        }
        
        // 3. Zaman kontrolü (çok uzun süre geçtiyse gönder)
        if let lastTime = lastSentTime {
            let timeSinceLast = Date().timeIntervalSince(lastTime)
            if timeSinceLast > maxTimeInterval {
                print("✅ [SmartFilter] Uzun süre geçti (\(String(format: "%.0f", timeSinceLast))s) - gönderiliyor")
                return true
            }
        }
        
        // 4. Önemli nokta kontrolü
        if isImportantLocationPoint(newLocation, lastSent: lastSent) {
            print("✅ [SmartFilter] Önemli nokta - gönderiliyor")
            return true
        }
        
        // 5. Hassasiyet kontrolü
        if newLocation.horizontalAccuracy > minAccuracy {
            print("❌ [SmartFilter] Düşük hassasiyet (\(String(format: "%.1f", newLocation.horizontalAccuracy))m > \(minAccuracy)m)")
            return false
        }
        
        print("❌ [SmartFilter] Filtreleme kriterleri sağlanmıyor - gönderilmiyor")
        return false
    }
    
    /// Konumun önemli bir nokta olup olmadığını belirler
    private func isImportantLocationPoint(_ newLocation: CLLocation, lastSent: CLLocation) -> Bool {
        // 1. Yön değişimi kontrolü
        let headingChange = abs(newLocation.course - lastSentHeading)
        if headingChange > minHeadingChange {
            print("🔍 [SmartFilter] Önemli yön değişimi: \(String(format: "%.1f", headingChange))°")
            return true
        }
        
        // 2. Hız değişimi kontrolü
        let speedChange = abs(newLocation.speed - lastSentSpeed)
        if speedChange > minSpeedChange {
            print("🔍 [SmartFilter] Önemli hız değişimi: \(String(format: "%.1f", speedChange)) m/s")
            return true
        }
        
        // 3. Durma kontrolü (çok yavaş hareket)
        if newLocation.speed < 1.0 && lastSentSpeed > 2.0 {
            print("🔍 [SmartFilter] Durma noktası tespit edildi")
            return true
        }
        
        // 4. Başlangıç hareketi kontrolü
        if newLocation.speed > 2.0 && lastSentSpeed < 1.0 {
            print("🔍 [SmartFilter] Başlangıç hareketi tespit edildi")
            return true
        }
        
        return false
    }
    
    /// Konum gönderildikten sonra son konum bilgilerini günceller
    private func updateLastSentLocation(_ location: CLLocation) {
        lastSentLocation = location
        lastSentHeading = location.course
        lastSentSpeed = location.speed
        lastSentTime = Date()
        
        print("📝 [SmartFilter] Son gönderilen konum güncellendi")
    }
    
    // MARK: - Toplu Konum Gönderimi
    
    /// Toplu konum gönderimi timer'ını başlatır
    private func setupBulkSendTimer() {
        bulkSendTimer = Timer.scheduledTimer(withTimeInterval: bulkSendInterval, repeats: true) { _ in
            if self.isRouteTracking {
                self.sendBulkLocations()
            }
        }
        print("⏰ [LocationManager] Toplu konum gönderimi timer'ı kuruldu - \(bulkSendInterval) saniye aralık")
    }
    
    /// Konum toplama timer'ını başlatır
    private func setupLocationCollectionTimer() {
        locationCollectionTimer = Timer.scheduledTimer(withTimeInterval: locationCollectionInterval, repeats: true) { _ in
            if self.isRouteTracking, let location = self.currentLocation {
                self.addLocationToBuffer(location)
            }
        }
        print("⏰ [LocationManager] Konum toplama timer'ı kuruldu - \(locationCollectionInterval) saniye aralık")
    }
    
    /// Toplu konum gönderimi timer'ını başlatır
    private func startBulkSendTimer() {
        bulkSendTimer?.invalidate()
        bulkSendTimer = Timer.scheduledTimer(withTimeInterval: bulkSendInterval, repeats: true) { _ in
            if self.isRouteTracking {
                self.sendBulkLocations()
            }
        }
        print("✅ [LocationManager] Toplu konum gönderimi timer'ı başlatıldı")
    }
    
    /// Konum toplama timer'ını başlatır
    private func startLocationCollectionTimer() {
        locationCollectionTimer?.invalidate()
        locationCollectionTimer = Timer.scheduledTimer(withTimeInterval: locationCollectionInterval, repeats: true) { _ in
            if self.isRouteTracking, let location = self.currentLocation {
                self.addLocationToBuffer(location)
            }
        }
        print("✅ [LocationManager] Konum toplama timer'ı başlatıldı")
    }
    
    /// Toplu konum gönderimi timer'ını durdurur
    private func stopBulkSendTimer() {
        bulkSendTimer?.invalidate()
        bulkSendTimer = nil
        print("🛑 [LocationManager] Toplu konum gönderimi timer'ı durduruldu")
    }
    
    /// Konum toplama timer'ını durdurur
    private func stopLocationCollectionTimer() {
        locationCollectionTimer?.invalidate()
        locationCollectionTimer = nil
        print("🛑 [LocationManager] Konum toplama timer'ı durduruldu")
    }
    
    /// Konumu buffer'a ekler (akıllı gruplandırma ile)
    private func addLocationToBuffer(_ location: CLLocation) {
        guard isRouteTracking,
              let currentRoute = currentRoute else {
            return
        }
        
        let locationPoint = LocationPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            timestamp: Date(),
            speed: location.speed,
            heading: location.course,
            distanceFromPrevious: calculateDistanceFromPrevious(),
            totalDistance: calculateTotalDistance()
        )
        
        // Akıllı gruplandırma uygula
        if shouldGroupWithPreviousLocation(locationPoint) {
            // Önceki konumla grupla
            groupLocationWithPrevious(locationPoint)
        } else {
            // Yeni grup başlat
            startNewLocationGroup(locationPoint)
        }
        
        // Buffer boyutunu kontrol et
        if locationBuffer.count >= maxBufferSize {
            print("📦 [LocationManager] Buffer dolu (\(maxBufferSize) konum), hemen gönderiliyor")
            sendBulkLocations()
        }
        
        print("📦 [LocationManager] Konum işlendi - Buffer: \(locationBuffer.count), Temp: \(tempLocationBuffer.count)")
    }
    
    // MARK: - Konum Gruplandırma Metodları
    
    /// Yeni konumun önceki konumla gruplandırılıp gruplandırılmayacağını belirler
    private func shouldGroupWithPreviousLocation(_ newLocation: LocationPoint) -> Bool {
        guard let lastLocation = tempLocationBuffer.last else {
            return false // İlk konum, grup yok
        }
        
        // 1. Mesafe kontrolü
        let distance = calculateDistanceBetweenLocations(lastLocation, newLocation)
        if distance > groupingDistanceThreshold {
            print("🔍 [Grouping] Mesafe çok uzak (\(String(format: "%.1f", distance))m > \(groupingDistanceThreshold)m) - yeni grup")
            return false
        }
        
        // 2. Zaman kontrolü
        let timeDifference = newLocation.timestamp.timeIntervalSince(lastLocation.timestamp)
        if timeDifference > groupingTimeThreshold {
            print("🔍 [Grouping] Zaman farkı çok büyük (\(String(format: "%.0f", timeDifference))s > \(groupingTimeThreshold)s) - yeni grup")
            return false
        }
        
        // 3. Hız kontrolü (hareket durumu)
        let isLastLocationStopped = lastLocation.speed < minSpeedThreshold
        let isNewLocationStopped = newLocation.speed < minSpeedThreshold
        
        // Eğer biri durmuş diğeri hareket halindeyse gruplama
        if isLastLocationStopped != isNewLocationStopped {
            print("🔍 [Grouping] Hareket durumu değişti (durma/hareket) - yeni grup")
            return false
        }
        
        // 4. Yön değişimi kontrolü (sadece hareket halindeyken)
        if !isLastLocationStopped && !isNewLocationStopped {
            let headingDifference = abs(newLocation.heading - lastLocation.heading)
            if headingDifference > 45.0 { // 45 derece üzeri yön değişimi
                print("🔍 [Grouping] Önemli yön değişimi (\(String(format: "%.1f", headingDifference))°) - yeni grup")
                return false
            }
        }
        
        // 5. Hassasiyet kontrolü
        if newLocation.accuracy > 50.0 { // 50 metre üzeri hassasiyet düşük
            print("🔍 [Grouping] Düşük hassasiyet (\(String(format: "%.1f", newLocation.accuracy))m) - yeni grup")
            return false
        }
        
        print("✅ [Grouping] Konum gruplandırılabilir - mesafe: \(String(format: "%.1f", distance))m, zaman: \(String(format: "%.0f", timeDifference))s")
        return true
    }
    
    /// Yeni konumu önceki konumla gruplandırır
    private func groupLocationWithPrevious(_ newLocation: LocationPoint) {
        guard var lastLocation = tempLocationBuffer.last else {
            startNewLocationGroup(newLocation)
            return
        }
        
        // Ortalama koordinatları hesapla
        let avgLatitude = (lastLocation.latitude + newLocation.latitude) / 2.0
        let avgLongitude = (lastLocation.longitude + newLocation.longitude) / 2.0
        
        // En iyi hassasiyeti seç
        let bestAccuracy = min(lastLocation.accuracy, newLocation.accuracy)
        
        // En son zamanı kullan
        let latestTimestamp = max(lastLocation.timestamp, newLocation.timestamp)
        
        // Ortalama hız ve yön
        let avgSpeed = (lastLocation.speed + newLocation.speed) / 2.0
        let avgHeading = calculateAverageHeading(lastLocation.heading, newLocation.heading)
        
        // Toplam mesafeyi güncelle
        let totalDistance = lastLocation.totalDistance + newLocation.distanceFromPrevious
        
        // Gruplandırılmış konum oluştur
        let groupedLocation = LocationPoint(
            latitude: avgLatitude,
            longitude: avgLongitude,
            accuracy: bestAccuracy,
            timestamp: latestTimestamp,
            speed: avgSpeed,
            heading: avgHeading,
            distanceFromPrevious: lastLocation.distanceFromPrevious,
            totalDistance: totalDistance
        )
        
        // Son konumu güncelle
        tempLocationBuffer[tempLocationBuffer.count - 1] = groupedLocation
        
        print("🔄 [Grouping] Konum gruplandırıldı - Temp buffer: \(tempLocationBuffer.count)")
    }
    
    /// Yeni konum grubu başlatır
    private func startNewLocationGroup(_ newLocation: LocationPoint) {
        // Temp buffer'daki konumları ana buffer'a taşı
        if !tempLocationBuffer.isEmpty {
            locationBuffer.append(contentsOf: tempLocationBuffer)
            print("📦 [Grouping] \(tempLocationBuffer.count) konum ana buffer'a taşındı")
            tempLocationBuffer.removeAll()
        }
        
        // Yeni konumu temp buffer'a ekle
        tempLocationBuffer.append(newLocation)
        print("🆕 [Grouping] Yeni grup başlatıldı - Temp buffer: \(tempLocationBuffer.count)")
    }
    
    /// İki konum arasındaki mesafeyi hesaplar
    private func calculateDistanceBetweenLocations(_ loc1: LocationPoint, _ loc2: LocationPoint) -> Double {
        let location1 = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
        let location2 = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
        return location1.distance(from: location2)
    }
    
    /// İki yönün ortalamasını hesaplar
    private func calculateAverageHeading(_ heading1: Double, _ heading2: Double) -> Double {
        // Yön farkını hesapla
        var diff = heading2 - heading1
        
        // 180 derece üzerindeki farkları düzelt
        if diff > 180 {
            diff -= 360
        } else if diff < -180 {
            diff += 360
        }
        
        // Ortalama hesapla
        let avg = heading1 + diff / 2.0
        
        // 0-360 aralığına normalize et
        return (avg + 360).truncatingRemainder(dividingBy: 360)
    }
    
    /// Buffer'daki konumları toplu olarak gönderir
    private func sendBulkLocations(status: String = "active") {
        // Temp buffer'daki konumları ana buffer'a taşı
        if !tempLocationBuffer.isEmpty {
            locationBuffer.append(contentsOf: tempLocationBuffer)
            print("📦 [Grouping] Son \(tempLocationBuffer.count) konum ana buffer'a taşındı")
            tempLocationBuffer.removeAll()
        }
        
        guard !locationBuffer.isEmpty,
              let currentRoute = currentRoute else {
            print("ℹ️ [LocationManager] Gönderilecek konum yok veya gerekli veriler eksik")
            return
        }
        
        print("📦 [LocationManager] Toplu konum gönderimi başlatılıyor - \(locationBuffer.count) konum")
        
        let bulkData = BulkLocationData(
            routeId: currentRoute.routeId,
            assignedPlanId: currentRoute.planId,
            assignedScreenId: currentRoute.assignmentScreenId,
            assignedEmployeeId: currentRoute.assignmentEmployeeId,
            assignedScheduleId: currentRoute.id,
            sessionDate: formatDateForAPI(Date()),
            actualStartTime: trackingStartDate ?? Date(),
            actualEndTime: Date(),
            status: status,
            batteryLevel: Double(UIDevice.current.batteryLevel),
            signalStrength: getSignalStrength(),
            actualDurationMin: calculateActualDuration(),
            locations: locationBuffer
        )
        
        // Buffer'ı temizle
        locationBuffer.removeAll()
        
        // API'ye gönder
        sendBulkLocationsToAPI(bulkData)
    }
    
    /// Toplu konum verilerini API'ye gönderir
    private func sendBulkLocationsToAPI(_ bulkData: BulkLocationData) {
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.Endpoints.trackBulkRouteLocation) else {
            LogManager.shared.log("Geçersiz bulk location URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.API.appToken, forHTTPHeaderField: "app_token")

        do {
            let jsonData = try JSONEncoder().encode(bulkData)
            request.httpBody = jsonData
            
            LogManager.shared.log("Toplu konum gönderiliyor: \(bulkData.locations.count) konum")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [LocationManager] Toplu konum gönderme hatası: \(error.localizedDescription)")
                        LogManager.shared.log("Toplu konum gönderme hatası: \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 [LocationManager] Toplu konum gönderme yanıtı: \(httpResponse.statusCode)")
                        
                        if httpResponse.statusCode == 200 {
                            print("✅ [LocationManager] Toplu konum verisi başarıyla gönderildi")
                            LogManager.shared.log("Toplu konum verisi başarıyla gönderildi - \(bulkData.locations.count) konum")
                        } else {
                            print("❌ [LocationManager] Toplu konum gönderilemedi - HTTP \(httpResponse.statusCode)")
                            // Hata durumunda konumları tekrar buffer'a ekle
                            self.locationBuffer.append(contentsOf: bulkData.locations)
                        }
                    }
                }
            }.resume()
        } catch {
            print("❌ [LocationManager] Toplu konum verisi encode hatası: \(error)")
            LogManager.shared.log("Toplu konum verisi encode hatası: \(error)")
            // Hata durumunda konumları tekrar buffer'a ekle
            locationBuffer.append(contentsOf: bulkData.locations)
        }
    }
    
    // MARK: - Route Completion Timer
    
    /// Rota tamamlama timer'ını başlatır
    private func startRouteCompletionTimer() {
        stopRouteCompletionTimer()
        
        guard let currentRoute = currentRoute else {
            print("❌ [LocationManager] Rota tamamlama timer başlatılamadı - currentRoute nil")
            return
        }
        
        let endDate = getRouteEndDate()
        guard let endDate = endDate else {
            print("❌ [LocationManager] Rota tamamlama timer başlatılamadı - endDate nil")
            return
        }
        
        let now = Date()
        let timeUntilCompletion = endDate.timeIntervalSince(now)
        
        print("⏰ [LocationManager] Rota tamamlama timer ayarlanıyor:")
        print("⏰ [LocationManager] Şu anki zaman: \(now)")
        print("⏰ [LocationManager] Bitiş zamanı: \(endDate)")
        print("⏰ [LocationManager] Kalan süre: \(timeUntilCompletion) saniye")
        
        if timeUntilCompletion > 0 {
            routeCompletionTimer = Timer.scheduledTimer(withTimeInterval: timeUntilCompletion, repeats: false) { _ in
                self.autoCompleteRoute()
            }
            print("✅ [LocationManager] Rota tamamlama timer başlatıldı - \(timeUntilCompletion) saniye sonra")
        } else {
            print("⚠️ [LocationManager] Rota zamanı zaten dolmuş, hemen tamamlanıyor")
            autoCompleteRoute()
        }
    }
    
    /// Rota tamamlama timer'ını durdurur
    private func stopRouteCompletionTimer() {
        routeCompletionTimer?.invalidate()
        routeCompletionTimer = nil
        print("🛑 [LocationManager] Rota tamamlama timer durduruldu")
    }
    
    /// Rota zamanı dolduğunda otomatik tamamlama
    private func autoCompleteRoute() {
        print("⏰ [LocationManager] Rota zamanı doldu, otomatik tamamlama başlatılıyor")
        
        // Buffer'daki konumları hemen gönder
        sendBulkLocations(status: "completed")
        
        DispatchQueue.main.async {
            // Work status'u completed olarak güncelle
            self.updateAssignmentWorkStatus(status: "completed")
            
            // ActiveTrackingInfo'yu temizle
            self.clearActiveTrackingInfo()
            
            // State'leri temizle
            self.isRouteTracking = false
            self.activeScheduleId = nil
            self.currentRoute = nil
            
            // Background monitoring'i durdur
            self.stopBackgroundMonitoring()
            
            // Konum toplama timer'ını durdur
            self.stopLocationCollectionTimer()
            
            // Toplu konum gönderimi timer'ını durdur
            self.stopBulkSendTimer()
            
            // Timer'ı durdur
            self.stopRouteCompletionTimer()
            
            // Notification gönder
            NotificationCenter.default.post(
                name: NSNotification.Name("RouteAutoCompleted"),
                object: nil,
                userInfo: [
                    "schedule_id": self.currentRoute?.id ?? "",
                    "assignment_id": self.currentRoute?.assignmentId ?? ""
                ]
            )
            
            LogManager.shared.log("Rota otomatik olarak tamamlandı - zaman doldu")
            print("✅ [LocationManager] Rota otomatik olarak tamamlandı")
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedAlways:
                LogManager.shared.log("Konum izni verildi (Always)")
                if self.isRouteTracking {
                    manager.startUpdatingLocation()
                }
            case .authorizedWhenInUse:
                LogManager.shared.log("Konum izni verildi (WhenInUse)")
            case .denied, .restricted:
                LogManager.shared.log("Konum izni reddedildi")
            case .notDetermined:
                LogManager.shared.log("Konum izni bekleniyor")
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationHistory.append(location)
            
            // Konumları artık timer ile topluyoruz, burada eklemiyoruz
            // Timer her 5 saniyede bir mevcut konumu buffer'a ekleyecek
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LogManager.shared.log("Konum güncelleme hatası: \(error.localizedDescription)")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        LogManager.shared.log("Konum güncellemeleri duraklatıldı")
    }
    
    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        LogManager.shared.log("Konum güncellemeleri devam ediyor")
    }
} 
