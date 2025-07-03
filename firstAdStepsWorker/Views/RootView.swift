import SwiftUI

struct RootView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            destinationView(for: navigationManager.currentScreen)
                .navigationDestination(for: NavigationManager.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationManager.Destination) -> some View {
        switch destination {
        case .splash:
            SplashView()
        case .phoneVerification:
            PhoneVerificationView()
        case .otpVerification(let phoneNumber, let countryCode, let otpRequestId):
            OTPView(phoneNumber: phoneNumber, countryCode: countryCode, otpRequestId: otpRequestId)
        case .registration(let phoneNumber, let countryCode):
            RegisterFormView(phoneNumber: phoneNumber, countryCode: countryCode)
        case .home:
            HomeView()
        case .activeRoutesMap:
            ActiveRoutesMapView(viewModel: ActiveRoutesViewModel())
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: NavigationManager.Screen) -> some View {
        switch screen {
        case .splash:
            SplashView()
        case .phoneVerification:
            PhoneVerificationView()
        case .otpVerification(let phoneNumber, let countryCode, let otpRequestId):
            OTPView(phoneNumber: phoneNumber, countryCode: countryCode, otpRequestId: otpRequestId)
        case .registration(let phoneNumber, let countryCode):
            RegisterFormView(phoneNumber: phoneNumber, countryCode: countryCode)
        case .home:
            HomeView()
        case .activeRoutesMap:
            ActiveRoutesMapView(viewModel: ActiveRoutesViewModel())
        }
    }
}

protocol NavigationDestination {}

extension NavigationManager.Screen: NavigationDestination {}
extension NavigationManager.Destination: NavigationDestination {}

#Preview {
    RootView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
        .environmentObject(CentralErrorManager.shared)
        .environmentObject(LogManager.shared)
} 
