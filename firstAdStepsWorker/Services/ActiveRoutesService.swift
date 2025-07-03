import Foundation

class ActiveRoutesService {
    static let shared = ActiveRoutesService()
    private let baseURL = AppConfig.API.baseURL
    private let appToken = AppConfig.API.appToken

    private init() {}
    
    func getActiveRoutes(
        date: Date,
        userId: String,
        status: String? = nil,
        employeeId: Int? = nil,
        completion: @escaping (Result<ActiveRoutesResponse, ServiceError>) -> Void
    ) {
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        var parameters: [String: Any] = [
            "userId": userId
            // "date": dateString
        ]
        
        if let status = status {
            parameters["status"] = status
        }
        
        if let employeeId = employeeId {
            parameters["employeeId"] = employeeId
        }
        
        makeRequest(
            endpoint: "getroutetrackings",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
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
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(appToken, forHTTPHeaderField: "app_token")
        
        // Set increased timeout
        request.timeoutInterval = 60.0
        
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
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
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
                print("🌐 RESPONSE SIZE: \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
                
                // Print full response for debugging
                let responseString = String(data: data, encoding: .utf8) ?? ""
                print("🌐 RESPONSE BODY (FULL): \(responseString)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let result = try decoder.decode(T.self, from: data)
                        completion(.success(result))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .dataCorrupted(let context):
                                print("❌ Data corrupted: \(context.debugDescription)")
                                print("❌ Coding path: \(context.codingPath)")
                            case .keyNotFound(let key, let context):
                                print("❌ Key not found: \(key.stringValue)")
                                print("❌ Coding path: \(context.codingPath)")
                            case .typeMismatch(let type, let context):
                                print("❌ Type mismatch: expected \(type)")
                                print("❌ Coding path: \(context.codingPath)")
                            case .valueNotFound(let type, let context):
                                print("❌ Value not found: expected \(type)")
                                print("❌ Coding path: \(context.codingPath)")
                            @unknown default:
                                print("❌ Unknown decoding error")
                            }
                        }
                        completion(.failure(.invalidData))
                    }
                case 401:
                    completion(.failure(.unauthorized))
                case 403:
                    completion(.failure(.invalidAppToken))
                case 404:
                    completion(.failure(.notFound))
                case 400, 402, 405...499:
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        completion(.failure(.custom(message: errorResponse.message)))
                    } else {
                        completion(.failure(.invalidData))
                    }
                case 500...599:
                    completion(.failure(.serverError("Sunucu hatası: \(httpResponse.statusCode)")))
                default:
                    completion(.failure(.unknown("Beklenmeyen durum kodu: \(httpResponse.statusCode)")))
                }
            } else {
                completion(.failure(.invalidResponse))
            }
        }.resume()
    }
} 
