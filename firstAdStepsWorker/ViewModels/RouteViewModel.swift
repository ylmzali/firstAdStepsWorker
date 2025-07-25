//
//  AddRouteViewModel.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 15.06.2025.
//
import Foundation
import Combine

class RouteViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var assignments: [Assignment] = [] // Bekleyen teklifler
    @Published var routes: [Assignment] = []      // Kabul edilen rotalar
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let routeService = RouteService.shared

    init(routes: [Assignment] = []) {
        self.routes = routes
        
        // Demo rotalar ekle (sadece preview için)
        #if DEBUG
        if routes.isEmpty {
            // self.routes = createDemoAssignments()
        }
        #endif
    }
    
    private func createDemoAssignments() -> [Assignment] {
        return [
            Assignment(
                id: "1",
                planId: "1",
                scheduleDate: "2025-07-24",
                startTime: "16:00:00",
                endTime: "21:00:00",
                routeType: "area_route",
                startLat: "0.00000000",
                startLng: "0.00000000",
                endLat: "0.00000000",
                endLng: "0.00000000",
                centerLat: "41.02296500",
                centerLng: "29.02028500",
                radiusMeters: "1000",
                mapSnapshotUrl: nil,
                mapSnapshotCreatedAt: nil,
                status: "draft",
                createdBy: "1",
                createdAt: "2025-07-20 23:02:51",
                assignmentScheduleId: "49",
                assignmentScreenId: "1",
                assignmentEmployeeId: "7",
                assignmentOfferDescription: "Kadıköy merkez ve çevresinde mobil ekran reklamları. Toplam 5 nokta, yaklaşık 3 saat sürecek.",
                assignmentOfferBudget: "400.00",
                assignmentStatus: .pending,
                assignmentId: "31",
                assignmentCreatedAt: "2025-07-20 23:03:14"
            ),
            Assignment(
                id: "2",
                planId: "2",
                scheduleDate: "2025-07-25",
                startTime: "10:00:00",
                endTime: "15:00:00",
                routeType: "fixed_route",
                startLat: "0.00000000",
                startLng: "0.00000000",
                endLat: "0.00000000",
                endLng: "0.00000000",
                centerLat: "41.03553300",
                centerLng: "28.97588400",
                radiusMeters: "0",
                mapSnapshotUrl: nil,
                mapSnapshotCreatedAt: nil,
                status: "draft",
                createdBy: "1",
                createdAt: "2025-07-21 10:00:00",
                assignmentScheduleId: "50",
                assignmentScreenId: "2",
                assignmentEmployeeId: "8",
                assignmentOfferDescription: "Beşiktaş semtinde sabit ekran reklamları. Barbaros Bulvarı ve çevresi. 4 nokta, 2.5 saat.",
                assignmentOfferBudget: "350.00",
                assignmentStatus: .accepted,
                assignmentId: "32",
                assignmentCreatedAt: "2025-07-21 10:05:00"
            )
            // ... başka demo assignmentlar ekleyebilirsin
        ]
    }

    // Kullanıcı bilgisini sessiondan alıp rotaları yükler
    func loadAssignments() {
        guard let userId = SessionManager.shared.currentUser?.id else { return }
        SessionManager.shared.isLoading = true
        errorMessage = nil
        routeService.getAssignments(userId: userId, filters: ["type": "assignment"]) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(let assignments):
                    self.assignments = assignments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    // Kabul edilen rotalar (accepted routes)
    func loadRoutes() {
        guard let userId = SessionManager.shared.currentUser?.id else { return }
        SessionManager.shared.isLoading = true
        errorMessage = nil
        routeService.getAssignments(userId: userId, filters: ["type": "route"]) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(let assignments):
                    self.routes = assignments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Sadece bekleyen assignment'ları döndürür
    var pendingAssignments: [Assignment] {
        assignments.filter { $0.assignmentStatus == .pending }
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

    // MARK: - Assignment Action Functions
    func acceptAssignment(
        assignmentId: String,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        routeService.acceptAssignment(
            assignmentId: assignmentId
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(_):
                    completion(.success(true))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func rejectAssignment(
        assignmentId: String,
        reason: String?,
        completion: @escaping (Result<Bool, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        routeService.rejectAssignment(
            assignmentId: assignmentId,
            reason: reason
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                switch result {
                case .success(_):
                    completion(.success(true))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Supporting Enums

extension Encodable {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

// MARK: - Supporting Types

