import Foundation
import SwiftUI

class EmployeeViewModel: ObservableObject {
    @Published var employees: [User] = []
    @Published var selectedEmployees: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let employeeService = EmployeeService.shared
    
    // MARK: - Load Company Employees
    func loadCompanyEmployees() {
        guard let currentUser = SessionManager.shared.currentUser,
              let companyTaxNumber = currentUser.companyTaxNumber else {
            errorMessage = "Şirket vergi numarası bulunamadı"
            return
        }
        
        let userId = currentUser.id
        
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        employeeService.getCompanyEmployees(userId: userId,companyTaxNumber: companyTaxNumber) { [weak self] result in
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.status == "success", let data = response.data, let employees = data.employees {
                        self?.employees = employees
                    } else if let error = response.error {
                        self?.errorMessage = error.message
                    } else {
                        self?.errorMessage = "Çalışanlar yüklenirken bir hata oluştu"
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Employee Selection
    func toggleEmployeeSelection(_ employee: User) {
        if let index = selectedEmployees.firstIndex(where: { $0.id == employee.id }) {
            selectedEmployees.remove(at: index)
        } else {
            selectedEmployees.append(employee)
        }
    }
    
    func isEmployeeSelected(_ employee: User) -> Bool {
        return selectedEmployees.contains { $0.id == employee.id }
    }
    
    func clearSelection() {
        selectedEmployees.removeAll()
    }
    
    func selectAllEmployees() {
        selectedEmployees = employees
    }
    
    func deselectAllEmployees() {
        selectedEmployees.removeAll()
    }
    
    // MARK: - Get Selected Employee IDs
    func getSelectedEmployeeIds() -> [String] {
        return selectedEmployees.map { $0.id }
    }
    
    // MARK: - Get Selected Employee Names
    func getSelectedEmployeeNames() -> [String] {
        return selectedEmployees.map { $0.fullName }
    }
    
    // MARK: - Validation
    func hasSelectedEmployees() -> Bool {
        return !selectedEmployees.isEmpty
    }
    
    func getSelectedCount() -> Int {
        return selectedEmployees.count
    }
} 
