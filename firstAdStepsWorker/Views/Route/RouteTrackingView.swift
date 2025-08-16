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
    // Rota zamanı kontrolü için timer
    @State private var routeTimeCheckTimer: Timer? = nil

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
                
                // Work Time Display - KALDIRILDI
                // HStack {
                //     Spacer()
                //     WorkTimeDisplay()
                //     Spacer()
                // }
                // .padding(.horizontal, 24)
                // .padding(.top, 8)
                
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
                    

                    
                    // Rota Tamamla butonu (sadece zaman içindeyken ve tamamlanmamışken görünür)
                    if isRouteTimeActive() && route.assignmentWorkStatus != .completed {
                        Button(action: {
                            print("🔴 [RouteTrackingView] Tamamla butonuna basıldı")
                            
                            // UI state'lerini temizle
                            DispatchQueue.main.async {
                                if let last = lastResumeDate {
                                    trackingElapsed += Date().timeIntervalSince(last)
                                }
                                lastResumeDate = nil
                                isTracking = false
                                isRouteActive = false
                            }
                            stopTrackingTimer()
                            
                            // Rota tamamlama işlemini başlat (paused göndermeden direkt completed)
                            print("🔴 [RouteTrackingView] completeRouteTracking çağrılıyor")
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
                        .disabled(!locationManager.isRouteTracking || locationManager.activeScheduleId != route.id)
                    }
                    Spacer()

                }
                .padding(.horizontal)

                // --- Smart Filtering Setting ---
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.gray600)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Akıllı Konum Filtreleme")
                                .font(.system(size: 14, weight: .medium))
                                .fixedSize()
                                .foregroundColor(Theme.gray600)
                            
                            HStack {
                                Text(locationManager.smartFilteringEnabled ? "Açık" : "Kapalı")
                                    .fixedSize()
                                    .font(.system(size: 14))
                                    .bold()
                                    .foregroundColor(locationManager.smartFilteringEnabled ? Color.green : Theme.gray600)
                                Text(locationManager.smartFilteringEnabled ? "Daha az veri gönderir" : "Tüm konumlar gönderilir")
                                    .fixedSize()
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.gray600)
                            }
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $locationManager.smartFilteringEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .green))
                            .scaleEffect(0.8)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.horizontal)

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
                stopRouteTimeCheckTimer()
                
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
        
        // Rota zamanı kontrolü için timer başlat
        startRouteTimeCheckTimer()
    }
    private func stopNowTimer() {
        // No-op, timer is not retained
        stopRouteTimeCheckTimer()
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
    
    // Rota zamanı kontrolü için timer fonksiyonları
    private func startRouteTimeCheckTimer() {
        stopRouteTimeCheckTimer()
        
        DispatchQueue.main.async {
            self.routeTimeCheckTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                self.checkRouteTimeAndAutoComplete()
            }
        }
    }
    
    private func stopRouteTimeCheckTimer() {
        DispatchQueue.main.async {
            routeTimeCheckTimer?.invalidate()
            routeTimeCheckTimer = nil
        }
    }
    
    private func checkRouteTimeAndAutoComplete() {
        // Eğer rota takibi aktifse ve zaman dışındaysa otomatik tamamla
        if locationManager.isRouteTracking && 
           locationManager.activeScheduleId == route.id && 
           !isRouteTimeActive() {
            
            print("⏰ [RouteTrackingView] Rota zamanı doldu, otomatik tamamlama başlatılıyor")
            
            // UI state'lerini temizle
            DispatchQueue.main.async {
                if let last = lastResumeDate {
                    trackingElapsed += Date().timeIntervalSince(last)
                }
                lastResumeDate = nil
                isTracking = false
                isRouteActive = false
            }
            stopTrackingTimer()
            
            // Rota tamamlama işlemini başlat
            locationManager.completeRouteTracking()
            
            // Kısa bir gecikme ile view'ı kapat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
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
        
        // Rota durumunu kontrol et
        if route.workStatus == "completed" {
            return "Tamamlandı"
        } else if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
            return "Durdur"
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
        
        // Rota durumunu kontrol et
        if route.workStatus == "completed" {
            return Color.gray
        } else if locationManager.isRouteTracking && locationManager.activeScheduleId == route.id {
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

// Modern Rota Detay Sayfası
struct RouteInfoSheet: View {
    let route: Assignment
    @Environment(\.dismiss) private var dismiss
    @State private var showEmergencyContact = false
    @State private var showMapOptions = false
    
    // Rota istatistikleri için parametreler
    let totalDistance: Double
    let averageSpeed: Double
    let isRouteActive: Bool
    let routeLocations: [LocationData]
    
    var body: some View {
        NavigationView {
        ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Section - Header
                    heroSection
                    
                    // Overview Section - Genel Bilgiler
                    overviewSection
                    
                    // Status Section - Durum ve İlerleme
                    statusSection
                    
                    // Location Section - Konum Bilgileri
                    locationSection
                    
                    // Map Section - Harita Görüntüsü
                    mapSection
                    
                    // Statistics Section - İstatistikler (Aktif rota için)
                    if isRouteActive {
                        statisticsSection
                    }
                    
                    // Actions Section - Hızlı Aksiyonlar
                    actionsSection
                    
                    // Bottom Spacing
                    Color.clear.frame(height: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                                .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    AssignmentStatusBadge(status: route.assignmentStatus)
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
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Rota ID ve Başlık
            VStack(spacing: 8) {
                Text("Rota #\(route.id)")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                            Text(route.assignmentOfferDescription ?? "Görev açıklaması bulunmuyor")
                                .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Tarih ve Saat Bilgileri
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(route.formattedTurkishDate)
                        .font(.caption.bold())
                    Text("Tarih")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                
                VStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("\(route.formattedStartTime)")
                        .font(.caption.bold())
                    Text("Başlangıç")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text("\(route.formattedEndTime)")
                        .font(.caption.bold())
                    Text("Bitiş")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Genel Bilgiler", icon: "info.circle", color: .blue)
            
            VStack(spacing: 12) {
                // Kazanç Kartı
                        HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kazanç")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("₺\(route.assignmentOfferBudget)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Image(systemName: "banknote")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Rota Tipi ve Alan
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rota Tipi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(route.routeType)
                            .font(.subheadline.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Çalışma Alanı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(route.radiusMeters)m")
                            .font(.subheadline.bold())
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Status Section
    private var statusSection: some View {
                        VStack(spacing: 16) {
            sectionHeader(title: "Durum ve İlerleme", icon: "chart.bar.fill", color: .orange)
            
            VStack(spacing: 12) {
                            // Durum Kartı
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                        Text("Mevcut Durum")
                            .font(.caption)
                            .foregroundColor(.secondary)
                                    Text(route.assignmentStatus.statusDescription)
                                        .font(.subheadline.bold())
                                        .foregroundColor(route.assignmentStatus.statusColor)
                                }
                                Spacer()
                    Image(systemName: route.assignmentStatus.icon)
                        .font(.title2)
                        .foregroundColor(route.assignmentStatus.statusColor)
                }
                .padding(16)
                .background(route.assignmentStatus.statusColor.opacity(0.1))
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
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Konum Bilgileri", icon: "location.fill", color: .red)
                        
                        VStack(spacing: 12) {
                // Başlangıç Noktası
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Başlangıç Noktası")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                        Text("\(route.startLat), \(route.startLng)")
                            .font(.subheadline.bold())
                                }
                                Spacer()
                    Image(systemName: "mappin.circle")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .padding(16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                
                // Bitiş Noktası
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                        Text("Bitiş Noktası")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                        Text("\(route.endLat), \(route.endLng)")
                            .font(.subheadline.bold())
                                }
                                Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
                            VStack(spacing: 16) {
            sectionHeader(title: "Canlı İstatistikler", icon: "chart.line.uptrend.xyaxis", color: .green)
            
            VStack(spacing: 12) {
                                // İstatistik Kartları
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                                    // Toplam Mesafe
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.blue)
                            Spacer()
                            Text(String(format: "%.2f", totalDistance))
                                            .font(.title3.bold())
                                            .foregroundColor(.blue)
                        }
                        Text("km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                                        Text("Toplam Mesafe")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                    .padding(16)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                    
                                    // Ortalama Hız
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.green)
                            Spacer()
                            Text(String(format: "%.1f", averageSpeed))
                                            .font(.title3.bold())
                                            .foregroundColor(.green)
                        }
                        Text("km/h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                                        Text("Ortalama Hız")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                    .padding(16)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                // Konum Kayıtları
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                        Text("Konum Kaydı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                                        Text("\(routeLocations.count)")
                                            .font(.title3.bold())
                                            .foregroundColor(.orange)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Canlı Takip")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.green)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                        Text("Aktif")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    }
                                }
                }
                .padding(16)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Hızlı Aksiyonlar", icon: "bolt.fill", color: .yellow)
                        
                        VStack(spacing: 12) {
                            // Acil Durum Butonu
                            Button(action: {
                                showEmergencyContact = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("Acil Durum İletişimi")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                    .padding(16)
                                .background(Color.red)
                    .cornerRadius(12)
                            }
                            
                            // Çalışma Raporu
                            Button(action: {
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
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                    .padding(16)
                                .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                            }
                            
                // Destek Ara
                            Button(action: {
                                if let supportUrl = URL(string: "tel:08502222222") {
                                    UIApplication.shared.open(supportUrl)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "phone.fill")
                                    Text("Destek Ara")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                    .padding(16)
                                .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                            }
                        }
                    }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
                }
                
    // MARK: - Map Section
    private var mapSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Rota Haritası", icon: "map.fill", color: .blue)
                
            VStack(spacing: 12) {
                // Harita Görüntüsü
                if let mapUrl = route.mapSnapshotUrl {
                Button(action: {
                        showMapOptions = true
                    }) {
                        AsyncImage(url: URL(string: "https://buisyurur.com\(mapUrl)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        } placeholder: {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        Text("Harita yükleniyor...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                )
                                .cornerRadius(12)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        showMapOptions = true
                    }) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "map")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                    Text("Harita görüntüsü yok")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Harita Aksiyonları
                HStack(spacing: 12) {
                    Button(action: {
                        openInAppleMaps()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "map")
                            Text("Apple Maps")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        openInGoogleMaps()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "map")
                            Text("Google Maps")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Map Functions
    private func openInAppleMaps() {
        if route.routeType == "fixed_route" {
            // Sabit rota: Başlangıç noktasını aç
            if let url = URL(string: "http://maps.apple.com/?q=\(route.startLat),\(route.startLng)") {
                UIApplication.shared.open(url)
            }
        } else {
            // Alan rota: Merkez noktasını aç
            if let url = URL(string: "http://maps.apple.com/?q=\(route.centerLat),\(route.centerLng)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openInGoogleMaps() {
        if route.routeType == "fixed_route" {
            // Sabit rota: Başlangıç noktasını aç
            if let url = URL(string: "comgooglemaps://?q=\(route.startLat),\(route.startLng)") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else {
                    if let webUrl = URL(string: "https://maps.google.com/?q=\(route.startLat),\(route.startLng)") {
                        UIApplication.shared.open(webUrl)
                    }
                }
            }
        } else {
            // Alan rota: Merkez noktasını aç
            if let url = URL(string: "comgooglemaps://?q=\(route.centerLat),\(route.centerLng)") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else {
                    if let webUrl = URL(string: "https://maps.google.com/?q=\(route.centerLat),\(route.centerLng)") {
                        UIApplication.shared.open(webUrl)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
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
    
    private func getRouteStartDate() -> Date? {
        let dateString = route.scheduleDate + " " + route.startTime
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return localFormatter.date(from: dateString)
    }
    
    private func getRouteEndDate() -> Date? {
        let dateString = route.scheduleDate + " " + route.endTime
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return localFormatter.date(from: dateString)
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
