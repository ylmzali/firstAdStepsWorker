//
//  CentralErrorManager.swift
//  firstAdSteps
//
//  Created by Ali YILMAZ on 2.06.2025.
//

import SwiftUI
import Combine

class CentralErrorManager: ObservableObject {
    static let shared = CentralErrorManager()
    
    @Published var currentError: ErrorMessage?
    @Published var showError = false
    
    private init() {}
    
    func handle(error: Error) {
        let message: String
        
        if let serviceError = error as? ServiceError {
            message = serviceError.userMessage
        } else if let networkError = error as? NetworkError {
            message = networkError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        DispatchQueue.main.async {
            self.currentError = ErrorMessage(message: message)
            self.showError = true
        }
    }
    
    func clearError() {
        currentError = nil
        showError = false
    }
}

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorManager: CentralErrorManager
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorManager.showError) {
                Alert(
                    title: Text("Hata"),
                    message: Text(errorManager.currentError?.message ?? "Bilinmeyen bir hata oluştu"),
                    dismissButton: .default(Text("Tamam")) {
                        errorManager.clearError()
                    }
                )
            }
    }
}

extension View {
    func errorAlert(errorManager: CentralErrorManager) -> some View {
        modifier(ErrorAlertModifier(errorManager: errorManager))
    }
}
