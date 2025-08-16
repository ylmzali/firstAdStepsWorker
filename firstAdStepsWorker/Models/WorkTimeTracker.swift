import Foundation

struct WorkTimeTracker: Codable {
    let assignmentId: String
    let scheduleId: String
    let employeeId: String
    let startTime: Date
    var pauseTime: Date?
    var resumeTime: Date?
    var endTime: Date?
    var totalWorkMinutes: Int
    var status: String // "working", "paused", "completed"
    
    // Hesaplanmış değerler
    var currentSessionMinutes: Int {
        if let pauseTime = pauseTime {
            return Int(pauseTime.timeIntervalSince(startTime) / 60)
        } else if let endTime = endTime {
            return Int(endTime.timeIntervalSince(startTime) / 60)
        } else {
            return Int(Date().timeIntervalSince(startTime) / 60)
        }
    }
    
    var totalMinutes: Int {
        return totalWorkMinutes + currentSessionMinutes
    }
    
    enum CodingKeys: String, CodingKey {
        case assignmentId = "assignment_id"
        case scheduleId = "schedule_id"
        case employeeId = "employee_id"
        case startTime = "start_time"
        case pauseTime = "pause_time"
        case resumeTime = "resume_time"
        case endTime = "end_time"
        case totalWorkMinutes = "total_work_minutes"
        case status
    }
} 