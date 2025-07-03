import Foundation
import CoreLocation

// MARK: - Active Routes Response Model
struct ActiveRoutesResponse: Codable {
    let success: Bool
    let message: String
    let data: ActiveRoutesData
}

struct ActiveRoutesData: Codable {
    let schedules: [ActiveSchedule]
}

struct ActiveSchedule: Codable, Identifiable {
    let id: Int
    let routeId: Int?
    let assignedPlanId: Int?
    let assignedScreenId: Int?
    let assignedEmployeeId: Int?
    let title: String?
    let scheduleDate: String?
    let startTime: String?
    let endTime: String?
    let displayDurationMinutes: Int?
    let pricePerHour: Double?
    let budget: Double?
    let routeType: String? // 'fixed_route' veya 'area_route'
    let startLat: Double?
    let startLng: Double?
    let endLat: Double?
    let endLng: Double?
    let centerLat: Double?
    let centerLng: Double?
    let radiusMeters: Int?
    let status: String?
    let createdBy: String?
    let createdAt: String?
    let screenSessions: [ScreenSession]?
    
    // Regular initializer for direct instantiation
    init(
        id: Int,
        routeId: Int? = nil,
        assignedPlanId: Int? = nil,
        assignedScreenId: Int? = nil,
        assignedEmployeeId: Int? = nil,
        title: String? = nil,
        scheduleDate: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        displayDurationMinutes: Int? = nil,
        pricePerHour: Double? = nil,
        budget: Double? = nil,
        routeType: String? = nil,
        startLat: Double? = nil,
        startLng: Double? = nil,
        endLat: Double? = nil,
        endLng: Double? = nil,
        centerLat: Double? = nil,
        centerLng: Double? = nil,
        radiusMeters: Int? = nil,
        status: String? = nil,
        createdBy: String? = nil,
        createdAt: String? = nil,
        screenSessions: [ScreenSession]? = nil
    ) {
        self.id = id
        self.routeId = routeId
        self.assignedPlanId = assignedPlanId
        self.assignedScreenId = assignedScreenId
        self.assignedEmployeeId = assignedEmployeeId
        self.title = title
        self.scheduleDate = scheduleDate
        self.startTime = startTime
        self.endTime = endTime
        self.displayDurationMinutes = displayDurationMinutes
        self.pricePerHour = pricePerHour
        self.budget = budget
        self.routeType = routeType
        self.startLat = startLat
        self.startLng = startLng
        self.endLat = endLat
        self.endLng = endLng
        self.centerLat = centerLat
        self.centerLng = centerLng
        self.radiusMeters = radiusMeters
        self.status = status
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.screenSessions = screenSessions
    }
    
    // Custom decoder for debugging route_type field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        routeId = try container.decodeIfPresent(Int.self, forKey: .routeId)
        assignedPlanId = try container.decodeIfPresent(Int.self, forKey: .assignedPlanId)
        assignedScreenId = try container.decodeIfPresent(Int.self, forKey: .assignedScreenId)
        assignedEmployeeId = try container.decodeIfPresent(Int.self, forKey: .assignedEmployeeId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        scheduleDate = try container.decodeIfPresent(String.self, forKey: .scheduleDate)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        displayDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .displayDurationMinutes)
        pricePerHour = try container.decodeIfPresent(Double.self, forKey: .pricePerHour)
        budget = try container.decodeIfPresent(Double.self, forKey: .budget)
        routeType = try container.decodeIfPresent(String.self, forKey: .routeType)
        startLat = try container.decodeIfPresent(Double.self, forKey: .startLat)
        startLng = try container.decodeIfPresent(Double.self, forKey: .startLng)
        endLat = try container.decodeIfPresent(Double.self, forKey: .endLat)
        endLng = try container.decodeIfPresent(Double.self, forKey: .endLng)
        centerLat = try container.decodeIfPresent(Double.self, forKey: .centerLat)
        centerLng = try container.decodeIfPresent(Double.self, forKey: .centerLng)
        radiusMeters = try container.decodeIfPresent(Int.self, forKey: .radiusMeters)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        screenSessions = try container.decodeIfPresent([ScreenSession].self, forKey: .screenSessions)
    }
}

struct ScreenSession: Codable, Identifiable {
    let id: Int
    let assignedScheduleId: Int
    let sessionDate: String
    let actualStartTime: String?
    let actualEndTime: String?
    let actualDurationMin: Int?
    let currentLat: Double?
    let currentLng: Double?
    let batteryLevel: Int?
    let signalStrength: Int?
    let status: String?
    let lastUpdate: String?

    // Regular initializer for direct instantiation
    init(
        id: Int,
        assignedScheduleId: Int,
        sessionDate: String,
        actualStartTime: String? = nil,
        actualEndTime: String? = nil,
        actualDurationMin: Int? = nil,
        currentLat: Double? = nil,
        currentLng: Double? = nil,
        batteryLevel: Int? = nil,
        signalStrength: Int? = nil,
        status: String? = nil,
        lastUpdate: String? = nil
    ) {
        self.id = id
        self.assignedScheduleId = assignedScheduleId
        self.sessionDate = sessionDate
        self.actualStartTime = actualStartTime
        self.actualEndTime = actualEndTime
        self.actualDurationMin = actualDurationMin
        self.currentLat = currentLat
        self.currentLng = currentLng
        self.batteryLevel = batteryLevel
        self.signalStrength = signalStrength
        self.status = status
        self.lastUpdate = lastUpdate
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: currentLat ?? 0.0, longitude: currentLng ?? 0.0)
    }
}

 