import Foundation

// User Model
struct User: Codable, Identifiable {
    let id: String
    let companyId: String?
    let firstName: String
    let lastName: String
    let email: String
    let countryCode: String
    let phoneNumber: String
    let companyName: String?
    let companyTaxNumber: String?
    let companyTaxOffice: String?
    let companyAddress: String?
    let workStatus: WorkStatus?
    let status: String
    let createdAt: String
    let updatedAt: String?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case firstName
        case lastName
        case email
        case countryCode
        case phoneNumber
        case companyName
        case companyTaxNumber
        case companyTaxOffice
        case companyAddress
        case workStatus
        case status
        case createdAt
        case updatedAt
    }
    
    // Normal initializer
    init(id: String,
         companyId: String? = nil,
         firstName: String,
         lastName: String,
         email: String,
         countryCode: String,
         phoneNumber: String,
         companyName: String? = nil,
         companyTaxNumber: String? = nil,
         companyTaxOffice: String? = nil,
         companyAddress: String? = nil,
         workStatus: WorkStatus? = nil,
         status: String = "active",
         createdAt: String,
         updatedAt: String? = nil) {
        self.id = id
        self.companyId = companyId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
        self.companyName = companyName
        self.companyTaxNumber = companyTaxNumber
        self.companyTaxOffice = companyTaxOffice
        self.companyAddress = companyAddress
        self.workStatus = workStatus
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // API'den gelen alanları decode et
        id = try container.decode(String.self, forKey: .id)
        companyId = try container.decodeIfPresent(String.self, forKey: .companyId)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        
        // Optional alanlar
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName)
        companyTaxNumber = try container.decodeIfPresent(String.self, forKey: .companyTaxNumber)
        companyTaxOffice = try container.decodeIfPresent(String.self, forKey: .companyTaxOffice)
        companyAddress = try container.decodeIfPresent(String.self, forKey: .companyAddress)
        
        // WorkStatus decode etme
        if let workStatusString = try container.decodeIfPresent(String.self, forKey: .workStatus) {
            workStatus = WorkStatus(rawValue: workStatusString)
        } else {
            workStatus = nil
        }
        
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
    
    // Preview için test verisi
    static let preview = User(
        id: "7",
        companyId: "7",
        firstName: "Mustafa",
        lastName: "Koç",
        email: "mustafa.koc@example.com",
        countryCode: "+90",
        phoneNumber: "5426943496",
        companyName: "Test Company",
        companyTaxNumber: "1234567890",
        companyTaxOffice: "Test Office",
        companyAddress: "Test Address",
        workStatus: .offDuty,
        status: "active",
        createdAt: "2025-07-06 13:48:09",
        updatedAt: "2025-07-20 04:05:59"
    )
} 
