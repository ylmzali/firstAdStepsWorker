import Foundation

enum ServiceError: LocalizedError {
    case networkError
    case invalidUrl
    case invalidData
    case invalidOTPLength
    case invalidAppToken
    case serverError(String)
    case unknown(String)
    case notFound
    case badRequest
    case invalidCode
    case invalidResponse

    case noData
    case encodingError
    case decodingError

    case unauthorized
    
    case custom(message: String)

    
    var errorDescription: String? {
        switch self {
        case .custom(let message): return message

        case .networkError:
            return "İnternet bağlantınızı kontrol edin"
        case .invalidUrl:
            return "Geçersiz url adresi"
        case .invalidData:
            return "Geçersiz veri formatı"
        case .invalidOTPLength:
            return "OTP kodu 4 haneli olmalıdır"
        case .invalidAppToken:
            return "Uygulama kimlik doğrulaması başarısız"
        case .serverError(let message):
            return message
        case .unknown(let message):
            return message
        case .notFound:
            return "Kullanıcı bulunamadı"
        case .badRequest:
            return "Geçersiz istek"
        case .invalidCode:
            return "Girilen kod hatalı"
        case .invalidResponse:
            return "Tanımlanamayan sonuç"
            
        case .noData:
            return "Veri alınamadı"
        case .decodingError:
            return "Veri çözümlenemedi"
        case .encodingError:
            return "Veri şifrelenemedi"

        case .unauthorized:
            return "Yetkisiz erişim"
        }
    }
    
    var userMessage: String {
        switch self {
        case .networkError:
            return "İnternet bağlantınızı kontrol edip tekrar deneyin"
        case .invalidData:
            return "Bir hata oluştu, lütfen tekrar deneyin"
        case .invalidOTPLength:
            return "Lütfen 4 haneli doğrulama kodunu girin"
        case .invalidAppToken:
            return "Uygulama kimlik doğrulaması başarısız, lütfen tekrar deneyin"
        case .serverError(let message):
            return message
        case .unknown(let message):
            return "Beklenmeyen bir hata oluştu: \(message)"
        case .notFound:
            return "Kullanıcı bulunamadı, lütfen tekrar deneyin"
        case .badRequest:
            return "Geçersiz istek, lütfen tekrar deneyin"
        case .invalidCode:
            return "Girilen kod hatalı, lütfen tekrar deneyin"
        case .unauthorized:
            return "Oturum süreniz doldu, lütfen tekrar giriş yapın"
        case .invalidResponse:
            return "Sonuç okunamadı"
        case .custom(message: let message):
            return message

        case .noData:
            return "Veri alınamadı"
        case .encodingError:
            return "Veri şifrelenemedi"
        case .decodingError:
            return "Veri çözümlenemedi"

        case .invalidUrl:
            return "Geçersiz URL"
        }
    }
}
