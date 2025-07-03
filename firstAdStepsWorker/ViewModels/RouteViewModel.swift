//
//  AddRouteViewModel.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 15.06.2025.
//
import Foundation
import Combine

class RouteViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var routes: [Route]
    @Published var formVal: Route

    private var cancellables = Set<AnyCancellable>()
    private let routeService = RouteService.shared

    init(routes: [Route] = [], formVal: Route) {
        self.routes = routes
        self.formVal = formVal
    }
    
    func resetForm() {
        self.formVal = Route(
            id: UUID().uuidString,
            userId: SessionManager.shared.currentUser?.id ?? "",
            title: "",
            description: "",
            status: .request_received,
            assignedDate: nil,
            completion: 0,
            shareWithEmployees: false,
            sharedEmployeeIds: [],
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    // Kullanıcı bilgisini sessiondan alıp rotaları yükler
    func loadRoutes() {
        // SessionManager.shared veya mevcut session yönetici sınıfınızdan userId alın
        guard let userId = SessionManager.shared.currentUser?.id else {
            self.errorMessage = "Kullanıcı oturumu bulunamadı."
            SessionManager.shared.isAuthenticated = false
            return
        }
        getRoutes(userId: userId) { _ in }
    }

    func getRoute(
        userId: String,
        routeId: String,
        completion: @escaping (Result<RouteGetData, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil

        routeService.getRoute(
            userId: userId,
            routeId: routeId
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success",
                        let data = response.data,
                        let issetRoute = data.issetRoute,
                        issetRoute == true
                        // let route = data.route
                    {
                        completion(.success(data))
                    } else if let error = response.error {
                        self.errorMessage = error.message
                        completion(.failure(.custom(message: error.message)))
                    } else {
                        self.errorMessage = "Rotalar getirilemedi"
                        completion(.failure(.invalidData))
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    func getRoutes(
        userId: String,
        completion: @escaping (Result<RoutesGetData, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil

        routeService.getRoutes(
            userId: userId
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success",
                        let data = response.data, 
                        let issetRoutes = data.issetRoutes,
                        issetRoutes == true,
                        let loadedRoutes = data.routes
                    {
                        self.routes = loadedRoutes
                        completion(.success(data))
                    } else if let error = response.error {
                        self.errorMessage = error.message
                        completion(.failure(.custom(message: error.message)))
                    } else {
                        self.errorMessage = "Rotalar getirilemedi"
                        completion(.failure(.invalidData))
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func createRoute(
        route: Route,
        completion: @escaping (Result<RouteCreateData, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        routeService.createRoute(
            route: route
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success",
                        let data = response.data, 
                        let isRouteCreated = data.isRouteCreated, 
                        isRouteCreated == true 
                    {
                        completion(.success(data))
                    } else if let error = response.error {
                        self.errorMessage = error.message
                        completion(.failure(.custom(message: error.message)))
                    } else {
                        self.errorMessage = "Rota oluşturulamadı"
                        completion(.failure(.invalidData))
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }

    /*
    private func validate(route: Route?) -> Bool {
        if route.name.isEmpty {
            errorMessage = "Rota adı boş olamaz."
            return false
        }
        
        if route.description.isEmpty {
            errorMessage = "Rota açıklaması boş olamaz."
            return false
        }
        
        if route.startLat == nil || route.startLng == nil {
            errorMessage = "Başlangıç konumu seçilmedi."
            return false
        }
        
        if route.endLat == nil || route.endLng == nil {
            errorMessage = "Bitiş konumu seçilmedi."
            return false
        }
        
        if route.areaType.isEmpty {
            errorMessage = "Alan tipi seçilmedi."
            return false
        }
        
        return true
    }
     */

    // MARK: - Plan Management Functions
    
    func approvePlan(
        routeId: String,
        note: String? = nil,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        // TODO: Backend API call for plan approval
        // Bu fonksiyon plan_ready durumundaki rotayı payment_pending durumuna geçirir
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            SessionManager.shared.isLoading = false
            
            // Simulated success - in real app, this would be API call
            if let index = self.routes.firstIndex(where: { $0.id == routeId }) {
                self.routes[index].status = .payment_pending
                completion(.success(true))
            } else {
                self.errorMessage = "Rota bulunamadı"
                completion(.failure(.custom(message: "Rota bulunamadı")))
            }
        }
    }
    
    func rejectPlan(
        routeId: String,
        rejectionType: PlanRejectionType,
        note: String? = nil,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        // TODO: Backend API call for plan rejection
        // Bu fonksiyon plan_ready durumundaki rotayı plan_rejected durumuna geçirir
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            SessionManager.shared.isLoading = false
            
            // Simulated success - in real app, this would be API call
            if let index = self.routes.firstIndex(where: { $0.id == routeId }) {
                self.routes[index].status = .plan_rejected
                self.routes[index].proposalRejectionNote = note
                self.routes[index].proposalRejectionDate = ISO8601DateFormatter().string(from: Date())
                completion(.success(true))
            } else {
                self.errorMessage = "Rota bulunamadı"
                completion(.failure(.custom(message: "Rota bulunamadı")))
            }
        }
    }
    
    func cancelRoute(
        routeId: String,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        // TODO: Backend API call for route cancellation
        // Bu fonksiyon rotayı cancelled durumuna geçirir
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            SessionManager.shared.isLoading = false
            
            // Simulated success - in real app, this would be API call
            if let index = self.routes.firstIndex(where: { $0.id == routeId }) {
                self.routes[index].status = .cancelled
                completion(.success(true))
            } else {
                self.errorMessage = "Rota bulunamadı"
                completion(.failure(.custom(message: "Rota bulunamadı")))
            }
        }
    }
    
    func requestNewPlan(
        routeId: String,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        // TODO: Backend API call for new plan request
        // Bu fonksiyon plan_rejected durumundaki rotayı request_received durumuna geçirir
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            SessionManager.shared.isLoading = false
            
            // Simulated success - in real app, this would be API call
            if let index = self.routes.firstIndex(where: { $0.id == routeId }) {
                self.routes[index].status = .request_received
                self.routes[index].proposalRejectionNote = nil
                self.routes[index].proposalRejectionDate = nil
                completion(.success(true))
            } else {
                self.errorMessage = "Rota bulunamadı"
                completion(.failure(.custom(message: "Rota bulunamadı")))
            }
        }
    }
}

// MARK: - Supporting Enums

enum PlanRejectionType {
    case withNote
    case requestNewPlan
    case cancelCompletely
}

extension Encodable {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

// MARK: - Supporting Types

