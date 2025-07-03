import Foundation
import CoreLocation
import SwiftUI

// MARK: - GPS Tracking Models

/// GPS konum verisi
struct GPSLocation: Codable, Identifiable {
    let id: String
    let routeId: String
    let employeeId: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double // metre cinsinden
    let speed: Double? // km/h cinsinden
    let heading: Double? // derece cinsinden (0-360)
    let altitude: Double? // metre cinsinden
    let timestamp: String
    let batteryLevel: Double? // 0-1 arası
    let signalStrength: Int? // 0-5 arası
    let isMoving: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case routeId
        case employeeId
        case latitude
        case longitude
        case accuracy
        case speed
        case heading
        case altitude
        case timestamp
        case batteryLevel
        case signalStrength
        case isMoving
    }
    
    // CLLocation'dan GPSLocation oluşturma
    init(from location: CLLocation, routeId: String, employeeId: String, batteryLevel: Double? = nil, signalStrength: Int? = nil) {
        self.id = UUID().uuidString
        self.routeId = routeId
        self.employeeId = employeeId
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.accuracy = location.horizontalAccuracy
        self.speed = location.speed >= 0 ? location.speed * 3.6 : nil // m/s'den km/h'ye çevir
        self.heading = location.course >= 0 ? location.course : nil
        self.altitude = location.altitude
        self.timestamp = ISO8601DateFormatter().string(from: location.timestamp)
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.isMoving = location.speed > 0.5 // 0.5 m/s'den fazla hareket varsa
    }
    
    // Normal initializer
    init(id: String, routeId: String, employeeId: String, latitude: Double, longitude: Double, accuracy: Double, speed: Double?, heading: Double?, altitude: Double?, timestamp: String, batteryLevel: Double?, signalStrength: Int?, isMoving: Bool) {
        self.id = id
        self.routeId = routeId
        self.employeeId = employeeId
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.speed = speed
        self.heading = heading
        self.altitude = altitude
        self.timestamp = timestamp
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.isMoving = isMoving
    }
    
    // MARK: - Computed Properties
    
    /// CLLocationCoordinate2D'ye çevirme
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Tarih objesi
    var date: Date? {
        return ISO8601DateFormatter().date(from: timestamp)
    }
    
    /// Formatlanmış zaman
    var formattedTime: String {
        guard let date = date else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// Formatlanmış tarih ve saat
    var formattedDateTime: String {
        guard let date = date else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// Göreceli zaman (örn: 2 dakika önce)
    var relativeTime: String {
        guard let date = date else { return "Bilinmiyor" }
        return date.toRelativeTime
    }
    
    /// Hız formatlanmış (km/h)
    var formattedSpeed: String {
        guard let speed = speed else { return "Bilinmiyor" }
        return String(format: "%.1f km/h", speed)
    }
    
    /// Yön formatlanmış (derece)
    var formattedHeading: String {
        guard let heading = heading else { return "Bilinmiyor" }
        return String(format: "%.0f°", heading)
    }
    
    /// Batarya seviyesi formatlanmış (%)
    var formattedBatteryLevel: String {
        guard let batteryLevel = batteryLevel else { return "Bilinmiyor" }
        return String(format: "%.0f%%", batteryLevel * 100)
    }
    
    /// Sinyal gücü formatlanmış
    var formattedSignalStrength: String {
        guard let signalStrength = signalStrength else { return "Bilinmiyor" }
        return "\(signalStrength)/5"
    }
    
    /// Hareket durumu
    var movementStatus: String {
        return isMoving ? "Hareket halinde" : "Durdu"
    }
    
    /// Hareket durumu rengi
    var movementStatusColor: Color {
        return isMoving ? .green : .orange
    }
}

/// Ekran ziyaret kaydı
struct ScreenVisit: Codable, Identifiable {
    let id: String
    let routeId: String
    let employeeId: String
    let screenId: String
    let screenName: String
    let screenLocation: String
    let arrivalTime: String
    let departureTime: String?
    let duration: Int? // dakika cinsinden
    let status: ScreenVisitStatus
    let photos: [String] // fotoğraf URL'leri
    let notes: String?
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case routeId
        case employeeId
        case screenId
        case screenName
        case screenLocation
        case arrivalTime
        case departureTime
        case duration
        case status
        case photos
        case notes
        case latitude
        case longitude
    }
    
    // Normal initializer
    init(id: String, routeId: String, employeeId: String, screenId: String, screenName: String, screenLocation: String, arrivalTime: String, departureTime: String?, duration: Int?, status: ScreenVisitStatus, photos: [String], notes: String?, latitude: Double, longitude: Double) {
        self.id = id
        self.routeId = routeId
        self.employeeId = employeeId
        self.screenId = screenId
        self.screenName = screenName
        self.screenLocation = screenLocation
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
        self.duration = duration
        self.status = status
        self.photos = photos
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: - Computed Properties
    
    /// Varış zamanı
    var arrivalDate: Date? {
        return ISO8601DateFormatter().date(from: arrivalTime)
    }
    
    /// Ayrılış zamanı
    var departureDate: Date? {
        guard let departureTime = departureTime else { return nil }
        return ISO8601DateFormatter().date(from: departureTime)
    }
    
    /// Formatlanmış varış zamanı
    var formattedArrivalTime: String {
        guard let date = arrivalDate else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Formatlanmış ayrılış zamanı
    var formattedDepartureTime: String {
        guard let date = departureDate else { return "Devam ediyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// Formatlanmış süre
    var formattedDuration: String {
        guard let duration = duration else { return "Devam ediyor" }
        if duration < 60 {
            return "\(duration) dakika"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            return "\(hours) saat \(minutes) dakika"
        }
    }
    
    /// Koordinat
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Ziyaret tamamlandı mı?
    var isCompleted: Bool {
        return status == .completed
    }
    
    /// Ziyaret devam ediyor mu?
    var isInProgress: Bool {
        return status == .in_progress
    }
    
    /// Ziyaret iptal edildi mi?
    var isCancelled: Bool {
        return status == .cancelled
    }
}

/// Ekran ziyaret durumu
enum ScreenVisitStatus: String, Codable {
    case in_progress = "in_progress"     // Ziyaret başladı, devam ediyor
    case completed = "completed"         // Ziyaret tamamlandı
    case cancelled = "cancelled"         // Ziyaret iptal edildi
    case delayed = "delayed"             // Ziyaret gecikti
    
    var statusColor: Color {
        switch self {
        case .in_progress: return .blue
        case .completed: return .green
        case .cancelled: return .red
        case .delayed: return .orange
        }
    }
    
    var statusDescription: String {
        switch self {
        case .in_progress: return "Devam ediyor"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal edildi"
        case .delayed: return "Gecikti"
        }
    }
}

/// Canlı takip durumu
enum LiveTrackingStatus: String, Codable {
    case not_started = "not_started"     // Henüz başlamadı
    case active = "active"               // Aktif takip
    case paused = "paused"               // Duraklatıldı
    case completed = "completed"         // Tamamlandı
    case stopped = "stopped"             // Durduruldu
    
    var statusColor: Color {
        switch self {
        case .not_started: return .gray
        case .active: return .green
        case .paused: return .orange
        case .completed: return .blue
        case .stopped: return .red
        }
    }
    
    var statusDescription: String {
        switch self {
        case .not_started: return "Başlamadı"
        case .active: return "Aktif"
        case .paused: return "Duraklatıldı"
        case .completed: return "Tamamlandı"
        case .stopped: return "Durduruldu"
        }
    }
}

/// Canlı takip oturumu
struct LiveTrackingSession: Codable, Identifiable {
    let id: String
    let routeId: String
    let employeeId: String
    let startTime: String
    let endTime: String?
    let status: LiveTrackingStatus
    let totalDistance: Double? // km cinsinden
    let totalDuration: Int? // dakika cinsinden
    let averageSpeed: Double? // km/h cinsinden
    let maxSpeed: Double? // km/h cinsinden
    let stopsCount: Int // durma sayısı
    let screenVisits: [ScreenVisit] // ekran ziyaretleri
    let gpsLocations: [GPSLocation] // GPS konumları
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case routeId
        case employeeId
        case startTime
        case endTime
        case status
        case totalDistance
        case totalDuration
        case averageSpeed
        case maxSpeed
        case stopsCount
        case screenVisits
        case gpsLocations
        case notes
    }
    
    // Normal initializer
    init(id: String, routeId: String, employeeId: String, startTime: String, endTime: String?, status: LiveTrackingStatus, totalDistance: Double?, totalDuration: Int?, averageSpeed: Double?, maxSpeed: Double?, stopsCount: Int, screenVisits: [ScreenVisit], gpsLocations: [GPSLocation], notes: String?) {
        self.id = id
        self.routeId = routeId
        self.employeeId = employeeId
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.totalDistance = totalDistance
        self.totalDuration = totalDuration
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.stopsCount = stopsCount
        self.screenVisits = screenVisits
        self.gpsLocations = gpsLocations
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    
    /// Başlangıç zamanı
    var startDate: Date? {
        return ISO8601DateFormatter().date(from: startTime)
    }
    
    /// Bitiş zamanı
    var endDate: Date? {
        guard let endTime = endTime else { return nil }
        return ISO8601DateFormatter().date(from: endTime)
    }
    
    /// Formatlanmış başlangıç zamanı
    var formattedStartTime: String {
        guard let date = startDate else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    /// Formatlanmış bitiş zamanı
    var formattedEndTime: String {
        guard let date = endDate else { return "Devam ediyor" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    /// Formatlanmış toplam mesafe
    var formattedTotalDistance: String {
        guard let distance = totalDistance else { return "Hesaplanıyor..." }
        return String(format: "%.1f km", distance)
    }
    
    /// Formatlanmış toplam süre
    var formattedTotalDuration: String {
        guard let duration = totalDuration else { return "Hesaplanıyor..." }
        if duration < 60 {
            return "\(duration) dakika"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            return "\(hours) saat \(minutes) dakika"
        }
    }
    
    /// Formatlanmış ortalama hız
    var formattedAverageSpeed: String {
        guard let speed = averageSpeed else { return "Hesaplanıyor..." }
        return String(format: "%.1f km/h", speed)
    }
    
    /// Formatlanmış maksimum hız
    var formattedMaxSpeed: String {
        guard let speed = maxSpeed else { return "Hesaplanıyor..." }
        return String(format: "%.1f km/h", speed)
    }
    
    /// Tamamlanan ekran ziyaretleri
    var completedScreenVisits: [ScreenVisit] {
        return screenVisits.filter { $0.isCompleted }
    }
    
    /// Devam eden ekran ziyaretleri
    var inProgressScreenVisits: [ScreenVisit] {
        return screenVisits.filter { $0.isInProgress }
    }
    
    /// Tamamlanma yüzdesi
    var completionPercentage: Int {
        let totalScreens = screenVisits.count
        guard totalScreens > 0 else { return 0 }
        let completedScreens = completedScreenVisits.count
        return Int((Double(completedScreens) / Double(totalScreens)) * 100)
    }
    
    /// Oturum devam ediyor mu?
    var isActive: Bool {
        return status == .active
    }
    
    /// Oturum tamamlandı mı?
    var isCompleted: Bool {
        return status == .completed
    }
    
    /// Oturum duraklatıldı mı?
    var isPaused: Bool {
        return status == .paused
    }
}

// MARK: - Preview Data

extension GPSLocation {
    static let preview = GPSLocation(
        id: "1",
        routeId: "route1",
        employeeId: "emp1",
        latitude: 40.9909,
        longitude: 29.0304,
        accuracy: 5.0,
        speed: 25.5,
        heading: 180.0,
        altitude: 100.0,
        timestamp: "2024-03-20T12:00:00Z",
        batteryLevel: 0.85,
        signalStrength: 4,
        isMoving: true
    )
}

extension ScreenVisit {
    static let preview = ScreenVisit(
        id: "1",
        routeId: "route1",
        employeeId: "emp1",
        screenId: "screen1",
        screenName: "Kadıköy Merkez",
        screenLocation: "Kadıköy, İstanbul",
        arrivalTime: "2024-03-20T12:00:00Z",
        departureTime: "2024-03-20T14:00:00Z",
        duration: 120,
        status: .completed,
        photos: ["photo1.jpg", "photo2.jpg"],
        notes: "Reklam başarıyla gösterildi",
        latitude: 40.9909,
        longitude: 29.0304
    )
}

extension LiveTrackingSession {
    static let preview = LiveTrackingSession(
        id: "1",
        routeId: "route1",
        employeeId: "emp1",
        startTime: "2024-03-20T08:00:00Z",
        endTime: nil,
        status: .active,
        totalDistance: 15.5,
        totalDuration: 240,
        averageSpeed: 25.0,
        maxSpeed: 45.0,
        stopsCount: 3,
        screenVisits: [ScreenVisit.preview],
        gpsLocations: [GPSLocation.preview],
        notes: "Günlük rota takibi"
    )
} 