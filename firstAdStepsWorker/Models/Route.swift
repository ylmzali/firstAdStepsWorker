import Foundation
import SwiftUI

enum RouteStatus: String, Codable {
    case request_received = "request_received"           // 1. Reklam talebi alındı
    case plan_ready = "plan_ready"                       // 2. Plan hazırlandı
    case payment_pending = "payment_pending"             // 3.1. Plan onaylandı, ödeme bekleniyor
    case plan_rejected = "plan_rejected"                 // 3.2. Plan reddedildi
    case payment_completed = "payment_completed"         // 4. Ödeme alındı, yayın planına alındı
    case ready_to_start = "ready_to_start"               // 5. Yayına hazır, yayın tarihinde aktif olacak
    case active = "active"                               // Aktif yayın
    case completed = "completed"                         // Tamamlandı
    case cancelled = "cancelled"                         // İptal edildi
    
    // Custom decoder for unknown status values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Try to create from raw value, fallback to request_received if unknown
        if let status = RouteStatus(rawValue: rawValue) {
            self = status
        } else {
            print("⚠️ Unknown status received from backend: '\(rawValue)', falling back to request_received")
            self = .request_received
        }
    }
    
    var statusColor: Color {
        switch self {
        case .request_received: return .gray
        case .plan_ready: return .blue
        case .payment_pending: return .orange
        case .plan_rejected: return .red
        case .payment_completed: return .green
        case .ready_to_start: return .green
        case .active: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
    
    var statusDescription: String {
        switch self {
        case .request_received:
            return "Reklam talebi alındı"
        case .plan_ready:
            return "Plan hazırlandı"
        case .payment_pending:
            return "Plan onaylandı, ödeme bekleniyor"
        case .plan_rejected:
            return "Plan reddedildi"
        case .payment_completed:
            return "Ödeme alındı, yayın planına alındı"
        case .ready_to_start:
            return "Yayına hazır, yayın tarihinde aktif olacak"
        case .active:
            return "Aktif yayın"
        case .completed:
            return "Tamamlandı"
        case .cancelled:
            return "İptal edildi"
        }
    }
    
    var canStartLiveTracking: Bool {
        return self == .active
    }
    
    var isPlanPhase: Bool {
        return self == .plan_ready
    }
    
    var isPaymentPhase: Bool {
        return self == .payment_pending
    }
    
    var isRejected: Bool {
        return self == .plan_rejected
    }
    
    var isActive: Bool {
        return self == .active || self == .completed
    }
    
    var canCancel: Bool {
        return self == .request_received || self == .plan_ready || self == .payment_pending
    }
    
    var isInProposalPhase: Bool {
        self == .request_received || self == .plan_ready || self == .plan_rejected
    }
    
    // MARK: - Workflow Order Properties
    
    /// Her status'un workflow'daki sırası (1'den başlar)
    var workflowOrder: Int {
        switch self {
        case .request_received: return 1
        case .plan_ready: return 2
        case .payment_pending: return 3
        case .payment_completed: return 4
        case .ready_to_start: return 4
        case .active: return 5
        case .completed: return 6
        case .plan_rejected: return 1 // Plan reddedildiğinde yeniden baştan başlar
        case .cancelled: return 0 // İptal edildi
        }
    }
    
    /// Belirli bir adımın tamamlanıp tamamlanmadığını kontrol eder
    func isStepCompleted(_ stepOrder: Int) -> Bool {
        return self.workflowOrder > stepOrder
    }
    
    /// Belirli bir adımın aktif olup olmadığını kontrol eder
    func isStepActive(_ stepOrder: Int) -> Bool {
        return self.workflowOrder == stepOrder
    }
    
    /// Belirli bir adımın gelecekte olup olmadığını kontrol eder
    func isStepFuture(_ stepOrder: Int) -> Bool {
        return self.workflowOrder < stepOrder
    }
}

// Progress Color based on completion percentage
enum ProgressColor {
    case low      // 0-30%
    case medium   // 31-70%
    case high     // 71-100%
    
    static func fromCompletion(_ completion: Int) -> ProgressColor {
        switch completion {
        case 0...30:
            return .low
        case 31...70:
            return .medium
        case 71...100:
            return .high
        default:
            return .low
        }
    }
    
    var color: Color {
        switch self {
        case .low:
            return .red
        case .medium:
            return .orange
        case .high:
            return .green
        }
    }
}

// User Model
struct Route: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var description: String
    var status: RouteStatus
    var assignedDate: String?
    var completion: Int
    var shareWithEmployees: Bool
    var sharedEmployeeIds: [String] // Seçilen çalışanların ID'leri
    var createdAt: String
    var proposalRejectionNote: String? // Plan reddetme notu
    var proposalRejectionDate: String? // Plan reddetme tarihi

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case title
        case description
        case status
        case assignedDate
        case completion
        case shareWithEmployees
        case sharedEmployeeIds
        case createdAt = "createdAt"
        case proposalRejectionNote
        case proposalRejectionDate
    }

    // Normal initializer
    init(id: String,
         userId: String,
         title: String,
         description: String,
         status: RouteStatus,
         assignedDate: String?,
         completion: Int,
         shareWithEmployees: Bool = false,
         sharedEmployeeIds: [String] = [],
         createdAt: String
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.assignedDate = assignedDate
        self.completion = completion
        self.shareWithEmployees = shareWithEmployees
        self.sharedEmployeeIds = sharedEmployeeIds
        self.createdAt = createdAt
    }

    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        status = try container.decode(RouteStatus.self, forKey: .status)
        assignedDate = try container.decodeIfPresent(String.self, forKey: .assignedDate)
        completion = try container.decode(Int.self, forKey: .completion)
        shareWithEmployees = try container.decodeIfPresent(Bool.self, forKey: .shareWithEmployees) ?? false
        sharedEmployeeIds = try container.decodeIfPresent([String].self, forKey: .sharedEmployeeIds) ?? []
        createdAt = try container.decode(String.self, forKey: .createdAt)
        proposalRejectionNote = try container.decodeIfPresent(String.self, forKey: .proposalRejectionNote)
        proposalRejectionDate = try container.decodeIfPresent(String.self, forKey: .proposalRejectionDate)
    }

    // MARK: - Computed Properties for Formatted Dates
    
    /// Formatlanmış atama tarihi (örn: 24 Haziran 2025)
    var formattedAssignedDate: String? {
        guard let assignedDate = assignedDate else { return nil }
        return assignedDate.toTurkishDate
    }
    
    /// Formatlanmış atama tarihi ve saati (örn: 24 Haziran 2025, 13:19)
    var formattedAssignedDateTime: String? {
        guard let assignedDate = assignedDate else { return nil }
        return assignedDate.toTurkishDateTime
    }
    
    /// Kısa formatlanmış atama tarihi (örn: 24.06.2025)
    var shortAssignedDate: String? {
        guard let assignedDate = assignedDate else { return nil }
        return assignedDate.toShortDate
    }
    
    /// Kısa formatlanmış atama tarihi ve saati (örn: 24.06.2025 13:19)
    var shortAssignedDateTime: String? {
        guard let assignedDate = assignedDate else { return nil }
        return assignedDate.toShortDateTime
    }
    
    /// Göreceli atama zamanı (örn: 2 saat önce)
    var relativeAssignedTime: String? {
        guard let assignedDate = assignedDate else { return nil }
        return assignedDate.toRelativeTime
    }
    
    /// Formatlanmış oluşturma tarihi (örn: 24 Haziran 2025)
    var formattedCreatedDate: String? {
        return createdAt.toTurkishDate
    }
    
    /// Kısa formatlanmış oluşturma tarihi (örn: 24.06.2025)
    var shortCreatedDate: String? {
        return createdAt.toShortDate
    }
    
    /// Göreceli oluşturma zamanı (örn: 2 saat önce)
    var relativeCreatedTime: String? {
        return createdAt.toRelativeTime
    }

    // MARK: - Live Tracking Status
    
    /// Canlı takip yapılabilir mi?
    var canStartLiveTracking: Bool {
        guard status.canStartLiveTracking else { return false }
        guard let assignedDate = assignedDate, let date = assignedDate.toDate else { return false }
        
        // Atama tarihi geldi mi?
        return Date() >= date
    }
    
    /// Canlı takip durumu açıklaması
    var liveTrackingStatusDescription: String {
        if !status.canStartLiveTracking {
            return status.statusDescription
        }
        
        guard let assignedDate = assignedDate, let date = assignedDate.toDate else {
            return "Tarih ataması bekleniyor"
        }
        
        if Date() < date {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            return "Başlama tarihi: \(formatter.string(from: date))"
        }
        
        return "Canlı takip başlatılabilir"
    }
    
    /// Canlı takip buton rengi
    var liveTrackingButtonColor: Color {
        if canStartLiveTracking {
            return .green
        } else if status.isPlanPhase {
            return .blue
        } else if status.isPaymentPhase {
            return .yellow
        } else if status.isRejected {
            return .red
        } else {
            return .gray
        }
    }

    // Preview için test verisi
    static let preview = Route(
        id: "1",
        userId: "1233",
        title: "Kadıköy - Üsküdar Kadıköy'den Üsküdar'a giden rota Kadıköy'den Üsküdar'a giden rota",
        description: "Kadıköy - Üsküdar Kadıköy'den Üsküdar'a giden rota Kadıköy'den Üsküdar'a giden rota",
        status: .active,
        assignedDate: "2024-03-20T12:00:00Z",
        // assignedDate: nil,
        completion: 80,
        shareWithEmployees: true,
        sharedEmployeeIds: ["1", "2", "1233"],
        createdAt: "2024-03-20T12:00:00Z"
    )
}
