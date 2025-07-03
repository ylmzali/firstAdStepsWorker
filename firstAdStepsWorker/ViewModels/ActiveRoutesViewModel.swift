import Foundation
import MapKit
import SwiftUI

@MainActor
class ActiveRoutesViewModel: ObservableObject {
    @Published var schedules: [ActiveSchedule] = []
    @Published var error: ServiceError?
    @Published var selectedDate = Date()
    @Published var selectedScheduleIds: [Int] = []
    
    // Map properties
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0251, longitude: 28.9934), // İstanbul merkez
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @Published var mapAnnotations: [RouteMapAnnotation] = []
    @Published var directionPolylines: [MKPolyline] = [] // Directions API'den gelen polyline
    @Published var sessionPolylines: [MKPolyline] = []   // ScreenSession'dan gelen polyline
    @Published var areaCircles: [MKCircle] = []          // Area route için çemberler
    
    private let service = ActiveRoutesService.shared
    
    init() {
        loadActiveSchedules()
    }
    
    func loadActiveSchedules() {
        print("🔵 ===== LOAD ACTIVE SCHEDULES ÇAĞRILDI =====")
        let userId = SessionManager.shared.currentUser?.id ?? "1"
        print("🔵 User ID: \(userId)")
        service.getActiveRoutes(date: selectedDate, userId: userId, status: nil, employeeId: nil) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("🔵 ===== API SUCCESS =====")
                    print("🔵 API'den gelen schedule sayısı: \(response.data.schedules.count)")
                    
                    // API'den gelen data'da routeType yoksa mock data kullan
                    let hasValidRouteData = response.data.schedules.contains { schedule in
                        schedule.routeType != nil && schedule.routeType != ""
                    }
                    
                    if hasValidRouteData {
                        print("🔵 API'den gelen data geçerli, kullanılıyor")
                        self?.schedules = response.data.schedules
                    } else {
                        print("🔵 API'den gelen data geçersiz, mock data kullanılıyor")
                        self?.addMockData()
                        return
                    }
                    
                    self?.prepareMapData()
                case .failure(let error):
                    print("🔵 ===== API FAILURE =====")
                    print("🔵 Hata: \(error)")
                    self?.error = error
                    // Test için mock data ekle
                    print("🔵 Mock data ekleniyor...")
                    self?.addMockData()
                }
            }
        }
    }
    
    // Test için mock data
    private func addMockData() {
        print("🔵 ===== MOCK DATA FONKSIYONU ÇAĞRILDI =====")
        print("🔵 Mock data yükleniyor...")
        let mockSchedules: [ActiveSchedule] = [
            // Fixed Route örneği - İstanbul'da iki farklı nokta arası
            ActiveSchedule(
                id: 1,
                routeId: 101,
                assignedPlanId: 201,
                assignedScreenId: 301,
                assignedEmployeeId: 401,
                scheduleDate: "2024-01-15",
                startTime: "09:00:00",
                endTime: "17:00:00",
                displayDurationMinutes: 480,
                pricePerHour: 50.0,
                budget: 400.0,
                routeType: "fixed_route",
                startLat: 41.0082, // Sultanahmet
                startLng: 28.9784,
                endLat: 41.0369, // Taksim
                endLng: 28.9850,
                centerLat: nil,
                centerLng: nil,
                radiusMeters: nil,
                status: "active",
                createdBy: "mock",
                createdAt: "2024-01-15T08:00:00Z",
                screenSessions: []
            ),
            // Area Route örneği - Beşiktaş merkez
            ActiveSchedule(
                id: 2,
                routeId: 102,
                assignedPlanId: 202,
                assignedScreenId: 302,
                assignedEmployeeId: 402,
                scheduleDate: "2024-01-16",
                startTime: "10:00:00",
                endTime: "18:00:00",
                displayDurationMinutes: 480,
                pricePerHour: 60.0,
                budget: 480.0,
                routeType: "area_route",
                startLat: nil,
                startLng: nil,
                endLat: nil,
                endLng: nil,
                centerLat: 41.0438, // Beşiktaş
                centerLng: 29.0083,
                radiusMeters: 1500,
                status: "active",
                createdBy: "mock",
                createdAt: "2024-01-16T08:00:00Z",
                screenSessions: [
                    ScreenSession(
                        id: 4,
                        assignedScheduleId: 2,
                        sessionDate: "2024-01-16",
                        actualStartTime: "2024-01-16 09:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 41.0422,
                        currentLng: 29.0083,
                        batteryLevel: 92,
                        signalStrength: 95,
                        status: "active",
                        lastUpdate: "2024-01-16 10:30:00"
                    ),
                    ScreenSession(
                        id: 5,
                        assignedScheduleId: 2,
                        sessionDate: "2024-01-16",
                        actualStartTime: "2024-01-16 11:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 41.0400,
                        currentLng: 29.0100,
                        batteryLevel: 90,
                        signalStrength: 90,
                        status: "active",
                        lastUpdate: "2024-01-16 11:00:00"
                    ),
                    ScreenSession(
                        id: 6,
                        assignedScheduleId: 2,
                        sessionDate: "2024-01-16",
                        actualStartTime: "2024-01-16 12:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 41.0390,
                        currentLng: 29.0060,
                        batteryLevel: 88,
                        signalStrength: 85,
                        status: "active",
                        lastUpdate: "2024-01-16 12:30:00"
                    )
                ]
            ),
            // 3. Schedule - Fixed Route örneği - Kadıköy'den Üsküdar'a
            ActiveSchedule(
                id: 3,
                routeId: 103,
                assignedPlanId: 203,
                assignedScreenId: 303,
                assignedEmployeeId: 403,
                scheduleDate: "2024-01-17",
                startTime: "08:00:00",
                endTime: "16:00:00",
                displayDurationMinutes: 480,
                pricePerHour: 55.0,
                budget: 440.0,
                routeType: "fixed_route",
                startLat: 40.9909, // Kadıköy
                startLng: 29.0303,
                endLat: 41.0235, // Üsküdar
                endLng: 29.0122,
                centerLat: nil,
                centerLng: nil,
                radiusMeters: nil,
                status: "active",
                createdBy: "mock",
                createdAt: "2024-01-17T08:00:00Z",
                screenSessions: [
                    ScreenSession(
                        id: 7,
                        assignedScheduleId: 3,
                        sessionDate: "2024-01-17",
                        actualStartTime: "2024-01-17 08:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 40.9909,
                        currentLng: 29.0303,
                        batteryLevel: 95,
                        signalStrength: 98,
                        status: "active",
                        lastUpdate: "2024-01-17 08:00:00"
                    ),
                    ScreenSession(
                        id: 8,
                        assignedScheduleId: 3,
                        sessionDate: "2024-01-17",
                        actualStartTime: "2024-01-17 10:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 41.0072,
                        currentLng: 29.0212,
                        batteryLevel: 92,
                        signalStrength: 95,
                        status: "active",
                        lastUpdate: "2024-01-17 10:00:00"
                    ),
                    ScreenSession(
                        id: 9,
                        assignedScheduleId: 3,
                        sessionDate: "2024-01-17",
                        actualStartTime: "2024-01-17 12:00:00",
                        actualEndTime: nil,
                        actualDurationMin: nil,
                        currentLat: 41.0235,
                        currentLng: 29.0122,
                        batteryLevel: 88,
                        signalStrength: 90,
                        status: "active",
                        lastUpdate: "2024-01-17 12:00:00"
                    )
                ]
            )
        ]
        
        print("🔵 Mock data oluşturuldu: \(mockSchedules.count) schedule")
        for (index, schedule) in mockSchedules.enumerated() {
            print("🔵 Schedule \(index + 1): ID=\(schedule.id), Type=\(schedule.routeType ?? "nil"), ScreenSessions=\(schedule.screenSessions?.count ?? 0)")
        }
        
        // Debug: Mock data'dan sonra routeType değerlerini kontrol et
        print("🔵 DEBUG: Mock data routeType değerleri:")
        for (index, schedule) in mockSchedules.enumerated() {
            print("🔵 Schedule \(index + 1): routeType = '\(schedule.routeType ?? "nil")'")
        }
        
        self.schedules = mockSchedules
        
        // Debug: self.schedules'a atandıktan sonra routeType değerlerini kontrol et
        print("🔵 DEBUG: self.schedules routeType değerleri:")
        for (index, schedule) in self.schedules.enumerated() {
            print("🔵 Schedule \(index + 1): routeType = '\(schedule.routeType ?? "nil")'")
        }
        
        print("🔵 Mock data yüklendi: \(mockSchedules.count) schedule")
        self.prepareMapData()
    }
    
    func prepareMapData() {
        print("🔵 prepareMapData başladı - \(schedules.count) schedule")
        
        // Filtrelenmiş schedule'ları al
        let filteredSchedules: [ActiveSchedule]
        if !selectedScheduleIds.isEmpty {
            filteredSchedules = schedules.filter { selectedScheduleIds.contains($0.id) }
            print("🔵 Seçili schedule ID'ler: \(selectedScheduleIds), filtrelenmiş: \(filteredSchedules.count) schedule")
        } else {
            filteredSchedules = schedules
        }
        
        // Debug: API'den gelen data'nın routeType değerlerini kontrol et
        print("🔵 ===== API'DEN GELEN DATA DEBUG =====")
        for (index, schedule) in filteredSchedules.enumerated() {
            print("🔵 API Schedule \(index + 1): ID=\(schedule.id), routeType='\(schedule.routeType ?? "nil")'")
            print("🔵   - startLat: \(schedule.startLat ?? 0), startLng: \(schedule.startLng ?? 0)")
            print("🔵   - endLat: \(schedule.endLat ?? 0), endLng: \(schedule.endLng ?? 0)")
            print("🔵   - centerLat: \(schedule.centerLat ?? 0), centerLng: \(schedule.centerLng ?? 0)")
            print("🔵   - radiusMeters: \(schedule.radiusMeters ?? 0)")
        }
        print("🔵 ===== API DEBUG SONU =====")
        // Clear existing data
        self.directionPolylines = []
        self.sessionPolylines = []
        self.areaCircles = []
        
        // Annotations
        var annotations: [RouteMapAnnotation] = []
        var sessionPolylines: [MKPolyline] = []
        var directionPolylines: [MKPolyline] = []
        var areaCircles: [MKCircle] = []
        
        for schedule in filteredSchedules {
            print("🔵 Schedule işleniyor: ID=\(schedule.id), Type=\(schedule.routeType ?? "nil")")
            // Route type'a göre farklı gösterim
            if let routeType = schedule.routeType, routeType == "fixed_route" {
                print("🔵 Fixed route işleniyor...")
                // Fixed Route: Başlangıç ve bitiş noktası arasında Directions API ile yürüyüş rotası
                if let startLat = schedule.startLat, let startLng = schedule.startLng,
                   let endLat = schedule.endLat, let endLng = schedule.endLng {
                    
                    print("🔵 Fixed route koordinatları: Start(\(startLat), \(startLng)) -> End(\(endLat), \(endLng))")
                    
                    // Başlangıç ve bitiş annotation'ları
                    let startAnnotation = RouteMapAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: startLat, longitude: startLng),
                        type: .start,
                        color: .blue,
                        schedule: schedule,
                        isLarge: true
                    )
                    annotations.append(startAnnotation)
                    
                    let endAnnotation = RouteMapAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: endLat, longitude: endLng),
                        type: .end,
                        color: .blue, // Kırmızı yerine mavi
                        schedule: schedule,
                        isLarge: true
                    )
                    annotations.append(endAnnotation)
                    
                    // Directions API ile yürüyüş rotası al
                    getWalkingRoute(from: CLLocationCoordinate2D(latitude: startLat, longitude: startLng),
                                   to: CLLocationCoordinate2D(latitude: endLat, longitude: endLng)) { [weak self] polyline in
                        if let polyline = polyline {
                            self?.directionPolylines.append(polyline.polyline)
                            self?.objectWillChange.send()
                            print("🔵 Directions polyline eklendi")
                        }
                    }
                }
            } else if let routeType = schedule.routeType, routeType == "area_route" {
                print("🔵 Area route işleniyor...")
                // Area Route: Merkez nokta etrafında çember
                if let centerLat = schedule.centerLat, let centerLng = schedule.centerLng {
                    print("🔵 Area route merkez: (\(centerLat), \(centerLng))")
                    
                    // Merkez annotation
                    let centerAnnotation = RouteMapAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                        type: .waypoint,
                        color: .blue,
                        schedule: schedule,
                        isLarge: true
                    )
                    annotations.append(centerAnnotation)
                    
                    // Çember oluştur (radius_meters cinsinden)
                    let radius = schedule.radiusMeters ?? 1000 // Varsayılan 1000 metre
                    let circle = MKCircle(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng), radius: CLLocationDistance(radius))
                    areaCircles.append(circle)
                    print("🔵 Area circle oluşturuldu: Radius=\(radius)m")
                }
            }
            
            // Screen session'ları için polyline oluştur
            if let screenSessions = schedule.screenSessions, screenSessions.count > 1 {
                print("🔵 Screen sessions işleniyor: \(screenSessions.count) session")
                var coordinates: [CLLocationCoordinate2D] = []
                
                for session in screenSessions {
                    if let lat = session.currentLat, let lng = session.currentLng {
                        coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    }
                }
                
                if coordinates.count > 1 {
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    sessionPolylines.append(polyline)
                    print("🔵 Screen session polyline oluşturuldu: \(coordinates.count) nokta")
                }
            }
        }
        
        // UI'ı güncelle
        DispatchQueue.main.async { [weak self] in
            self?.mapAnnotations = annotations
            self?.sessionPolylines = sessionPolylines
            self?.areaCircles = areaCircles
            print("🔵 Map data güncellendi: \(annotations.count) annotation, \(sessionPolylines.count) session polyline, \(areaCircles.count) area circle")
            
            // Seçilen schedule'lara focus yap, yoksa tüm rotaları göster
            if let selectedIds = self?.selectedScheduleIds, !selectedIds.isEmpty {
                // Seçilen schedule'ları al
                let selectedSchedules = filteredSchedules.filter { schedule in
                    selectedIds.contains(schedule.id)
                }
                
                if selectedSchedules.count == 1 {
                    // Tek rota seçilmişse ona focus yap
                    self?.focusOnSchedule(selectedSchedules[0])
                } else if selectedSchedules.count > 1 {
                    // Birden fazla rota seçilmişse hepsini kapsayacak şekilde focus yap
                    self?.focusOnSelectedSchedules(selectedSchedules)
                } else {
                    // Hiç rota seçilmemişse tüm rotaları göster
                    self?.showAllRoutes(filteredSchedules)
                }
            } else {
                // Hiç rota seçilmemişse tüm rotaları göster
                self?.showAllRoutes(filteredSchedules)
            }
        }
    }
    
    private func getWalkingRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, completion: @escaping (MKRoute?) -> Void) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first {
                completion(route)
            } else {
                completion(nil)
            }
        }
    }
    
    private func colorForSchedule(_ id: Int) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .yellow, .teal, .indigo, .mint]
        return colors[id % colors.count]
    }
    
    // MARK: - Map Focus Functions
    private func focusOnSchedule(_ schedule: ActiveSchedule) {
        print("🔵 Schedule'a focus yapılıyor: ID=\(schedule.id)")
        
        if let routeType = schedule.routeType, routeType == "fixed_route" {
            // Fixed route için başlangıç ve bitiş noktaları arasına zoom
            if let startLat = schedule.startLat, let startLng = schedule.startLng,
               let endLat = schedule.endLat, let endLng = schedule.endLng {
                
                let startCoord = CLLocationCoordinate2D(latitude: startLat, longitude: startLng)
                let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLng)
                
                // İki nokta arasındaki merkezi hesapla
                let centerLat = (startLat + endLat) / 2
                let centerLng = (startLng + endLng) / 2
                let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
                
                // İki nokta arasındaki mesafeyi hesapla ve span ayarla
                let latDelta = abs(endLat - startLat) * 1.5 // 1.5 ile biraz daha genişlet
                let lngDelta = abs(endLng - startLng) * 1.5
                
                // Minimum span değerleri
                let minSpan = 0.01
                let finalLatDelta = max(latDelta, minSpan)
                let finalLngDelta = max(lngDelta, minSpan)
                
                self.region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLngDelta)
                )
                print("🔵 Fixed route focus: Merkez(\(centerLat), \(centerLng)), Span(\(finalLatDelta), \(finalLngDelta))")
            }
        } else if let routeType = schedule.routeType, routeType == "area_route" {
            // Area route için merkez nokta etrafına zoom
            if let centerLat = schedule.centerLat, let centerLng = schedule.centerLng, let radius = schedule.radiusMeters {
                let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
                // Radius'u kapsayacak şekilde span hesapla (1 derece ~ 111km)
                let latDelta = Double(radius) / 111_000.0 * 2.2 // 2.2 ile biraz daha genişlet
                let lngDelta = Double(radius) / (111_000.0 * cos(centerLat * .pi / 180)) * 2.2
                
                self.region = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
                )
                print("🔵 Area route focus: Merkez(\(centerLat), \(centerLng)), Radius=\(radius)m, Span(\(latDelta), \(lngDelta))")
            }
        }
    }
    
    private func focusOnSelectedSchedules(_ schedules: [ActiveSchedule]) {
        print("🔵 Seçilen schedule'lara focus yapılıyor: \(schedules.count) schedule")
        
        if schedules.isEmpty {
            // Hiç schedule yoksa varsayılan bölge
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0251, longitude: 28.9934), // İstanbul merkez
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }
        
        // Seçilen schedule'ların koordinatlarını topla
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        for schedule in schedules {
            // Fixed route koordinatları
            if let startLat = schedule.startLat, let startLng = schedule.startLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: startLat, longitude: startLng))
            }
            if let endLat = schedule.endLat, let endLng = schedule.endLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: endLat, longitude: endLng))
            }
            
            // Area route merkez koordinatları
            if let centerLat = schedule.centerLat, let centerLng = schedule.centerLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng))
            }
            
            // Screen session koordinatları
            if let screenSessions = schedule.screenSessions {
                for session in screenSessions {
                    if let lat = session.currentLat, let lng = session.currentLng {
                        allCoordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    }
                }
            }
        }
        
        if allCoordinates.isEmpty {
            // Hiç koordinat yoksa varsayılan bölge
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0251, longitude: 28.9934),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }
        
        // Seçilen koordinatları kapsayacak bölgeyi hesapla
        let lats = allCoordinates.map { $0.latitude }
        let lngs = allCoordinates.map { $0.longitude }
        
        let minLat = lats.min() ?? 41.0
        let maxLat = lats.max() ?? 41.1
        let minLng = lngs.min() ?? 28.9
        let maxLng = lngs.max() ?? 29.1
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        let latDelta = (maxLat - minLat) * 1.3 // 1.3 ile biraz daha genişlet
        let lngDelta = (maxLng - minLng) * 1.3
        
        // Minimum span değerleri
        let minSpan = 0.015
        let finalLatDelta = max(latDelta, minSpan)
        let finalLngDelta = max(lngDelta, minSpan)
        
        self.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLngDelta)
        )
        
        print("🔵 Seçilen rotalar focus: Merkez(\(centerLat), \(centerLng)), Span(\(finalLatDelta), \(finalLngDelta))")
        print("🔵 Seçilen koordinat aralığı: Lat(\(minLat)-\(maxLat)), Lng(\(minLng)-\(maxLng))")
    }
    
    private func showAllRoutes(_ schedules: [ActiveSchedule]) {
        print("🔵 Tüm rotalar gösteriliyor: \(schedules.count) schedule")
        
        if schedules.isEmpty {
            // Hiç schedule yoksa varsayılan bölge
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0251, longitude: 28.9934), // İstanbul merkez
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }
        
        // Tüm schedule'ların koordinatlarını topla
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        for schedule in schedules {
            // Fixed route koordinatları
            if let startLat = schedule.startLat, let startLng = schedule.startLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: startLat, longitude: startLng))
            }
            if let endLat = schedule.endLat, let endLng = schedule.endLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: endLat, longitude: endLng))
            }
            
            // Area route merkez koordinatları
            if let centerLat = schedule.centerLat, let centerLng = schedule.centerLng {
                allCoordinates.append(CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng))
            }
            
            // Screen session koordinatları
            if let screenSessions = schedule.screenSessions {
                for session in screenSessions {
                    if let lat = session.currentLat, let lng = session.currentLng {
                        allCoordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
                    }
                }
            }
        }
        
        if allCoordinates.isEmpty {
            // Hiç koordinat yoksa varsayılan bölge
            self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 41.0251, longitude: 28.9934),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }
        
        // Tüm koordinatları kapsayacak bölgeyi hesapla
        let lats = allCoordinates.map { $0.latitude }
        let lngs = allCoordinates.map { $0.longitude }
        
        let minLat = lats.min() ?? 41.0
        let maxLat = lats.max() ?? 41.1
        let minLng = lngs.min() ?? 28.9
        let maxLng = lngs.max() ?? 29.1
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        let latDelta = (maxLat - minLat) * 1.2 // 1.2 ile biraz daha genişlet
        let lngDelta = (maxLng - minLng) * 1.2
        
        // Minimum span değerleri
        let minSpan = 0.02
        let finalLatDelta = max(latDelta, minSpan)
        let finalLngDelta = max(lngDelta, minSpan)
        
        self.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLngDelta)
        )
        
        print("🔵 Tüm rotalar focus: Merkez(\(centerLat), \(centerLng)), Span(\(finalLatDelta), \(finalLngDelta))")
        print("🔵 Koordinat aralığı: Lat(\(minLat)-\(maxLat)), Lng(\(minLng)-\(maxLng))")
    }
}

// MARK: - Map Annotation Model
struct RouteMapAnnotation: Identifiable, Equatable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    let color: Color
    let schedule: ActiveSchedule
    let isLarge: Bool // true: büyük ikon (schedule), false: küçük ikon (screen session)
    
    enum AnnotationType: Equatable { 
        case start, end, waypoint 
    }
    
    static func == (lhs: RouteMapAnnotation, rhs: RouteMapAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

struct RoutePolyline: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
    let lineWidth: CGFloat
    let routeType: RouteType
    
    enum RouteType {
        case schedule      // Başlangıç-bitiş rotası
        case screenSession // Gezinti verisi rotası
    }
} 


