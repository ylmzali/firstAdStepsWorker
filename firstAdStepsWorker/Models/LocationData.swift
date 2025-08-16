import Foundation

struct LocationData: Codable {
    let routeId: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
    let speed: Double
    let heading: Double
    
    // Yeni alanlar
    let assignedPlanId: String?
    let assignedScreenId: String?
    let assignedEmployeeId: String?
    let assignedScheduleId: String?
    let sessionDate: String?
    let actualStartTime: Date?
    let actualEndTime: Date?
    let status: String?
    let batteryLevel: Double?
    let signalStrength: Int?
    let actualDurationMin: Int?
    
    // Mesafe alanları
    let distanceFromPrevious: Double? // Bir önceki konum ile arasındaki mesafe (metre)
    let totalDistance: Double? // Bu noktaya kadar ki toplam yürünen mesafe (metre)
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case latitude
        case longitude
        case accuracy
        case timestamp
        case speed
        case heading
        case assignedPlanId = "assigned_plan_id"
        case assignedScreenId = "assigned_screen_id"
        case assignedEmployeeId = "assigned_employee_id"
        case assignedScheduleId = "assigned_schedule_id"
        case sessionDate = "session_date"
        case actualStartTime = "actual_start_time"
        case actualEndTime = "actual_end_time"
        case status
        case batteryLevel = "battery_level"
        case signalStrength = "signal_strength"
        case actualDurationMin = "actual_duration_min"
        case distanceFromPrevious = "distance_from_previous"
        case totalDistance = "total_distance"
    }
}

// MARK: - Toplu Konum Gönderimi için Yeni Model
struct BulkLocationData: Codable {
    let routeId: String
    let assignedPlanId: String?
    let assignedScreenId: String?
    let assignedEmployeeId: String?
    let assignedScheduleId: String?
    let sessionDate: String
    let actualStartTime: Date
    let actualEndTime: Date
    let status: String
    let batteryLevel: Double?
    let signalStrength: Int?
    let actualDurationMin: Int?
    let locations: [LocationPoint]
    
    enum CodingKeys: String, CodingKey {
        case routeId = "route_id"
        case assignedPlanId = "assigned_plan_id"
        case assignedScreenId = "assigned_screen_id"
        case assignedEmployeeId = "assigned_employee_id"
        case assignedScheduleId = "assigned_schedule_id"
        case sessionDate = "session_date"
        case actualStartTime = "actual_start_time"
        case actualEndTime = "actual_end_time"
        case status
        case batteryLevel = "battery_level"
        case signalStrength = "signal_strength"
        case actualDurationMin = "actual_duration_min"
        case locations
    }
}

struct LocationPoint: Codable {
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let timestamp: Date
    let speed: Double
    let heading: Double
    let distanceFromPrevious: Double
    let totalDistance: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case accuracy
        case timestamp
        case speed
        case heading
        case distanceFromPrevious = "distance_from_previous"
        case totalDistance = "total_distance"
    }
} 