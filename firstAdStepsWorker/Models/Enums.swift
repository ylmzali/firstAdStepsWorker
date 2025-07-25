//
//  UserServiceError.swift
//  firstAdSteps
//
//  Created by Ali YILMAZ on 2.06.2025.
//
import SwiftUI


struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

enum AppView {
    case splash
    case auth
    case main
}

// WorkStatus Enum
enum WorkStatus: String, CaseIterable, Codable {
    case available = "available"
    case onRoute = "on_route"
    case offDuty = "off_duty"
    case busy = "busy"
    
    var displayName: String {
        switch self {
        case .available:
            return "Müsait"
        case .onRoute:
            return "Rota Üzerinde"
        case .offDuty:
            return "İzinde"
        case .busy:
            return "Meşgul"
        }
    }
    
    var color: Color {
        switch self {
        case .available:
            return .green
        case .onRoute:
            return .blue
        case .offDuty:
            return .orange
        case .busy:
            return .red
        }
    }
}

// HTTPMethod.swift
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case badRequest
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .noData:
            return "Veri alınamadı"
        case .decodingError:
            return "Veri çözümlenemedi"
        case .serverError(let message):
            return "Sunucu hatası: \(message)"
        case .unauthorized:
            return "Yetkisiz erişim"
        case .badRequest:
            return "Geçersiz istek"
        case .unknown:
            return "Bilinmeyen hata"
        }
    }
}
