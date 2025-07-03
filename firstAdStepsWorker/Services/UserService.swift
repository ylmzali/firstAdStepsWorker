import Foundation

class UserService {
    static let shared = UserService()
    private let baseURL = AppConfig.API.baseURL
    private let appToken = AppConfig.API.appToken
    
    private init() {}
    
    // MARK: - Get User
    func getUser(
        userId: String,
        completion: @escaping (Result<UserGetResponse, ServiceError>) -> Void
    ) {
        let parameters = [
            "userId": userId
        ]
        
        makeRequest(
            endpoint: "getuser",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
    // MARK: - Register
    func register(
        phoneNumber: String,
        countryCode: String,
        firstName: String,
        lastName: String,
        email: String,
        companyName: String?,
        companyTaxNumber: String?,
        companyTaxOffice: String?,
        companyAddress: String?,
        completion: @escaping (Result<UserRegisterResponse, ServiceError>) -> Void
    ) {
        var parameters: [String: Any] = [
            "phone_number": phoneNumber,
            "country_code": countryCode,
            "first_name": firstName,
            "last_name": lastName,
            "email": email
        ]
        
        if let companyName = companyName {
            parameters["company_name"] = companyName
        }
        if let companyTaxNumber = companyTaxNumber {
            parameters["company_tax_number"] = companyTaxNumber
        }
        if let companyTaxOffice = companyTaxOffice {
            parameters["company_tax_office"] = companyTaxOffice
        }
        if let companyAddress = companyAddress {
            parameters["company_address"] = companyAddress
        }
        
        makeRequest(
            endpoint: "adduser",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
    // MARK: - Update User
    func updateUser(
        user: User,
        completion: @escaping (Result<UserUpdateResponse, ServiceError>) -> Void
    ) {
        var parameters: [String: Any] = [
            "user_id": user.id,
            "first_name": user.firstName,
            "last_name": user.lastName,
            "email": user.email,
            "country_code": user.countryCode,
            "phone_number": user.phoneNumber,
            "status": user.status
        ]
        
        // Optional şirket bilgileri
        if let companyName = user.companyName {
            parameters["company_name"] = companyName
        }
        if let companyTaxNumber = user.companyTaxNumber {
            parameters["company_tax_number"] = companyTaxNumber
        }
        if let companyTaxOffice = user.companyTaxOffice {
            parameters["company_tax_office"] = companyTaxOffice
        }
        if let companyAddress = user.companyAddress {
            parameters["company_address"] = companyAddress
        }
        
        makeRequest(
            endpoint: "updateuser",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
    // MARK: - Helper Methods
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, ServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(.invalidUrl))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appToken, forHTTPHeaderField: "app_token")
        
        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                print("🌐 REQUEST URL: \(url)")
                print("🌐 REQUEST METHOD: \(method.rawValue)")
                print("🌐 REQUEST HEADERS: \(request.allHTTPHeaderFields ?? [:])")
                print("🌐 REQUEST BODY: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "")")
            } catch {
                completion(.failure(.invalidData))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(.failure(.networkError))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.invalidData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 RESPONSE STATUS: \(httpResponse.statusCode)")
                    print("🌐 RESPONSE BODY: \(String(data: data, encoding: .utf8) ?? "")")

                    switch httpResponse.statusCode {
                    case 200...299:
                        do {
                            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                            completion(.success(decodedResponse))
                        } catch {
                            print("❌ Decoding error: \(error)")
                            completion(.failure(.invalidData))
                        }
                    case 401:
                        completion(.failure(.unauthorized))
                    case 404:
                        completion(.failure(.notFound))
                    case 400...499:
                        completion(.failure(.badRequest))
                    case 500...599:
                        completion(.failure(.serverError("Sunucu hatası")))
                    default:
                        completion(.failure(.unknown("Beklenmeyen durum kodu: \(httpResponse.statusCode)")))
                    }
                } else {
                    completion(.failure(.invalidResponse))
                }
            }
        }.resume()
    }
}

// MARK: - Response Models
struct UserGetResponse: Codable {
    let status: String
    let data: UserGetData?
    let error: UserGetError?
}

struct UserGetData: Codable {
    let issetUser: Bool?
    let user: User?
}

struct UserGetError: Codable {
    let code: String
    let message: String
    let details: String
}


struct UserRegisterResponse: Codable {
    let status: String
    let data: UserRegisterData?
    let error: UserRegisterError?
}
struct UserRegisterData: Codable {
    let isUserSaved: Bool?
    let user: User?
}
struct UserRegisterError: Codable {
    let code: String
    let message: String
    let details: String
}


struct UserUpdateResponse: Codable {
    let status: String
    let data: UserUpdateData?
    let error: UserUpdateError?
}
struct UserUpdateData: Codable {
    let isUserUpdated: Bool?
    let user: User?
}
struct UserUpdateError: Codable {
    let code: String
    let message: String
    let details: String
} 
