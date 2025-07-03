//
//  RouteService.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 15.06.2025.
//

import Foundation
import Combine

class RouteService {
    static let shared = RouteService()
    private let baseURL = AppConfig.API.baseURL
    private let appToken = AppConfig.API.appToken
    
    private init() {}
    
    // MARK: - ROUTE GET Request
    func getRoute(
        userId: String,
        routeId: String,
        completion: @escaping (Result<RouteGetResponse, ServiceError>) -> Void
    ) {
        let parameters = [
            "userId": userId,
            "routeId": routeId
        ]
        
        makeRequest(
            endpoint: "getroute",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }

    // MARK: - ROUTES GET Request
    func getRoutes(
        userId: String,
        completion: @escaping (Result<RoutesGetResponse, ServiceError>) -> Void
    ) {
        let parameters = [
            "userId": userId
        ]
        
        makeRequest(
            endpoint: "getroutes",
            method: .post,
            parameters: parameters,
            completion: completion
        )
    }
    
    // MARK: - ROUTE CREATE Request
    func createRoute(
        route: Route,
        completion: @escaping (Result<RouteCreateResponse, ServiceError>) -> Void
    ) {
        guard let routeDict = route.asDictionary else {
            completion(.failure(.invalidData))
            return
        }

        let parameters = [
            "route": routeDict
        ]
        
        makeRequest(
            endpoint: "createroute",
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
                print("🌐 RESPONSE BODY: \(String(data: data, encoding: .utf8) ?? "")")
                
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
