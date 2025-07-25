import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showSearch = false
    @State private var searchText = ""
    @ObservedObject var appState = AppStateManager.shared
    
    private let tabBarItems: [(icon: String, label: String)] = [
        ("Home", "GİRİŞ"),
        ("Offer", "TEKLİFLER"),
        ("Marker", "ROTALAR"),
        ("Profile", "PROFİL")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0: MainView()
                case 1: AssignmentListView()
                case 2: RoutesView()
                case 3: ProfileView()
                default: MainView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            CustomTabBar(selectedTab: $selectedTab, tabBarItems: tabBarItems)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .modifier(NotificationHandlers(selectedTab: $selectedTab))
        .preferredColorScheme(.light)
    }
}

struct NotificationHandlers: ViewModifier {
    @Binding var selectedTab: Int
    
    func body(content: Content) -> some View {
        content
            // Backend'den gelen bildirimleri dinle
            .onReceive(NotificationCenter.default.publisher(for: .adRequestPlanReadyTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Reklam Planı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .routeStartedTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Rota Başladı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .routeCompletedTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Rota Tamamlandı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .reportReadyTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Rapor Hazır")
            }
            .onReceive(NotificationCenter.default.publisher(for: .paymentPendingTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Ödeme Bekliyor")
            }
            // Push notification'ları dinle
            .onReceive(NotificationCenter.default.publisher(for: .adRequestPlanReadyReceived)) { notification in
                handlePushNotification(notification: notification, type: "Reklam Planı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .routeStartedReceived)) { notification in
                handlePushNotification(notification: notification, type: "Rota Başladı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .routeCompletedReceived)) { notification in
                handlePushNotification(notification: notification, type: "Rota Tamamlandı")
            }
            .onReceive(NotificationCenter.default.publisher(for: .reportReadyReceived)) { notification in
                handlePushNotification(notification: notification, type: "Rapor Hazır")
            }
            .onReceive(NotificationCenter.default.publisher(for: .paymentPendingReceived)) { notification in
                handlePushNotification(notification: notification, type: "Ödeme Bekliyor")
            }
            .onReceive(NotificationCenter.default.publisher(for: .readyToStartReceived)) { notification in
                handlePushNotification(notification: notification, type: "Başlamaya Hazır")
            }
            // Geriye uyumluluk için eski bildirimler
            .onReceive(NotificationCenter.default.publisher(for: .routeNotificationTapped)) { notification in
                handleNotificationTap(notification: notification, tab: 2, type: "Genel Rota")
            }
            .onReceive(NotificationCenter.default.publisher(for: .routeNotificationReceived)) { notification in
                handlePushNotification(notification: notification, type: "Rota Güncellendi")
            }
            // Deep link handling
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkToRoute)) { notification in
                handleDeepLink(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToRoute)) { notification in
                handleNavigateToRoute(notification: notification)
            }
            // Tab navigation
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTab)) { notification in
                handleTabNavigation(notification: notification)
            }
    }
    
    // MARK: - Notification Handlers
    private func handleNotificationTap(notification: Notification, tab: Int, type: String) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("\(type) bildirimi tıklandı, routeId: \(routeId)")
            selectedTab = tab // Rotalar tab'ına git
            // TODO: Belirli rotayı açmak için ek işlemler yapılabilir
        }
    }
    
    private func handlePushNotification(notification: Notification, type: String) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("Push notification: \(type), routeId: \(routeId)")
            // Bildirimler tab'ına git ve kullanıcıya göster
            selectedTab = 3 // Bildirimler tab'ı
        }
    }
    
    private func handleDeepLink(notification: Notification) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("🔗 HomeView: Deep link işleniyor - Route ID: \(routeId)")
            // Rotalar tab'ına git ve route'u göster
            selectedTab = 2
            // TODO: Belirli route'u açmak için ek işlemler
        }
    }
    
    private func handleNavigateToRoute(notification: Notification) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("🔗 HomeView: Route'a yönlendiriliyor - Route ID: \(routeId)")
            // Rotalar tab'ına git ve route'u göster
            selectedTab = 2
            // TODO: Belirli route'u açmak için ek işlemler
        }
    }
    
    private func handleTabNavigation(notification: Notification) {
        if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
            print("🔗 HomeView: Tab navigation - Tab Index: \(tabIndex)")
            selectedTab = tabIndex
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
        .environmentObject(AppStateManager.shared)
} 
