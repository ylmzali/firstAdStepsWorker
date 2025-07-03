import SwiftUI

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var path = NavigationPath()
    @Published var currentScreen: Screen = .splash
    @Published var isLoading = false
    
    enum Screen {
        case splash
        case phoneVerification
        case otpVerification(phoneNumber: String, countryCode: String, otpRequestId: String)
        case registration(phoneNumber: String, countryCode: String)
        case home
        case activeRoutesMap
    }
    
    enum Destination: Hashable {
        case splash
        case phoneVerification
        case otpVerification(phoneNumber: String, countryCode: String, otpRequestId: String)
        case registration(phoneNumber: String, countryCode: String)
        case home
        case activeRoutesMap
    }
    
    private init() {}
    
    // MARK: - Navigation Functions
    func goToSplash() {
        withAnimation {
            currentScreen = .splash
            path.removeLast(path.count)
        }
    }
    
    func goToPhoneVerification() {
        withAnimation {
            currentScreen = .phoneVerification
            path.append(Destination.phoneVerification)
        }
    }
    
    func goToOTPVerification(phoneNumber: String, countryCode: String, otpRequestId: String) {
        withAnimation {
            currentScreen = .otpVerification(phoneNumber: phoneNumber, countryCode: countryCode, otpRequestId: otpRequestId)
            path.append(Destination.otpVerification(phoneNumber: phoneNumber, countryCode: countryCode, otpRequestId: otpRequestId))
        }
    }
    
    func goToRegistration(phoneNumber: String, countryCode: String) {
        withAnimation {
            currentScreen = .registration(phoneNumber: phoneNumber, countryCode: countryCode)
            path.append(Destination.registration(phoneNumber: phoneNumber, countryCode: countryCode))
        }
    }
    
    func goToHome() {
        withAnimation {
            currentScreen = .home
            path.append(Destination.home)
        }
    }
    
    func goToActiveRoutesMap() {
        withAnimation {
            currentScreen = .activeRoutesMap
            path.append(Destination.activeRoutesMap)
        }
    }
    
    // MARK: - Loading State
    func startLoading() {
        isLoading = true
    }
    
    func stopLoading() {
        isLoading = false
    }
    
    // MARK: - Reset Navigation
    func resetNavigation() {
        withAnimation {
            currentScreen = .splash
            path.removeLast(path.count)
        }
    }
} 
