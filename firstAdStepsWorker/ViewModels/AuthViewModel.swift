import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    func requestOTP(
        phoneNumber: String,
        countryCode: String,
        completion: @escaping (Result<OTPData, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        /*
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
         */
        
        authService.requestOTP(
            phoneNumber: phoneNumber, 
            countryCode: countryCode
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {

                SessionManager.shared.isLoading = false
                
                switch result {
                case .success(let response):
                    if response.status == "success",
                        let data = response.data,
                        !data.otpRequestId.isEmpty {
                        completion(.success(data))
                    } else if let error = response.error {
                        self.errorMessage = error.message
                        completion(.failure(.custom(message: error.message)))
                    } else {
                        self.errorMessage = "OTP gönderilemedi"
                        completion(.failure(.invalidData))
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func verifyOTP(
        phoneNumber: String,
        countryCode: String,
        otpRequestId: String,
        otpCode: String,
        completion: @escaping (Result<OTPVerifyData, ServiceError>) -> Void
    ) {
        SessionManager.shared.isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                SessionManager.shared.isLoading = false
            }
        }
        
        authService.verifyOTP(
            phoneNumber: phoneNumber,
            countryCode: countryCode,
            otpRequestId: otpRequestId,
            otpCode: otpCode
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.status == "success", let data = response.data {
                        if let user = data.user, data.isUserExist == true {
                            SessionManager.shared.setUser(user)
                        }
                        completion(.success(data))
                    } else if let error = response.error {
                        self.errorMessage = error.message
                        completion(.failure(.custom(message: error.message)))
                    } else {
                        self.errorMessage = "Doğrulama başarısız"
                        completion(.failure(.invalidData))
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
} 
