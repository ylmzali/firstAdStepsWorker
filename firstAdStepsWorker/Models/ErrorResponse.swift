import Foundation

struct ErrorResponse: Codable {
    let code: String
    let message: String
    let details: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case details
    }
} 