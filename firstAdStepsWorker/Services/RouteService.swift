//
//  RouteService.swift
//  firstAdStepsWorker
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
    
    // MARK: - Get Pending Assignments
    func getPendingAssignments(
        userId: String,
        completion: @escaping (Result<[Assignment], ServiceError>) -> Void
    ) {
        let parameters = [
            "user_id": userId
        ]
        
        makeRequest(
            endpoint: AppConfig.Endpoints.getAssignments,
            method: .post,
            parameters: parameters
        ) { (result: Result<PendingAssignmentsResponse, ServiceError>) in
            switch result {
            case .success(let response):
                if response.status == "success",
                   let data = response.data,
                   let issetRoutes = data.issetRoutes,
                   issetRoutes == true,
                   let assignments = data.routes {
                    completion(.success(assignments))
                } else if let error = response.error {
                    completion(.failure(.custom(message: error.message)))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Accept Assignment
    func acceptAssignment(
        assignmentId: String,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        let parameters = [
            "assignment_id": assignmentId
        ]
        
        makeRequest(
            endpoint: AppConfig.Endpoints.acceptAssignment,
            method: .post,
            parameters: parameters
        ) { (result: Result<AssignmentActionResponse, ServiceError>) in
            switch result {
            case .success(let response):
                if response.status == "success" {
                    completion(.success(true))
                } else if let error = response.error {
                    completion(.failure(.custom(message: error.message)))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Reject Assignment
    func rejectAssignment(
        assignmentId: String,
        reason: String?,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        var parameters: [String: Any] = [
            "assignment_id": assignmentId
        ]
        
        if let reason = reason, !reason.isEmpty {
            parameters["reason"] = reason
        }
        
        makeRequest(
            endpoint: AppConfig.Endpoints.rejectAssignment,
            method: .post,
            parameters: parameters
        ) { (result: Result<AssignmentActionResponse, ServiceError>) in
            switch result {
            case .success(let response):
                if response.status == "success" {
                    completion(.success(true))
                } else if let error = response.error {
                    completion(.failure(.custom(message: error.message)))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Genel assignment/route sorgusu
    func getAssignments(
        userId: String,
        filters: [String: String]? = nil,
        completion: @escaping (Result<[Assignment], ServiceError>) -> Void
    ) {
        var parameters: [String: Any] = ["user_id": userId]
        if let filters = filters {
            for (key, value) in filters {
                parameters[key] = value
            }
        }
        makeRequest(
            endpoint: AppConfig.Endpoints.getAssignments, // veya uygun endpoint
            method: .post,
            parameters: parameters
        ) { (result: Result<PendingAssignmentsResponse, ServiceError>) in
            switch result {
            case .success(let response):
                if response.status == "success",
                   let data = response.data,
                   let issetRoutes = data.issetRoutes,
                   issetRoutes == true,
                   let assignments = data.routes {
                    completion(.success(assignments))
                } else if let error = response.error {
                    completion(.failure(.custom(message: error.message)))
                } else {
                    completion(.success([]))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func makeRequest<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        completion: @escaping (Result<T, ServiceError>) -> Void
    ) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
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
                        // Backend'den camelCase geliyor, snake_case conversion'a gerek yok
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
