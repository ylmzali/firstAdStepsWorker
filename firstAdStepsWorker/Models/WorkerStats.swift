import Foundation

// MARK: - Worker Stats Response
struct WorkerStatsResponse: Codable {
    let status: String
    let message: String
    let data: WorkerStatsData
}

// MARK: - Worker Stats Data
struct WorkerStatsData: Codable {
    let employeeId: String
    let periodInfo: PeriodInfo
    let performanceMetrics: PerformanceMetrics
    let financialMetrics: FinancialMetrics
    let deviceMetrics: DeviceMetrics
    let scheduleDetails: [ScheduleDetail]
    
    enum CodingKeys: String, CodingKey {
        case employeeId = "employee_id"
        case periodInfo = "period_info"
        case performanceMetrics = "performance_metrics"
        case financialMetrics = "financial_metrics"
        case deviceMetrics = "device_metrics"
        case scheduleDetails = "schedule_details"
    }
}

// MARK: - Period Info
struct PeriodInfo: Codable {
    let totalAssignedSchedules: Int
    let completedSchedules: Int
    let activeSchedules: Int
    let pendingSchedules: Int
    
    enum CodingKeys: String, CodingKey {
        case totalAssignedSchedules = "total_assigned_schedules"
        case completedSchedules = "completed_schedules"
        case activeSchedules = "active_schedules"
        case pendingSchedules = "pending_schedules"
    }
}

// MARK: - Performance Metrics
struct PerformanceMetrics: Codable {
    let totalWorkHours: Double
    let totalDistanceKm: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let totalSessions: Int
    let activeSessions: Int
    
    enum CodingKeys: String, CodingKey {
        case totalWorkHours = "total_work_hours"
        case totalDistanceKm = "total_distance_km"
        case averageSpeed = "average_speed"
        case maxSpeed = "max_speed"
        case totalSessions = "total_sessions"
        case activeSessions = "active_sessions"
    }
}

// MARK: - Financial Metrics
struct FinancialMetrics: Codable {
    let totalEarned: Double
    let averagePerHour: Double
    let completedJobsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case totalEarned = "total_earned"
        case averagePerHour = "average_per_hour"
        case completedJobsCount = "completed_jobs_count"
    }
}

// MARK: - Device Metrics
struct DeviceMetrics: Codable {
    let averageBattery: Double
    let averageSignal: Double
    let lowBatterySessions: Int
    
    enum CodingKeys: String, CodingKey {
        case averageBattery = "average_battery"
        case averageSignal = "average_signal"
        case lowBatterySessions = "low_battery_sessions"
    }
}

// MARK: - Schedule Detail
struct ScheduleDetail: Codable {
    let id: String
    let title: String
    let date: String
    let startTime: String
    let endTime: String
    let status: String
    let budget: Double
    let routeType: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case budget
        case routeType = "route_type"
    }
}
