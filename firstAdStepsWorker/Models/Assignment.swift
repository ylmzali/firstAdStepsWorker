import Foundation
import SwiftUI

// Assignment Model - Worker'a atanan görevler
struct Assignment: Codable, Identifiable {
    let id: String
    let routeId: String
    let planId: String
    let scheduleDate: String
    let startTime: String
    let endTime: String
    let routeType: String
    let startLat: String
    let startLng: String
    let endLat: String
    let endLng: String
    let centerLat: String
    let centerLng: String
    let radiusMeters: String
    let mapSnapshotUrl: String?
    let mapSnapshotCreatedAt: String?
    var status: String
    var workStatus: String
    let createdBy: String
    let createdAt: String
    let assignmentScheduleId: String
    let assignmentScreenId: String
    let assignmentEmployeeId: String
    let assignmentOfferDescription: String?
    let assignmentOfferBudget: String
    let assignmentStatus: AssignmentStatus
    let assignmentWorkStatus: AssignmentWorkStatus
    let assignmentId: String
    let assignmentCreatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case routeId
        case planId
        case scheduleDate
        case startTime
        case endTime
        case routeType
        case startLat
        case startLng
        case endLat
        case endLng
        case centerLat
        case centerLng
        case radiusMeters
        case mapSnapshotUrl
        case mapSnapshotCreatedAt
        case status
        case workStatus
        case createdBy
        case createdAt
        case assignmentScheduleId
        case assignmentScreenId
        case assignmentEmployeeId
        case assignmentOfferDescription
        case assignmentOfferBudget
        case assignmentStatus
        case assignmentWorkStatus
        case assignmentId
        case assignmentCreatedAt
    }
    
    // Normal initializer
    init(id: String,
         routeId: String,
         planId: String,
         scheduleDate: String,
         startTime: String,
         endTime: String,
         routeType: String,
         startLat: String,
         startLng: String,
         endLat: String,
         endLng: String,
         centerLat: String,
         centerLng: String,
         radiusMeters: String,
         mapSnapshotUrl: String?,
         mapSnapshotCreatedAt: String?,
         status: String,
         workStatus: String,
         createdBy: String,
         createdAt: String,
         assignmentScheduleId: String,
         assignmentScreenId: String,
         assignmentEmployeeId: String,
         assignmentOfferDescription: String?,
         assignmentOfferBudget: String,
         assignmentStatus: AssignmentStatus,
         assignmentWorkStatus: AssignmentWorkStatus,
         assignmentId: String,
         assignmentCreatedAt: String) {
        self.id = id
        self.routeId = routeId
        self.planId = planId
        self.scheduleDate = scheduleDate
        self.startTime = startTime
        self.endTime = endTime
        self.routeType = routeType
        self.startLat = startLat
        self.startLng = startLng
        self.endLat = endLat
        self.endLng = endLng
        self.centerLat = centerLat
        self.centerLng = centerLng
        self.radiusMeters = radiusMeters
        self.mapSnapshotUrl = mapSnapshotUrl
        self.mapSnapshotCreatedAt = mapSnapshotCreatedAt
        self.status = status
        self.workStatus = workStatus
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.assignmentScheduleId = assignmentScheduleId
        self.assignmentScreenId = assignmentScreenId
        self.assignmentEmployeeId = assignmentEmployeeId
        self.assignmentOfferDescription = assignmentOfferDescription
        self.assignmentOfferBudget = assignmentOfferBudget
        self.assignmentStatus = assignmentStatus
        self.assignmentWorkStatus = assignmentWorkStatus
        self.assignmentId = assignmentId
        self.assignmentCreatedAt = assignmentCreatedAt
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        routeId = try container.decode(String.self, forKey: .routeId)
        planId = try container.decode(String.self, forKey: .planId)
        scheduleDate = try container.decode(String.self, forKey: .scheduleDate)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        routeType = try container.decode(String.self, forKey: .routeType)
        startLat = try container.decode(String.self, forKey: .startLat)
        startLng = try container.decode(String.self, forKey: .startLng)
        endLat = try container.decode(String.self, forKey: .endLat)
        endLng = try container.decode(String.self, forKey: .endLng)
        centerLat = try container.decode(String.self, forKey: .centerLat)
        centerLng = try container.decode(String.self, forKey: .centerLng)
        radiusMeters = try container.decode(String.self, forKey: .radiusMeters)
        mapSnapshotUrl = try container.decodeIfPresent(String.self, forKey: .mapSnapshotUrl)
        mapSnapshotCreatedAt = try container.decodeIfPresent(String.self, forKey: .mapSnapshotCreatedAt)
        status = try container.decode(String.self, forKey: .status)
        workStatus = try container.decode(String.self, forKey: .workStatus)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        assignmentScheduleId = try container.decode(String.self, forKey: .assignmentScheduleId)
        assignmentScreenId = try container.decode(String.self, forKey: .assignmentScreenId)
        assignmentEmployeeId = try container.decode(String.self, forKey: .assignmentEmployeeId)
        assignmentOfferDescription = try container.decodeIfPresent(String.self, forKey: .assignmentOfferDescription)
        assignmentOfferBudget = try container.decode(String.self, forKey: .assignmentOfferBudget)
        assignmentStatus = try container.decode(AssignmentStatus.self, forKey: .assignmentStatus)
        assignmentWorkStatus = try container.decode(AssignmentWorkStatus.self, forKey: .assignmentWorkStatus)
        assignmentId = try container.decode(String.self, forKey: .assignmentId)
        assignmentCreatedAt = try container.decode(String.self, forKey: .assignmentCreatedAt)
    }
    
    // Preview için test verisi
    static let preview = Assignment(
        id: "44",
        routeId: "27",
        planId: "23",
        scheduleDate: "2025-07-27",
        startTime: "08:00:00",
        endTime: "24:00:00",
        routeType: "fixed_route",
        startLat: "41.04045300",
        startLng: "28.97888800",
        endLat: "41.03553300",
        endLng: "28.97588400",
        centerLat: "41.04045300",
        centerLng: "28.97888800",
        radiusMeters: "0",
        mapSnapshotUrl: "/assets/uploads/map_snapshots/schedule_44_1752669278.png",
        mapSnapshotCreatedAt: "2025-07-16 15:34:38",
        status: "pending",
        workStatus: "pending",
        createdBy: "1",
        createdAt: "2025-07-16 15:33:54",
        assignmentScheduleId: "44",
        assignmentScreenId: "6",
        assignmentEmployeeId: "7",
        assignmentOfferDescription: "1 gün 4 saatlik bir program. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.",
        assignmentOfferBudget: "350.00",
        assignmentStatus: .accepted,
        assignmentWorkStatus: .working,
        assignmentId: "26",
        assignmentCreatedAt: "2025-07-23 15:35:51"
    )
}

extension Assignment {
    /// Kısa Türkçe tarih (örn: 15.06.2024)
    var formattedShortDate: String {
        scheduleDate.toShortDate ?? scheduleDate
    }
    /// Uzun Türkçe tarih (örn: 15 Haziran 2024)
    var formattedTurkishDate: String {
        scheduleDate.toTurkishDate ?? scheduleDate
    }
    /// Başlangıç saati (örn: 16:00)
    var formattedStartTime: String {
        DateFormatter.formatTimeString(startTime)
    }
    /// Bitiş saati (örn: 21:00)
    var formattedEndTime: String {
        let timeString = DateFormatter.formatTimeString(endTime)
        // Eğer 24:00 ise, 23:59 olarak göster
        if timeString == "24:00" {
            return "23:59"
        }
        return timeString
    }
    
    /// Kısa tarih + saat aralığı (örn: 15.06.2024 16:00 - 21:00)
    var formattedDateTimeRange: String {
        "\(formattedShortDate) \(formattedStartTime) - \(formattedEndTime)"
    }
    /// Türkçe tarih + saat (örn: 2 Ocak 2025 saat 16:30)
    var formattedTurkishDateTime: String {
        let dateString = scheduleDate.toTurkishLongDate ?? scheduleDate
        let timeString = formattedStartTime
        return "\(dateString) saat \(timeString)"
    }
    /// Kısa yazılı Türkçe tarih (örn: 2 Temmuz 2025)
    var formattedTurkishShortDate: String {
        scheduleDate.toTurkishShortDate ?? scheduleDate
    }
    /// Kısa yazılı Türkçe tarih + saat (örn: 2 Temmuz 2025 saat 16:00)
    var formattedTurkishShortDateTime: String {
        "\(formattedTurkishShortDate) saat \(formattedStartTime)"
    }
}

// Assignment Status Enum
enum AssignmentStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Bekliyor"
        case .accepted:
            return "Kabul Edildi"
        case .rejected:
            return "Reddedildi"
        case .cancelled:
            return "İptal Edildi"
        }
    }
    
    var statusDescription: String {
        switch self {
        case .pending:
            return "Onay bekliyor"
        case .accepted:
            return "Kabul edildi"
        case .rejected:
            return "Reddedildi"
        case .cancelled:
            return "İptal edildi"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .accepted:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
} 

// Assignment Work Status Enum
enum AssignmentWorkStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case working = "working"
    case paused = "paused"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Bekliyor"
        case .working:
            return "Çalışıyor"
        case .paused:
            return "Durduruldu"
        case .completed:
            return "Tamamlandı"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .pending:
            return .gray
        case .working:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .working:
            return "arrow.counterclockwise.circle.fill"
        case .paused:
            return "pause.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
} 
