import SwiftUI
import MapKit

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

    var body: some View {
        ZStack {
            // Tam ekran harita
            mapSection
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
                
                HStack(spacing: 12) {
                    Spacer()
                    // Info butonu
                    Button(action: { showInfoSheet = true }) {
                        HStack {
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

                    // Takip Başlat/Durdur butonu
                    Button(action: { isTracking ? pauseTracking() : startTracking() }) {
                        HStack {
                            Image(systemName: isTracking ? "pause.fill" : "play.fill")
                            Text(isTracking ? "Duraklat" : "Başlat")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(isTracking ? Color.orange : Color.green)
                        .cornerRadius(8)
                        // .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

                    }
                    
                    // Rota Tamamla butonu (sadece takip aktifken göster)
                    if isTracking {
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
                            HStack {
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
                VStack(spacing: 18) {

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
                // Konum izni kontrolü ve hazırlık
                locationManager.requestLocationPermission()
                
                // Konum izni bekleniyorsa alert göster
                if locationManager.locationPermissionStatus == .notDetermined {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showLocationPermissionAlert = true
                    }
                }
                
                // Eğer zaten rota takibi aktifse, durumu güncelle
                if locationManager.isTrackingRoute(routeId: route.id) {
                    isTracking = true
                    startTrackingTimer()
                }
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                // Konum güncellendiğinde harita bölgesini güncelle
                if let location = newLocation {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            region.center = location.coordinate
                        }
                    }
                }
            }
            .alert("Konum İzni Gerekli", isPresented: $showLocationPermissionAlert) {
                Button("Ayarlara Git") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("İptal", role: .cancel) { }
            } message: {
                Text("Rota takibi için konum izni gereklidir. Lütfen ayarlardan konum iznini verin.")
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
                .padding(.top, 54)
                .padding(.horizontal)
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showInfoSheet) {
            RouteInfoSheet(route: route)
        }
        .onAppear {
            updateRegionToCurrentLocation()
            isTracking = locationManager.isTrackingRoute(routeId: route.id)
            startNowTimer()
        }
        .onDisappear {
            stopNowTimer()
            stopTrackingTimer()
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
            updateRegionToCurrentLocation()
        }
    }

    // MARK: - Takip Fonksiyonları
    private func startTracking() {
        if trackingStartDate == nil {
            trackingStartDate = Date()
        }
        lastResumeDate = Date()
        isTracking = true
        startTrackingTimer()
        
        // iOS 14+ için geçici konum izni iste
        locationManager.requestTemporaryLocationPermission()
        
        locationManager.startRouteTracking(routeId: route.id) // Start location tracking
        
        // Send first location immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let currentLocation = self.locationManager.currentLocation {
                let locationData = LocationData(
                    routeId: self.route.id,
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    accuracy: currentLocation.horizontalAccuracy,
                    timestamp: Date(),
                    speed: currentLocation.speed,
                    heading: currentLocation.course
                )
                self.locationManager.sendLocationToAPI(parameters: locationData) { _ in
                    print("📍 RouteTrackingView: İlk konum verisi gönderildi")
                }
            }
        }
        print("📍 RouteTrackingView: Rota takibi başlatıldı - Route ID: \(route.id)")
    }
    
    private func pauseTracking() {
        if let last = lastResumeDate {
            trackingElapsed += Date().timeIntervalSince(last)
        }
        lastResumeDate = nil
        isTracking = false
        stopTrackingTimer()
        
        // LocationManager ile rota takibini durdur
        locationManager.stopRouteTracking()
        
        print("📍 RouteTrackingView: Rota takibi duraklatıldı - Route ID: \(route.id)")
    }
    
    private func stopTracking() {
        pauseTracking()
        trackingStartDate = nil
        trackingElapsed = 0
        
        // LocationManager ile rota takibini tamamen durdur
        locationManager.stopRouteTracking()
        
        print("📍 RouteTrackingView: Rota takibi durduruldu - Route ID: \(route.id)")
    }
    private func updateRegionToCurrentLocation() {
        if let loc = locationManager.currentLocation {
            region.center = loc.coordinate
        }
    }
    // --- Progress Bar Helpers ---
    private var routeDurationSeconds: TimeInterval {
        guard let start = routeStartDate, let end = routeEndDate else { return 1 }
        return end.timeIntervalSince(start)
    }
    private var routeStartDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = route.scheduleDate + " " + route.startTime
        return formatter.date(from: dateString)
    }
    private var routeEndDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = route.scheduleDate + " " + route.endTime
        return formatter.date(from: dateString)
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
            self.trackingTimer?.invalidate()
            self.trackingTimer = nil
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
}

// CLUserLocationAnnotation: Identifiable wrapper
struct CLUserLocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Info bottom sheet
struct RouteInfoSheet: View {
    let route: Assignment
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(.gray.opacity(0.2))
                .padding(.top, 8)
            Text("Rota Bilgileri")
                .font(.title2.bold())
            VStack(alignment: .leading, spacing: 12) {
                Text(route.assignmentOfferDescription ?? "Görev")
                    .font(.headline)
                Label(route.scheduleDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("Bütçe: ₺" + route.assignmentOfferBudget, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("Başlangıç: " + route.startTime, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button(action: {
                dismiss()
            }, label: {
                Text("Kapat")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            })
        }
        .padding(24)
        .presentationDetents([.medium, .large])
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let startString = route.scheduleDate + " " + route.startTime
        let endString = route.scheduleDate + " " + route.endTime
        
        // Güvenli tarih parsing
        let start = formatter.date(from: startString) ?? Date()
        let end = formatter.date(from: endString) ?? Date().addingTimeInterval(3600)
        
        // End date'in start date'den sonra olduğundan emin ol
        let safeEnd = end > start ? end : start.addingTimeInterval(3600)
        
        return (start, safeEnd)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
