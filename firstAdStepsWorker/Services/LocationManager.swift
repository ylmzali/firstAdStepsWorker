import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    private let baseURL = AppConfig.API.baseURL
    private let appToken = AppConfig.API.appToken
    private let tokenHeader = AppConfig.API.tokenHeader

    private let locationManager = CLLocationManager()
    private let locationUpdateTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect() // 30 saniyede bir
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentLocation: CLLocation?
    @Published var isLocationTracking = false
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocationUpdate: Date?
    @Published var locationHistory: [LocationData] = []
    
    // Rota ispatı için
    @Published var activeRouteId: String?
    @Published var isRouteTracking = false
    
    override init() {
        super.init()
        
        print("📍 LocationManager: Başlatılıyor...")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Timer'ı ayarla
        setupLocationUpdateTimer()
        
        // Uygulama başlarken konum izni iste
        requestLocationPermission()
    }
    
    private func setupLocationUpdateTimer() {
        locationUpdateTimer
            .sink { [weak self] _ in
                self?.sendLocationToServer()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        print("📍 LocationManager: Konum izni isteniyor...")
        
        // Konum izni durumunu kontrol et
        switch locationPermissionStatus {
        case .denied, .restricted:
            print("⚠️ LocationManager: Konum izni reddedildi, demo modunda çalışacak")
            // Kullanıcıya bildirim gönder
            NotificationCenter.default.post(name: .locationPermissionDenied, object: nil)
        case .notDetermined:
            // Konum izni iste
            print("⏳ LocationManager: Konum izni isteniyor...")
            // Kullanıcıya bildirim gönder
            NotificationCenter.default.post(name: .locationPermissionRequested, object: nil)
            // Önce WhenInUse izni iste
            locationManager.requestWhenInUseAuthorization()
            // Kısa bir süre sonra Always izni iste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.locationManager.requestAlwaysAuthorization()
            }
        case .authorizedWhenInUse:
            // WhenInUse izni var ama Always iste
            print("⚠️ LocationManager: Sadece uygulama açıkken izin var, Always izni isteniyor...")
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("✅ LocationManager: Konum izni mevcut (Always)")
            // Kullanıcıya bildirim gönder
            NotificationCenter.default.post(name: .locationPermissionGranted, object: nil)
        @unknown default:
            print("❓ LocationManager: Bilinmeyen konum izni durumu")
        }
    }
    
    // iOS 14+ için geçici konum izni iste
    func requestTemporaryLocationPermission() {
        print("📍 LocationManager: Geçici konum izni isteniyor...")
        locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "RouteTracking")
    }
    
    // showLocationSettingsAlert fonksiyonu kaldırıldı - artık gerekli değil
    
    func startLocationTracking() {
        // Konum izni olmadan da çalışabilir mod
        switch locationPermissionStatus {
        case .denied, .restricted:
            // Konum izni yok ama uygulama çalışmaya devam edebilir
            print("⚠️ LocationManager: Konum izni yok, demo modunda çalışıyor")
            isLocationTracking = true
            // Demo konum verisi oluştur
            createDemoLocationData()
        case .notDetermined:
            requestLocationPermission()
        case .authorizedWhenInUse, .authorizedAlways:
            // Normal konum takibi
            if locationPermissionStatus == .authorizedAlways {
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
            } else {
                locationManager.allowsBackgroundLocationUpdates = false
            }
            
            locationManager.startUpdatingLocation()
            isLocationTracking = true
            print("📍 LocationManager: Konum takibi başlatıldı")
        @unknown default:
            requestLocationPermission()
        }
    }
    
    private func createDemoLocationData() {
        // Demo konum verisi oluştur (İstanbul koordinatları)
        let demoLocation = CLLocation(latitude: 41.0082, longitude: 28.9784)
        currentLocation = demoLocation
        
        // Demo konum verisini servise gönder
        if let routeId = activeRouteId {
            let demoData = LocationData(
                routeId: routeId,
                latitude: demoLocation.coordinate.latitude,
                longitude: demoLocation.coordinate.longitude,
                accuracy: 100.0,
                timestamp: Date(),
                speed: 0.0,
                heading: 0.0
            )
            
            locationHistory.append(demoData)
            sendLocationToAPI(parameters: demoData) { result in
                print("📍 LocationManager: Demo konum verisi gönderildi")
            }
        }
    }
    
    func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
        isLocationTracking = false
        print("📍 LocationManager: Konum takibi durduruldu")
    }
    
    func startRouteTracking(routeId: String) {
        // Önce konum iznini kontrol et
        guard locationPermissionStatus == .authorizedWhenInUse || 
              locationPermissionStatus == .authorizedAlways else {
            print("⚠️ LocationManager: Konum izni yok, demo modunda çalışacak")
            activeRouteId = routeId
            isRouteTracking = true
            startDemoLocationTracking()
            return
        }
        
        activeRouteId = routeId
        isRouteTracking = true
        startLocationTracking()
        
        // İlk konum verisini hemen gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let location = self.currentLocation {
                let locationData = LocationData(
                    routeId: routeId,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    accuracy: location.horizontalAccuracy,
                    timestamp: Date(),
                    speed: location.speed,
                    heading: location.course
                )
                
                self.sendLocationToAPI(parameters: locationData) { _ in
                    print("📍 LocationManager: İlk konum verisi gönderildi - Route ID: \(routeId)")
                }
            }
        }
        
        print("📍 LocationManager: Rota takibi başlatıldı - Route ID: \(routeId)")
    }
    
    private func startDemoLocationTracking() {
        // Demo konum verisi ile takip simülasyonu
        print("📍 LocationManager: Demo konum takibi başlatıldı")
        
        // İlk demo konum verisini hemen gönder
        sendDemoLocationData()
        
        // Her 30 saniyede bir demo konum gönder
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.sendDemoLocationData()
        }
    }
    
    private func sendDemoLocationData() {
        // Demo konum verisi (İstanbul koordinatları)
        let demoLocation = CLLocation(latitude: 41.0082, longitude: 28.9784)
        currentLocation = demoLocation // Current location'ı da güncelle
        
        // Backend'e konum verisi gönder
        let parameters = LocationData(
            routeId: activeRouteId ?? "",
            latitude: demoLocation.coordinate.latitude,
            longitude: demoLocation.coordinate.longitude,
            accuracy: 10.0,
            timestamp: Date(),
            speed: 0.0,
            heading: 0.0
        )
        
        sendLocationToAPI(parameters: parameters) { _ in }
        
        print("📍 LocationManager: Demo konum gönderildi - Lat: \(demoLocation.coordinate.latitude), Lng: \(demoLocation.coordinate.longitude)")
    }
    
    func stopRouteTracking() {
        activeRouteId = nil
        isRouteTracking = false
        stopLocationTracking()
        print("📍 LocationManager: Rota takibi durduruldu")
    }
    
    func completeRouteTracking() {
        // Rota tamamlama işlemi
        guard let routeId = activeRouteId else {
            print("⚠️ LocationManager: Tamamlanacak aktif rota yok")
            return
        }
        
        print("📍 LocationManager: Rota tamamlama başlatılıyor - Route ID: \(routeId)")
        
        // Önce takibi durdur
        isRouteTracking = false
        stopLocationTracking()
        
        // Son konum verisini gönder
        sendLocationToServer()
        
        // Rota tamamlama verisi gönder (asenkron)
        DispatchQueue.main.async {
            self.sendRouteCompletionToAPI(routeId: routeId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        print("✅ LocationManager: Rota başarıyla tamamlandı - Route ID: \(routeId)")
                    case .failure(let error):
                        print("❌ LocationManager: Rota tamamlama hatası: \(error)")
                    }
                    
                    // State'i temizle
                    self.activeRouteId = nil
                    self.isRouteTracking = false
                    self.stopLocationTracking()
                    
                    print("📍 LocationManager: Rota takibi tamamlandı - Route ID: \(routeId)")
                }
            }
        }
    }
    
    // MARK: - Server Communication
    
    private func sendLocationToServer() {
        guard let location = currentLocation,
              let routeId = activeRouteId else { return }
        
        let parameters = LocationData(
            routeId: routeId,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            timestamp: Date(),
            speed: location.speed,
            heading: location.course
        )
        
        // Konum verisini geçmişe ekle
        locationHistory.append(parameters)
        
        // Servise gönder
        sendLocationToAPI(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
        }

        lastLocationUpdate = Date()
        print("📍 LocationManager: Konum servise gönderildi - Route: \(routeId)")
    }
    
    func sendLocationToAPI(
        parameters: LocationData,
        completion: @escaping (Result<LocationRequest, ServiceError>) -> Void
    ) {
        
        // Request body
        /*
        let parametersData = LocationRequest(
            latitude: parameters.latitude,
            longitude: parameters.longitude,
            accuracy: parameters.accuracy,
            timestamp: ISO8601DateFormatter().string(from: parameters.timestamp),
            speed: parameters.speed,
            heading: parameters.heading
        )
        */
        
        var parametersData: [String: Any] = [
            "routeId": parameters.routeId,
            "latitude": parameters.latitude,
            "longitude": parameters.longitude,
            "accuracy": parameters.accuracy,
            "timestamp": ISO8601DateFormatter().string(from: parameters.timestamp),
            "speed": parameters.speed,
            "heading": parameters.heading
        ]
        
        makeRequest(
            endpoint: AppConfig.Endpoints.employeeLocationUpdate,
            method: .post,
            parameters: parametersData,
            completion: completion
        )
    }
    
    private func sendRouteCompletionToAPI(
        routeId: String,
        completion: @escaping (Result<RouteCompletionResponse, ServiceError>) -> Void
    ) {
        let parameters: [String: Any] = [
            "routeId": routeId,
            "completionTime": ISO8601DateFormatter().string(from: Date()),
            "totalDistance": calculateTotalDistance(),
            "totalDuration": calculateTotalDuration(),
            "locationCount": locationHistory.filter { $0.routeId == routeId }.count
        ]
        
        makeRequest(
            endpoint: AppConfig.Endpoints.routeCompletion,
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
    private func calculateTotalDistance() -> Double {
        // Basit mesafe hesaplama - gerçek uygulamada daha gelişmiş algoritma kullanılabilir
        var totalDistance: Double = 0
        let routeLocations = locationHistory.filter { $0.routeId == activeRouteId }
        
        for i in 1..<routeLocations.count {
            let prevLocation = CLLocation(latitude: routeLocations[i-1].latitude, longitude: routeLocations[i-1].longitude)
            let currentLocation = CLLocation(latitude: routeLocations[i].latitude, longitude: routeLocations[i].longitude)
            totalDistance += prevLocation.distance(from: currentLocation)
        }
        
        return totalDistance
    }
    
    private func calculateTotalDuration() -> Int {
        // Toplam süre hesaplama (dakika cinsinden)
        guard let routeId = activeRouteId else { return 0 }
        let routeLocations = locationHistory.filter { $0.routeId == routeId }
        
        guard let firstLocation = routeLocations.first,
              let lastLocation = routeLocations.last else { return 0 }
        
        let duration = lastLocation.timestamp.timeIntervalSince(firstLocation.timestamp)
        return Int(duration / 60) // Dakika cinsinden
    }
    
    // MARK: - Location History
    func getLocationHistory(for routeId: String) -> [LocationData] {
        return locationHistory.filter { $0.routeId == routeId }
    }
    
    func clearLocationHistory() {
        locationHistory.removeAll()
    }

    // MARK: - Helper Methods
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, ServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(.invalidUrl))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appToken, forHTTPHeaderField: "app_token")
        
        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                print("🌐 REQUEST URL: \(url)")
                print("🌐 REQUEST METHOD: \(method.rawValue)")
                print("🌐 REQUEST HEADERS: \(request.allHTTPHeaderFields ?? [:])")
                print("🌐 REQUEST BODY: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
            } catch {
                completion(.failure(.invalidData))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(.failure(.networkError))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.invalidData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 RESPONSE STATUS: \(httpResponse.statusCode)")
                    print("🌐 RESPONSE BODY: \(String(data: data, encoding: .utf8) ?? "")")

                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                            completion(.success(decodedResponse))
                        } catch {
                            print("❌ Decoding error: \(error)")
                            completion(.failure(.invalidData))
                        }
                    case 401:
                        completion(.failure(.unauthorized))
                    case 404:
                        completion(.failure(.notFound))
                    case 400...499:
                        completion(.failure(.badRequest))
                    case 500...599:
                        completion(.failure(.serverError("Sunucu hatası")))
                    default:
                        completion(.failure(.unknown("Beklenmeyen durum kodu: \(httpResponse.statusCode)")))
                    }
                } else {
                    completion(.failure(.invalidResponse))
                }
            }
        }.resume()
    }
}

// MARK: - API Response Models

struct RouteCompletionResponse: Codable {
    let status: String
    let message: String?
    let data: RouteCompletionData?
    
    struct RouteCompletionData: Codable {
        let routeId: String
        let completionTime: String
        let totalDistance: Double
        let totalDuration: Int
        let locationCount: Int
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        
        // Eğer rota takibi aktifse, konumu servise gönder
        if isRouteTracking {
            sendLocationToServer()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ LocationManager: Konum alma hatası: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationPermissionStatus = manager.authorizationStatus
        
        switch locationPermissionStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ LocationManager: Konum izni verildi")
            NotificationCenter.default.post(name: .locationPermissionGranted, object: nil)
        case .denied, .restricted:
            print("❌ LocationManager: Konum izni reddedildi")
            NotificationCenter.default.post(name: .locationPermissionDenied, object: nil)
        case .notDetermined:
            print("⏳ LocationManager: Konum izni bekleniyor")
            NotificationCenter.default.post(name: .locationPermissionRequested, object: nil)
        @unknown default:
            break
        }
    }
}

// MARK: - Data Models

struct LocationData {
    let routeId: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
    let speed: Double
    let heading: Double
}

struct LocationRequest: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: String
    let speed: Double
    let heading: Double
}

// MARK: - Location Utilities

extension LocationManager {
    func calculateDistance(from startLocation: CLLocation, to endLocation: CLLocation) -> Double {
        return startLocation.distance(from: endLocation)
    }
    
    func isWithinRouteArea(location: CLLocation, routeCoordinates: [CLLocationCoordinate2D], radius: Double = 100) -> Bool {
        // Basit mesafe kontrolü - gerçek uygulamada daha gelişmiş algoritma kullanılabilir
        for coordinate in routeCoordinates {
            let routeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = location.distance(from: routeLocation)
            
            if distance <= radius {
                return true
            }
        }
        return false
    }
    
    func getCurrentSpeed() -> Double {
        return currentLocation?.speed ?? 0.0
    }
    
    func getCurrentHeading() -> Double {
        return currentLocation?.course ?? 0.0
    }
    
    // MARK: - Route Tracking Status
    
    var isLocationEnabled: Bool {
        return locationPermissionStatus == .authorizedWhenInUse || 
               locationPermissionStatus == .authorizedAlways
    }
    
    func isTrackingRoute(routeId: String) -> Bool {
        return isRouteTracking && activeRouteId == routeId
    }
} 
