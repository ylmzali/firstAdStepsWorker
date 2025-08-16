import Foundation
import Combine

class WorkerStatsService: ObservableObject {
    static let shared = WorkerStatsService()
    
    private let baseURL = AppConfig.baseURL
    private var cancellables = Set<AnyCancellable>()
    
    @Published var workerStats: WorkerStatsData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchWorkerStats() {
        guard let employeeId = SessionManager.shared.currentUser?.id else {
            errorMessage = "Kullanıcı bilgisi bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let urlString = "\(baseURL)\(AppConfig.Endpoints.getWorkerStats)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Geçersiz URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Auth token ekle
        if let token = SessionManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WorkerStatsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "İstatistikler yüklenirken hata oluştu: \(error.localizedDescription)"
                        print("❌ [WorkerStatsService] Hata: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.workerStats = response.data
                    print("✅ [WorkerStatsService] İstatistikler başarıyla yüklendi")
                    print("📊 [WorkerStatsService] Toplam atanan: \(response.data.periodInfo.totalAssignedSchedules)")
                    print("📊 [WorkerStatsService] Tamamlanan: \(response.data.periodInfo.completedSchedules)")
                    print("📊 [WorkerStatsService] Toplam kazanç: ₺\(response.data.financialMetrics.totalEarned)")
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshStats() {
        fetchWorkerStats()
    }
}
