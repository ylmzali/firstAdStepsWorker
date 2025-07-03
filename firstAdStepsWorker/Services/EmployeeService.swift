import Foundation

class EmployeeService {
    static let shared = EmployeeService()
    private let baseURL = AppConfig.API.baseURL
    private let appToken = AppConfig.API.appToken
    
    private init() {}
    
    // MARK: - Get Company Employees
    func getCompanyEmployees(
        userId: String,
        companyTaxNumber: String,
        completion: @escaping (Result<EmployeeListResponse, ServiceError>) -> Void
    ) {
        let parameters = [
            "company_tax_number": companyTaxNumber,
            "user_id": userId
        ]
        
        makeRequest(
            endpoint: "getcompanyemployees",
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
struct EmployeeListResponse: Codable {
    let status: String
    let data: EmployeeListData?
    let error: EmployeeListError?
}

struct EmployeeListData: Codable {
    let employees: [User]?
    let totalCount: Int?
}

struct EmployeeListError: Codable {
    let code: String
    let message: String
    let details: String
}
