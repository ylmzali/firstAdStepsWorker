import Foundation

struct ActiveTrackingInfo: Codable {
    let routeId: String
    let assignmentId: String
    let employeeId: String
    let startTime: Date
    let endTime: Date
    let status: String // "working", "paused", "completed"
    let lastLocationUpdate: Date?
    
    init(routeId: String, assignmentId: String, employeeId: String, startTime: Date, endTime: Date, status: String, lastLocationUpdate: Date? = nil) {
        self.routeId = routeId
        self.assignmentId = assignmentId
        self.employeeId = employeeId
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.lastLocationUpdate = lastLocationUpdate
    }
    
    // Zaman aralığı kontrolü
    var isTimeActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    // Süre dolmuş mu?
    var isExpired: Bool {
        let now = Date()
        return now > endTime
    }
    
    // Kalan süre (dakika)
    var remainingMinutes: Int {
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        let minutes = max(0, Int(remaining / 60))
        
        // Debug için log ekle
        print("⏰ [ActiveTrackingInfo] Kalan süre hesaplaması:")
        print("⏰ [ActiveTrackingInfo] Şu anki zaman: \(now)")
        print("⏰ [ActiveTrackingInfo] Bitiş zamanı: \(endTime)")
        print("⏰ [ActiveTrackingInfo] Kalan saniye: \(remaining)")
        print("⏰ [ActiveTrackingInfo] Kalan dakika: \(minutes)")
        
        return minutes
    }
} 