import Foundation

// User Model
struct User: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let countryCode: String
    let phoneNumber: String
    let companyName: String?
    let companyTaxNumber: String?
    let companyTaxOffice: String?
    let companyAddress: String?
    let status: String
    let createdAt: String
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
        case countryCode
        case phoneNumber
        case companyName
        case companyTaxNumber
        case companyTaxOffice
        case companyAddress
        case status
        case createdAt = "createdAt"
    }
    
    // Normal initializer
    init(id: String,
         firstName: String,
         lastName: String,
         email: String,
         countryCode: String,
         phoneNumber: String,
         companyName: String? = nil,
         companyTaxNumber: String? = nil,
         companyTaxOffice: String? = nil,
         companyAddress: String? = nil,
         status: String = "active",
         createdAt: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
        self.companyName = companyName
        self.companyTaxNumber = companyTaxNumber
        self.companyTaxOffice = companyTaxOffice
        self.companyAddress = companyAddress
        self.status = status
        self.createdAt = createdAt
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // API'den gelen alanları decode et
        id = try container.decode(String.self, forKey: .id)
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
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
    
    // Preview için test verisi
    static let preview = User(
        id: "1",
        firstName: "John",
        lastName: "Doe",
        email: "john@example.com",
        countryCode: "+90",
        phoneNumber: "5551234567",
        companyName: "Test Company",
        companyTaxNumber: "1234567890",
        companyTaxOffice: "Test Office",
        companyAddress: "Test Address",
        status: "active",
        createdAt: "2024-03-20T12:00:00Z"
    )
} 
