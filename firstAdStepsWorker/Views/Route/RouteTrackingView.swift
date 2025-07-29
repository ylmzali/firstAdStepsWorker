import SwiftUI
import MapKit

// MKMapView wrapper for MapType support
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var mapType: MKMapType
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.mapType = mapType
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Sadece region değiştiğinde güncelle, sürekli takip etme
        if mapView.region.center.latitude != region.center.latitude || 
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
        mapView.mapType = mapType
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

struct RouteTrackingView: View {
    let route: Assignment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager.shared
    @State private var isTracking = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    @State private var showInfoSheet = false
    @State private var showLocationPermissionAlert = false
    // Progress bar states
    @State private var trackingStartDate: Date? = nil
    @State private var trackingElapsed: TimeInterval = 0
    @State private var trackingTimer: Timer? = nil
    @State private var lastResumeDate: Date? = nil
    @State private var now: Date = Date()
    // Harita tipi
    @State private var mapType: MKMapType = .standard
    // Konuma odaklanma animasyonu
    @State private var shouldCenterOnUser: Bool = false
    @State private var hasCenteredOnUser = false
    
    // Rota takibi için yeni state'ler
    @State private var routeLocations: [LocationData] = []
    @State private var totalDistance: Double = 0
    @State private var averageSpeed: Double = 0
    @State private var isRouteActive: Bool = false

    var body: some View {
        ZStack {
            // Tam ekran harita
            MapView(region: $region, mapType: $mapType)
                .ignoresSafeArea()

            // Sağ alt köşe butonlar
            VStack {
                // Tracking Status Indicator
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(getLocationStatusColor())
                                .frame(width: 8, height: 8)
                            Text(getLocationStatusText())
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(locationManager.isRouteTracking ? Color.blue : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(locationManager.isRouteTracking ? "Takip Aktif" : "Takip Kapalı")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 80)
                
                HStack(spacing: 6) {
                    Spacer()
                    // Info butonu
                    Button(action: { showInfoSheet = true }) {
                        VStack {
                            Image(systemName: "info.circle.fill")
                            Text("Rota")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(Color.blue)
                        .cornerRadius(8)
                        // .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                        
                    }

                    // Takip Başlat/Durdur/Devam Et butonu
                    Button(action: { 
                        // LocationManager'daki mevcut durumu kontrol et
                        if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
                            pauseTracking()
                        } else {
                            // Rota zamanı kontrolü
                            if isRouteTimeActive() {
                                startTracking()
                            }
                        }
                    }) {
                        VStack {
                            Image(systemName: getButtonIcon())
                            Text(getButtonText())
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(getButtonColor())
                        .cornerRadius(8)
                        .disabled(!isRouteTimeActive() && !locationManager.isRouteTracking)
                    }
                    
                    // Zaman bilgisi (debug için)
                    if !isRouteTimeActive() {
                        VStack {
                            Text("Rota Zamanı:")
                                .font(.system(size: 14, weight: .light))
                            Text("\(route.formattedStartTime) - \(route.formattedEndTime)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .disabled(!isRouteTimeActive() && !locationManager.isRouteTracking)
                    }
                    
                    // Rota Tamamla butonu (sadece çalışıyor durumunda göster)
                    if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
                        Button(action: {
                            // Önce takibi durdur
                            pauseTracking()
                            
                            // Rota tamamlama işlemini başlat
                            locationManager.completeRouteTracking()
                            
                            // Kısa bir gecikme ile view'ı kapat
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                dismiss()
                            }
                        }) {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Tamamla")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                    }
                    Spacer()

                }
                .padding()

                // --- Progress Bars ---
                VStack(alignment: .leading, spacing: 18) {
                    
                    Text("Süreç")

                    // 1. Rota Süresi Progress Barı
                    RouteDurationProgressBar(route: route, now: $now)

                    // 2. Çalışılan Süre Progress Barı
                    TrackedTimeProgressBar(
                        elapsed: trackingElapsed + (isTracking && lastResumeDate != nil ? Date().timeIntervalSince(lastResumeDate!) : 0),
                        total: routeDurationSeconds
                    )
                }
                .padding(.horizontal)
                .padding(.vertical)
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal, 32)

                // ---
                Spacer()
            }
            .onAppear {
                DispatchQueue.main.async {
                    // Konum izni kontrolü ve hazırlık
                    locationManager.requestLocationPermission()
                    
                    // Always izni kontrolü
                    if locationManager.locationPermissionStatus != .authorizedAlways {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showLocationPermissionAlert = true
                        }
                    }
                    
                    // İlk durumu ayarla
                    setupInitialState()
                    
                    // Eğer zaten rota takibi aktifse, durumu güncelle
                    if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
                        isTracking = true
                        isRouteActive = true
                    }
                    
                    // Konum güncellemelerini dinle
                    NotificationCenter.default.addObserver(
                        forName: .locationPermissionGranted,
                        object: nil,
                        queue: .main
                    ) { _ in
                        // Konum izni verildiğinde yapılacak işlemler
                    }
                    
                    // Rota konum güncellemelerini dinle
                    NotificationCenter.default.addObserver(
                        forName: .routeLocationUpdated,
                        object: nil,
                        queue: .main
                    ) { notification in
                        if let locationData = notification.object as? LocationData,
                           locationData.routeId == self.route.id {
                            // Yeni konum verisini kaydet
                            self.routeLocations.append(locationData)
                            self.updateRouteStats()
                        }
                    }
                }
                startNowTimer()
            }
            .onDisappear {
                // Harita sayfasından çıkıldığında UI timer'ını durdur
                // Tracking LocationManager'da devam ediyor
                NotificationCenter.default.removeObserver(self, name: .locationPermissionGranted, object: nil)
                NotificationCenter.default.removeObserver(self, name: .routeLocationUpdated, object: nil)
                
                // UI timer'ını durdur (performans için)
                stopTrackingTimer()
                
            }

            .alert("Konum İzni Gerekli", isPresented: $showLocationPermissionAlert) {
                Button("Ayarlara Git") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Tekrar İste") {
                    locationManager.requestLocationPermission()
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Rota takibi için 'Her Zaman' konum izni gereklidir. Uygulama kapalıyken bile tracking devam etmesi için bu izin şarttır. Lütfen ayarlardan konum iznini 'Her Zaman' olarak ayarlayın.")
            }

            // Çıkış butonu sağ üstte küçük
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.black)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 40, height: 40)
                            )
                    }
                    .padding(.trailing, 20)

                    /*
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                            .padding(8)
                    }
                     */
                }
                .padding(.top, 70)
                .padding(.horizontal)
                Spacer()
            }
            // Sağ alt köşe butonlar (ekstra: konumu bul ve harita tipi)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 14) {
                        // Konumu bul butonu
                        Button(action: {
                            centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        // Harita tipi değiştir butonu
                        Button(action: {
                            DispatchQueue.main.async {
                                switch mapType {
                                case .standard:
                                    mapType = .hybrid
                                case .hybrid:
                                    mapType = .satellite
                                default:
                                    mapType = .standard
                                }
                            }
                        }) {
                            Image(systemName: mapType == .standard ? "map" : (mapType == .hybrid ? "globe.europe.africa.fill" : "photo.fill"))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.gray)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding(.bottom, 32)
                    .padding(.trailing, 18)
                }
            }
        }
        .fullScreenCover(isPresented: $showInfoSheet) {
            RouteInfoSheet(route: route, totalDistance: totalDistance, averageSpeed: averageSpeed, isRouteActive: isRouteActive, routeLocations: routeLocations)
        }
        .onAppear {
            DispatchQueue.main.async {
                updateRegionToCurrentLocation()
                isTracking = locationManager.isRouteTracking && locationManager.activeScheduleId == route.id
                if !hasCenteredOnUser {
                    centerOnUserLocation()
                    hasCenteredOnUser = true
                }
            }
            startNowTimer()
        }
        .onDisappear {
            stopTrackingTimer()
            NotificationCenter.default.removeObserver(self)
        }
        .ignoresSafeArea()
    }

    // MARK: - Harita
    private var mapSection: some View {
        Group {
            if let userLocation = locationManager.currentLocation {
                let annotation = CLUserLocationAnnotation(coordinate: userLocation.coordinate)
                Map(coordinateRegion: $region, annotationItems: [annotation]) { item in
                    MapMarker(coordinate: item.coordinate, tint: .green)
                }
            } else {
                Map(coordinateRegion: $region)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                updateRegionToCurrentLocation()
            }
        }
    }

    // MARK: - Takip Fonksiyonları
    private func startTracking() {
        
        // Konum izni kontrolü - Always izni gerekli
        if locationManager.locationPermissionStatus != .authorizedAlways {
            showLocationPermissionAlert = true
            return
        }
        
        // Rota saat aralığı kontrolü
        let now = Date()
        let startDate = routeStartDate
        let endDate = routeEndDate
        
        print("🔍 [RouteTrackingView] startTracking çağrıldı")
        print("🔍 [RouteTrackingView] Şu anki zaman: \(now)")
        print("🔍 [RouteTrackingView] Başlangıç zamanı: \(startDate?.description ?? "nil")")
        print("🔍 [RouteTrackingView] Bitiş zamanı: \(endDate?.description ?? "nil")")
        
        guard let startDate = startDate,
              let endDate = endDate,
              now >= startDate && now <= endDate else {
            print("❌ [RouteTrackingView] Zaman kontrolü başarısız - tracking başlatılamıyor")
            return
        }
        
        print("✅ [RouteTrackingView] Zaman kontrolü başarılı - tracking başlatılıyor")
        
        DispatchQueue.main.async {
            if trackingStartDate == nil {
                trackingStartDate = Date()
            }
            lastResumeDate = Date()
            isTracking = true
            isRouteActive = true
        }
        startTrackingTimer()
        
        // Konum izni iste (Always için)
        locationManager.requestLocationPermission()
        
        // Rota takibini başlat
        locationManager.startRouteTracking(route: route)
        
        // Konum geçmişini temizle
        routeLocations.removeAll()
        totalDistance = 0
        averageSpeed = 0
        
    }
    
    private func pauseTracking() {
        
        DispatchQueue.main.async {
            if let last = lastResumeDate {
                trackingElapsed += Date().timeIntervalSince(last)
            }
            lastResumeDate = nil
            isTracking = false
            isRouteActive = false
        }
        stopTrackingTimer()
        
        // Rota takibini durdur
        locationManager.stopRouteTracking()
        
    }
    
    private func stopTracking() {
        pauseTracking()
        DispatchQueue.main.async {
            trackingStartDate = nil
            trackingElapsed = 0
            isRouteActive = false
        }
        
        // LocationManager ile rota takibini tamamen durdur (work status "completed" olacak)
        locationManager.completeRouteTracking()
        
    }
    private func updateRegionToCurrentLocation() {
        if let loc = locationManager.currentLocation {
            DispatchQueue.main.async {
                region.center = loc.coordinate
            }
        }
    }
    // --- Progress Bar Helpers ---
    private var routeDurationSeconds: TimeInterval {
        guard let start = routeStartDate, let end = routeEndDate else { return 1 }
        return end.timeIntervalSince(start)
    }
    private var routeStartDate: Date? {
        let dateString = route.scheduleDate + " " + route.startTime
        
        // Türkiye saati olarak parse et (UTC dönüşümü yok)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        guard let localDate = localFormatter.date(from: dateString) else {
            return nil
        }
        
        return localDate
    }
    private var routeEndDate: Date? {
        let dateString = route.scheduleDate + " " + route.endTime
        
        // 24:00:00 formatını kontrol et
        var modifiedDateString = dateString
        var is24HourFormat = false
        if dateString.contains("24:00:00") {
            modifiedDateString = dateString.replacingOccurrences(of: "24:00:00", with: "23:59:59")
            is24HourFormat = true
        }
        
        // Türkiye saati olarak parse et (UTC dönüşümü yok)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        guard let localDate = localFormatter.date(from: modifiedDateString) else {
            return nil
        }
        
        // Eğer 24:00:00 ise, 1 saniye ekle (aynı günün sonu)
        var finalDate = localDate
        if is24HourFormat {
            finalDate = localDate.addingTimeInterval(1)
        }
        
        return finalDate
    }
    // --- Timer Logic ---
    private func startNowTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            now = Date()
        }
    }
    private func stopNowTimer() {
        // No-op, timer is not retained
    }
    private func startTrackingTimer() {
        stopTrackingTimer()
        
        // Timer'ı güvenli bir şekilde başlat
        DispatchQueue.main.async {
            self.trackingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.now = Date()
                }
            }
        }
    }
    
    private func stopTrackingTimer() {
        DispatchQueue.main.async {
            trackingTimer?.invalidate()
            trackingTimer = nil
        }
    }

    private func getLocationStatusColor() -> Color {
        switch locationManager.locationPermissionStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return Color.green
        case .denied, .restricted:
            return Color.red
        case .notDetermined:
            return Color.yellow
        @unknown default:
            return Color.yellow
        }
    }

    private func getLocationStatusText() -> String {
        switch locationManager.locationPermissionStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Konum Aktif"
        case .denied, .restricted:
            return "Konum Kapalı"
        case .notDetermined:
            return "Konum İzni Bekleniyor"
        @unknown default:
            return "Konum İzni Bekleniyor"
        }
    }
    
    private func centerOnUserLocation() {
        
        // Konum izni kontrolü
        print("🔍 [RouteTrackingView] Konum izni durumu: \(locationManager.locationPermissionStatus.rawValue)")
        if locationManager.locationPermissionStatus != .authorizedAlways {
            print("❌ [RouteTrackingView] Konum izni yetersiz - Always izni gerekli")
            showLocationPermissionAlert = true
            return
        }
        print("✅ [RouteTrackingView] Konum izni yeterli")
        
        // Mevcut konum varsa hemen odaklan
        if let userLocation = locationManager.currentLocation {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.2)) {
                    region.center = userLocation.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                }
            }
        } else {
            // Konum güncellemelerini başlat
            locationManager.requestLocationPermission()
            
            // Konum henüz alınamadıysa, kısa bir gecikme ile tekrar dene
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let userLocation = locationManager.currentLocation {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            region.center = userLocation.coordinate
                            region.span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                        }
                    }
                }
            }
        }
    }

    private func updateRouteStats() {
        guard routeLocations.count > 1 else { return }
        
        // Toplam mesafe hesapla
        var distance: Double = 0
        var totalSpeed: Double = 0
        var speedCount = 0
        
        for i in 0..<(routeLocations.count - 1) {
            let loc1 = routeLocations[i]
            let loc2 = routeLocations[i + 1]
            
            let location1 = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
            let location2 = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
            
            distance += location1.distance(from: location2)
            
            // Hız hesapla (km/h)
            if loc2.speed > 0 {
                totalSpeed += loc2.speed * 3.6 // m/s'den km/h'ye çevir
                speedCount += 1
            }
        }
        
        DispatchQueue.main.async {
            self.totalDistance = distance / 1000 // metre'den km'ye çevir
            self.averageSpeed = speedCount > 0 ? totalSpeed / Double(speedCount) : 0
        }
    }

    private func setupInitialState() {
        
        // LocationManager'daki mevcut durumu kontrol et
        if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
            isTracking = true
            isRouteActive = true
            startTrackingTimer()
            
            // Mevcut konum geçmişini al
            routeLocations = locationManager.getRouteLocations()
            updateRouteStats()
        } else if route.workStatus == "working" {
            // Route workStatus "working" ise LocationManager'da tracking başlat
            locationManager.startRouteTracking(route: route)
            isTracking = true
            isRouteActive = true
            startTrackingTimer()
        } else {
            isTracking = false
            isRouteActive = false
            stopTrackingTimer()
        }
    }

    private func getButtonIcon() -> String {
        
        // LocationManager'daki mevcut durumu kontrol et
        if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
            return "pause.fill"
        } else {
            // Rota zamanı kontrolü
            if isRouteTimeActive() {
                return "play.fill"
            } else {
                return "clock"
            }
        }
    }

    private func getButtonText() -> String {
        
        // LocationManager'daki mevcut durumu kontrol et
        if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
            return "Duraklat"
        } else {
            // Rota zamanı kontrolü
            if isRouteTimeActive() {
                return "Başlat"
            } else {
                return "Zaman Dışı"
            }
        }
    }

    private func getButtonColor() -> Color {
        
        // LocationManager'daki mevcut durumu kontrol et
        if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
            return Color.orange
        } else {
            // Rota zamanı kontrolü
            if isRouteTimeActive() {
                return Color.green
            } else {
                return Color.black.opacity(0.6)
            }
        }
    }
    
    private func isRouteTimeActive() -> Bool {
        let now = Date()
        let startDate = getRouteStartDate()
        let endDate = getRouteEndDate()
        
        guard let startDate = startDate, let endDate = endDate else {
            return false
        }
        
        return now >= startDate && now <= endDate
    }
    
    private func getRouteStartDate() -> Date? {
        let dateTimeString = "\(route.scheduleDate) \(route.startTime)"
        return DateFormatter.dateFromDateTime(dateTimeString)
    }
    
    private func getRouteEndDate() -> Date? {
        let dateTimeString = "\(route.scheduleDate) \(route.endTime)"
        return DateFormatter.dateFromDateTime(dateTimeString)
    }
}

// MARK: - LocationManager Extension for Route Tracking

extension LocationManager {
    func addRouteLocationUpdateObserver(routeId: String, completion: @escaping (LocationData) -> Void) {
        // Konum güncellemelerini dinle
        NotificationCenter.default.addObserver(
            forName: .locationPermissionGranted,
            object: nil,
            queue: .main
        ) { _ in
            // Konum izni verildiğinde yapılacak işlemler
        }
    }
}

// CLUserLocationAnnotation: Identifiable wrapper
struct CLUserLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Çalışan Rota Detay Sayfası
struct RouteInfoSheet: View {
    let route: Assignment
    @Environment(\.dismiss) private var dismiss
    @State private var showEmergencyContact = false
    
    // Rota istatistikleri için parametreler
    let totalDistance: Double
    let averageSpeed: Double
    let isRouteActive: Bool
    let routeLocations: [LocationData]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Capsule()
                        .frame(width: 40, height: 6)
                        .foregroundColor(.gray.opacity(0.2))
                        .padding(.top, 8)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Çalışma Detayları")
                                .font(.title2.bold())
                            Text("Rota #\(route.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        AssignmentStatusBadge(status: route.assignmentStatus)
                    }
                }
                .padding()
                
                // Ana Bilgiler
                VStack(spacing: 24) {
                    // Görev Açıklaması
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.bullet.clipboard")
                                .foregroundColor(.blue)
                            Text("Görev Detayları")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text(route.assignmentOfferDescription ?? "Görev açıklaması bulunmuyor")
                                .font(.body)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label(route.formattedTurkishDate, systemImage: "calendar")
                                        .font(.subheadline.bold())
                                    Text("Çalışma Tarihi")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 6) {
                                    Label("\(route.formattedStartTime) - \(route.formattedEndTime)", systemImage: "clock")
                                        .font(.subheadline.bold())
                                    Text("Çalışma Saatleri")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                                        Divider()
                    
                    // Çalışma Durumu
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                            Text("Çalışma Durumu")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 16) {
                            // Durum Kartı
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(route.assignmentStatus.statusDescription)
                                        .font(.subheadline.bold())
                                        .foregroundColor(route.assignmentStatus.statusColor)
                                    Text("Mevcut Durum")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("₺\(route.assignmentOfferBudget)")
                                        .font(.title3.bold())
                                        .foregroundColor(.green)
                                    Text("Kazanç")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // İlerleme Çubuğu
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Çalışma İlerlemesi")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(calculateProgressPercentage())%")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: calculateProgressValue())
                                    .accentColor(.blue)
                                    .frame(height: 8)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                                        Divider()
                    
                    // Konum Bilgileri
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text("Konum Bilgileri")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Başlangıç Noktası")
                                        .font(.subheadline.bold())
                                    Text("\(route.startLat), \(route.startLng)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Bitiş Noktası")
                                        .font(.subheadline.bold())
                                    Text("\(route.endLat), \(route.endLng)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Çalışma Alanı")
                                        .font(.subheadline.bold())
                                    Text("\(route.radiusMeters) metre yarıçap")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Rota Tipi")
                                        .font(.subheadline.bold())
                                    Text(route.routeType)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Rota İstatistikleri (Sadece aktif rota için)
                    if isRouteActive {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green)
                                Text("Rota İstatistikleri")
                                    .font(.headline)
                            }
                            
                            VStack(spacing: 16) {
                                // İstatistik Kartları
                                HStack(spacing: 16) {
                                    // Toplam Mesafe
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(format: "%.2f km", totalDistance))
                                            .font(.title3.bold())
                                            .foregroundColor(.blue)
                                        Text("Toplam Mesafe")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                    
                                    // Ortalama Hız
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(String(format: "%.1f km/h", averageSpeed))
                                            .font(.title3.bold())
                                            .foregroundColor(.green)
                                        Text("Ortalama Hız")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                // Konum Sayısı
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(routeLocations.count)")
                                            .font(.title3.bold())
                                            .foregroundColor(.orange)
                                        Text("Konum Kaydı")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Canlı Takip")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.green)
                                        Text("Aktif")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Hızlı Aksiyonlar
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            Text("Hızlı Aksiyonlar")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            // Acil Durum Butonu
                            Button(action: {
                                showEmergencyContact = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Acil Durum İletişimi")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                            
                            // Çalışma Raporu
                            Button(action: {
                                // Çalışma raporu oluştur
                                let reportText = """
                                📋 Çalışma Raporu
                                
                                🆔 Rota ID: \(route.id)
                                📝 Görev: \(route.assignmentOfferDescription ?? "Görev")
                                📅 Tarih: \(route.formattedTurkishDate)
                                ⏰ Saat: \(route.formattedStartTime) - \(route.formattedEndTime)
                                💰 Kazanç: ₺\(route.assignmentOfferBudget)
                                📊 Durum: \(route.assignmentStatus.statusDescription)
                                📍 Konum: \(route.startLat), \(route.startLng)
                                
                                📱 Bu İş Yürür uygulamasından oluşturuldu
                                """
                                
                                UIPasteboard.general.string = reportText
                                
                                let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                    Text("Çalışma Raporu Oluştur")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Destek İste
                            Button(action: {
                                // Destek ekranını aç
                                if let supportUrl = URL(string: "tel:08502222222") {
                                    UIApplication.shared.open(supportUrl)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Destek Ara")
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Kapat Butonu
                Button(action: {
                    dismiss()
                }) {
                    Text("Kapat")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .alert("Acil Durum İletişimi", isPresented: $showEmergencyContact) {
            Button("Acil Servis (112)") {
                if let emergencyUrl = URL(string: "tel:112") {
                    UIApplication.shared.open(emergencyUrl)
                }
            }
            Button("Güvenlik (155)") {
                if let securityUrl = URL(string: "tel:155") {
                    UIApplication.shared.open(securityUrl)
                }
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Acil durumda hangi servisi aramak istiyorsunuz?")
        }

    }
    
    // İlerleme hesaplama fonksiyonları
    private func calculateProgressValue() -> Double {
        guard let start = getRouteStartDate(), let end = getRouteEndDate() else { return 0 }
        let total = end.timeIntervalSince(start)
        let now = Date()
        let elapsed = now.timeIntervalSince(start)
        return total > 0 ? min(max(elapsed / total, 0), 1) : 0
    }
    
    private func calculateProgressPercentage() -> Int {
        return Int(calculateProgressValue() * 100)
    }
    
    // Tarih hesaplama fonksiyonları
    private func getRouteStartDate() -> Date? {
        let dateString = route.scheduleDate + " " + route.startTime
        
        // Türkiye saati olarak parse et (UTC dönüşümü yok)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        guard let localDate = localFormatter.date(from: dateString) else {
            return nil
        }
        
        return localDate
    }
    
    private func getRouteEndDate() -> Date? {
        let dateString = route.scheduleDate + " " + route.endTime
        
        // 24:00:00 formatını kontrol et
        var modifiedDateString = dateString
        var is24HourFormat = false
        if dateString.contains("24:00:00") {
            modifiedDateString = dateString.replacingOccurrences(of: "24:00:00", with: "23:59:59")
            is24HourFormat = true
        }
        
        // Türkiye saati olarak parse et (UTC dönüşümü yok)
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        guard let localDate = localFormatter.date(from: modifiedDateString) else {
            return nil
        }
        
        // Eğer 24:00:00 ise, 1 saniye ekle (aynı günün sonu)
        var finalDate = localDate
        if is24HourFormat {
            finalDate = localDate.addingTimeInterval(1)
        }
        
        return finalDate
    }
}

 

#Preview {
    RouteTrackingView(route: Assignment.preview)
}

// --- Progress Bar Views ---
struct RouteDurationProgressBar: View {
    let route: Assignment
    @Binding var now: Date
    
    var body: some View {
        let progressData = calculateProgressData()
        
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: progressData.progress)
                .accentColor(.blue)
                .frame(height: 8)
                .clipShape(Capsule())
            HStack {
                Text("Rota Süresi: \(progressData.startTime) - \(progressData.endTime)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Kalan: \(progressData.remaining)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func calculateProgressData() -> (progress: Double, startTime: String, endTime: String, remaining: String) {
        let (start, end) = getRouteDates()
        let total = max(end.timeIntervalSince(start), 1)
        let elapsed = min(max(now.timeIntervalSince(start), 0), total)
        let progress = total > 0 ? min(elapsed / total, 1.0) : 0
        let remaining = max(total - elapsed, 0)
        
        return (
            progress: progress,
            startTime: formatTime(start),
            endTime: formatTime(end),
            remaining: formatDuration(remaining)
        )
    }
    
    private func getRouteDates() -> (Date, Date) {
        let startString = route.scheduleDate + " " + route.startTime
        let endString = route.scheduleDate + " " + route.endTime
        
        // Türkiye saati formatter
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        // Start date parsing
        guard let start = localFormatter.date(from: startString) else {
            return (Date(), Date().addingTimeInterval(3600))
        }
        
        // End date parsing with 24:00:00 support
        var modifiedEndString = endString
        var is24HourFormat = false
        if endString.contains("24:00:00") {
            modifiedEndString = endString.replacingOccurrences(of: "24:00:00", with: "23:59:59")
            is24HourFormat = true
        }
        
        guard let endLocal = localFormatter.date(from: modifiedEndString) else {
            return (start, start.addingTimeInterval(3600))
        }
        
        var end = endLocal
        
        // Eğer 24:00:00 ise, 1 saniye ekle (aynı günün sonu)
        if is24HourFormat {
            end = end.addingTimeInterval(1)
        }
        
        // End date'in start date'den sonra olduğundan emin ol
        let safeEnd = end > start ? end : start.addingTimeInterval(3600)
        
        return (start, safeEnd)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        let timeString = formatter.string(from: date)
        
        // Eğer saat 00:00 ise ve bu end time ise, 24:00 olarak göster
        if timeString == "00:00" && route.endTime.contains("24:00:00") {
            return "24:00"
        }
        
        return timeString
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let safeInterval = max(interval, 0)
        let ti = Int(safeInterval)
        let h = ti / 3600
        let m = (ti % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}

struct TrackedTimeProgressBar: View {
    let elapsed: TimeInterval
    let total: TimeInterval
    
    var body: some View {
        let progressData = calculateProgressData()
        
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: progressData.progress)
                .accentColor(.green)
                .frame(height: 8)
                .clipShape(Capsule())
            HStack {
                Text("Çalışılan Süre: \(progressData.elapsed)")
                .font(.caption2)
                .foregroundColor(.secondary)
                Spacer()
                Text("Toplam: \(progressData.total)")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func calculateProgressData() -> (progress: Double, elapsed: String, total: String) {
        let safeElapsed = max(elapsed, 0)
        let safeTotal = max(total, 1)
        let progress = safeTotal > 0 ? min(safeElapsed / safeTotal, 1.0) : 0
        
        return (
            progress: progress,
            elapsed: formatDuration(safeElapsed),
            total: formatDuration(safeTotal)
        )
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let safeInterval = max(interval, 0)
        let ti = Int(safeInterval)
        let h = ti / 3600
        let m = (ti % 3600) / 60
        return String(format: "%02d:%02d", h, m)
    }
}
