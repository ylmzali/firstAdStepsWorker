//
//  firstAdStepsWorkerApp.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 13.06.2025.
//

import SwiftUI

@main
struct firstAdStepsWorkerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var errorManager = CentralErrorManager.shared
    @StateObject private var logManager = LogManager.shared
    @StateObject private var appStateManager = AppStateManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var navigationPath = NavigationPath()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionManager)
                .environmentObject(navigationManager)
                .environmentObject(errorManager)
                .environmentObject(logManager)
                .environmentObject(appStateManager)
                .environmentObject(notificationManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    // Uygulama kapatılmadan önce son temizlik işlemleri
                }
                .onChange(of: sessionManager.isAuthenticated) { newValue in
                    if !newValue {
                        // Oturum kapandığında navigation stack'i temizle ve OTP'ye yönlendir
                        navigationPath.removeLast(navigationPath.count)
                        navigationManager.goToPhoneVerification()
                    }
                }
        }
    }
}
