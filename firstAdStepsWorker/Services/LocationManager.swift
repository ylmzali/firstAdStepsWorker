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
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRouteTracking = false
    @Published var activeScheduleId: String?
    @Published var currentRoute: Assignment?
    @Published var trackingStartDate: Date?
    @Published var lastLocationUpdate: Date?
    
    // Background task management
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: Timer?
    
    // Route completion timer
    private var routeCompletionTimer: Timer?
    
    // Location history for tracking
    private var locationHistory: [CLLocation] = []
    private var lastLocationUpdateTime: Date?
    
    // Pending location data for offline sending
    private var pendingLocationData: [LocationData] = []
    private let pendingLocationKey = "pending_location_data"
    
    // Public property for pending location data count
    var pendingLocationDataCount: Int {
        return pendingLocationData.count
    }
    
    // MARK: - Smart Location Filtering
    private var lastSentLocation: CLLocation?
    private var lastSentHeading: Double = 0.0
    private var lastSentSpeed: Double = 0.0
    private var lastSentTime: Date?
    
    // Smart filtering configuration
    private var isSmartFilteringEnabled: Bool = true
    private var minDistanceForSending: Double = 3.0 // 3 metre
    private var minHeadingChange: Double = 15.0 // 15 derece
    private var minSpeedChange: Double = 2.0 // 2 m/s
    private var maxTimeInterval: TimeInterval = 60.0 // 60 saniye
    private var minAccuracy: Double = 20.0 // 20 metre
    
    override init() {
        super.init()
        setupLocationManager()
        setupNotificationObservers()
        loadPendingLocationData()
        checkExistingTrackingStatus()
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
    
    @objc private func appDidEnterBackground() {
        if isRouteTracking {
            startBackgroundTask()
            startBackgroundMonitoring()
            
            // İlk konum gönderimini hemen yap
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.sendLocationToServer()
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        endBackgroundTask()
        
        // Pending konum verilerini tekrar göndermeyi dene
        if !pendingLocationData.isEmpty {
            print("🔄 [LocationManager] Uygulama foreground'a geldi, pending konum verileri gönderiliyor")
            retryPendingLocationData()
        }
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
            self.endBackgroundTask()
        }
        
        let remainingTime = UIApplication.shared.backgroundTimeRemaining
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
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
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
        
        // Rota tamamlama timer'ını başlat
        startRouteCompletionTimer()
        print("🚀 [LocationManager] Rota tamamlama timer'ı başlatıldı")
        
        LogManager.shared.log("Schedule tracking başlatıldı - Schedule ID: \(route.id), Assignment ID: \(route.assignmentId)")
    }
    
    func stopRouteTracking() {
        updateActiveTrackingInfo(status: "paused")
        isRouteTracking = false
        activeScheduleId = nil
        stopBackgroundMonitoring()
        stopRouteCompletionTimer()
        
        updateAssignmentWorkStatus(status: "paused")
        
        LogManager.shared.log("Route tracking duraklatıldı")
    }
    
    func completeRouteTracking() {
        updateAssignmentWorkStatus(status: "completed")
        clearActiveTrackingInfo()
        isRouteTracking = false
        activeScheduleId = nil
        stopBackgroundMonitoring()
        stopRouteCompletionTimer()
        
        LogManager.shared.log("Route tracking tamamlandı")
    }
    
    func sendLocationToServer() {
        guard isRouteTracking,
              let currentLocation = currentLocation,
              let currentRoute = currentRoute else {
            return
        }
        
        // Akıllı filtreleme kontrolü
        if !shouldSendLocation(currentLocation) {
            print("🚫 [LocationManager] Konum akıllı filtreleme nedeniyle gönderilmiyor")
            return
        }
        
        // Son güncelleme zamanını kontrol et (15 saniye minimum aralık)
        if let lastUpdate = lastLocationUpdate,
           Date().timeIntervalSince(lastUpdate) < 15 {
            return
        }
        
        // Zaman kontrolü
        if !isRouteTimeActive() {
            LogManager.shared.log("Rota zamanı doldu, tracking tamamlanıyor")
            autoCompleteRoute()
            return
        }
        
        print("✅ [LocationManager] Konum gönderiliyor - Akıllı filtreleme geçti")
        
        let locationData = LocationData(
            routeId: currentRoute.routeId,
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude,
            accuracy: currentLocation.horizontalAccuracy,
            timestamp: Date(),
            speed: currentLocation.speed,
            heading: currentLocation.course,
            assignedPlanId: currentRoute.planId,
            assignedScreenId: currentRoute.assignmentScreenId,
            assignedEmployeeId: currentRoute.assignmentEmployeeId,
            assignedScheduleId: currentRoute.id,
            sessionDate: formatDateForAPI(Date()),
            actualStartTime: trackingStartDate ?? Date(),
            actualEndTime: Date(),
            status: "active",
            batteryLevel: Double(UIDevice.current.batteryLevel),
            signalStrength: getSignalStrength(),
            actualDurationMin: calculateActualDuration(),
            distanceFromPrevious: calculateDistanceFromPrevious(),
            totalDistance: calculateTotalDistance()
        )
        
        // Önce local'e kaydet
        addPendingLocationData(locationData)
        
        // Sonra server'a gönder
        sendLocationToAPI(locationData)
        
        // Son gönderilen konum bilgilerini güncelle
        updateLastSentLocation(currentLocation)
        
        // ActiveTrackingInfo güncelle
        updateActiveTrackingInfo(status: "working", lastLocationUpdate: Date())
        
        lastLocationUpdate = Date()
    }
    
    private func sendLocationToAPI(_ locationData: LocationData) {
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.Endpoints.trackRouteLocation) else {
            LogManager.shared.log("Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.API.appToken, forHTTPHeaderField: "app_token")

        do {
            let jsonData = try JSONEncoder().encode(locationData)
            request.httpBody = jsonData
            
            LogManager.shared.log("Konum gönderiliyor: \(locationData.latitude), \(locationData.longitude)")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [LocationManager] Konum gönderme hatası: \(error.localizedDescription)")
                        LogManager.shared.log("Konum gönderme hatası: \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 [LocationManager] Konum gönderme yanıtı: \(httpResponse.statusCode)")
                        
                        if httpResponse.statusCode == 200 {
                            // Başarılı gönderim - pending listesinden kaldır
                            self.removeLocationDataFromPending(locationData)
                            print("✅ [LocationManager] Konum verisi başarıyla gönderildi")
                        } else {
                            print("❌ [LocationManager] Konum gönderilemedi - HTTP \(httpResponse.statusCode)")
                        }
                    }
                }
            }.resume()
        } catch {
            print("❌ [LocationManager] Konum verisi encode hatası: \(error)")
            LogManager.shared.log("Konum verisi encode hatası: \(error)")
        }
    }
    
    // MARK: - Pending Location Data Management
    
    private func addPendingLocationData(_ locationData: LocationData) {
        pendingLocationData.append(locationData)
        savePendingLocationData()
        print("📝 [LocationManager] Konum verisi pending listesine eklendi")
    }
    
    private func savePendingLocationData() {
        do {
            let data = try JSONEncoder().encode(pendingLocationData)
            UserDefaults.standard.set(data, forKey: pendingLocationKey)
            print("💾 [LocationManager] Pending konum verileri kaydedildi: \(pendingLocationData.count) adet")
        } catch {
            print("❌ [LocationManager] Pending konum verileri kaydedilemedi: \(error)")
        }
    }
    
    private func loadPendingLocationData() {
        guard let data = UserDefaults.standard.data(forKey: pendingLocationKey) else {
            print("ℹ️ [LocationManager] Pending konum verisi bulunamadı")
            return
        }
        
        do {
            pendingLocationData = try JSONDecoder().decode([LocationData].self, from: data)
            print("📥 [LocationManager] Pending konum verileri yüklendi: \(pendingLocationData.count) adet")
        } catch {
            print("❌ [LocationManager] Pending konum verileri yüklenemedi: \(error)")
            pendingLocationData = []
        }
    }
    
    private func clearPendingLocationData() {
        pendingLocationData.removeAll()
        UserDefaults.standard.removeObject(forKey: pendingLocationKey)
        print("🗑️ [LocationManager] Pending konum verileri temizlendi")
    }
    
    private func removeLocationDataFromPending(_ locationData: LocationData) {
        if let index = pendingLocationData.firstIndex(where: { 
            $0.timestamp == locationData.timestamp && 
            $0.latitude == locationData.latitude && 
            $0.longitude == locationData.longitude 
        }) {
            pendingLocationData.remove(at: index)
            savePendingLocationData()
            print("✅ [LocationManager] Konum verisi pending listesinden kaldırıldı")
        }
    }
    
    // Pending konum verilerini tekrar göndermeyi dene
    func retryPendingLocationData() {
        guard !pendingLocationData.isEmpty else {
            print("ℹ️ [LocationManager] Gönderilecek pending konum verisi yok")
            return
        }
        
        print("🔄 [LocationManager] Pending konum verileri tekrar gönderiliyor: \(pendingLocationData.count) adet")
        
        for locationData in pendingLocationData {
            sendLocationToAPI(locationData)
        }
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
        
        // Pending konum verilerini temizle
        clearPendingLocationData()
        
        // Location manager'ı durdur
        locationManager.stopUpdatingLocation()
        
        // Background monitoring'i durdur
        stopBackgroundMonitoring()
        
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
            
            if self.isRouteTracking && self.activeScheduleId != nil {
                self.sendLocationToServer()
            }
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
