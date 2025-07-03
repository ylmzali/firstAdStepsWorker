import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showSearch = false
    @State private var searchText = ""
    @ObservedObject var appState = AppStateManager.shared
    
    var body: some View {
        ZStack {
            // Content View
            TabContentView(selectedTab: $selectedTab)
            
            // Custom Tab Bar - Absolute positioned at bottom
            VStack {
                Spacer()
                if !appState.tabBarHidden {
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .navigationBarHidden(true)
        // Backend'den gelen bildirimleri dinle
        .onReceive(NotificationCenter.default.publisher(for: .adRequestPlanReadyTapped)) { notification in
            handleNotificationTap(notification: notification, tab: 1, type: "Reklam Planı")
        }
        .onReceive(NotificationCenter.default.publisher(for: .routeStartedTapped)) { notification in
            handleNotificationTap(notification: notification, tab: 1, type: "Rota Başladı")
        }
        .onReceive(NotificationCenter.default.publisher(for: .routeCompletedTapped)) { notification in
            handleNotificationTap(notification: notification, tab: 1, type: "Rota Tamamlandı")
        }
        .onReceive(NotificationCenter.default.publisher(for: .reportReadyTapped)) { notification in
            handleNotificationTap(notification: notification, tab: 1, type: "Rapor Hazır")
        }
        .onReceive(NotificationCenter.default.publisher(for: .paymentPendingTapped)) { notification in
            handleNotificationTap(notification: notification, tab: 1, type: "Ödeme Bekliyor")
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
            handleNotificationTap(notification: notification, tab: 1, type: "Genel Rota")
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
    }
    
    // MARK: - Notification Handlers
    
    private func handleNotificationTap(notification: Notification, tab: Int, type: String) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("\(type) bildirimi tıklandı, routeId: \(routeId)")
            selectedTab = tab // Reklamlar tab'ına git
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
            // Reklamlar tab'ına git ve route'u göster
            selectedTab = 1
            // TODO: Belirli route'u açmak için ek işlemler
        }
    }
    
    private func handleNavigateToRoute(notification: Notification) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("🔗 HomeView: Route'a yönlendiriliyor - Route ID: \(routeId)")
            // Reklamlar tab'ına git ve route'u göster
            selectedTab = 1
            // TODO: Belirli route'u açmak için ek işlemler
        }
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                MainView(selectedTab: $selectedTab)
            case 1:
                RoutesView()
            case 2:
                // Harita tab'ına tıklandığında NavigationManager'ı kullan
                Color.clear
                    .onAppear {
                        navigationManager.goToActiveRoutesMap()
                    }
            case 3:
                NotificationListView()
            case 4:
                ProfileView()
            default:
                MainView(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        HStack(spacing: 0) {
            CustomTabButton(
                title: "Ana Sayfa",
                icon: "house",
                isSelected: selectedTab == 0
            ) {
                // withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = 0
                // }
            }
            
            CustomTabButton(
                title: "Reklamlar",
                icon: "cart",
                isSelected: selectedTab == 1
            ) {
                    selectedTab = 1
            }
            
            CustomTabButton(
                title: "Harita",
                icon: "map",
                isSelected: selectedTab == 2
            ) {
                    selectedTab = 2
            }
            
            CustomTabButton(
                title: "Bildirimler",
                icon: "bell",
                isSelected: selectedTab == 3
            ) {
                    selectedTab = 3
            }
            
            CustomTabButton(
                title: "Profil",
                icon: "person",
                isSelected: selectedTab == 4
            ) {
                    selectedTab = 4
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
        .background(Color.clear)
    }
}

// MARK: - Custom Tab Button
struct CustomTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .shadow(color: Color.white.opacity(0.15), radius: 15, x: 0, y: -5)

                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                    .shadow(color: Color.white.opacity(0.15), radius: 15, x: 0, y: -5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.clear.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Original TabView (Commented Out)
/*
struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showSearch = false
    @State private var searchText = ""
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            MainView(selectedTab: $selectedTab)
                .tabItem {
                    // Image(selectedTab == 0 ? "HomeHover" : "Home")
                    Image(systemName: selectedTab == 2 ? "house" : "house")
                    Text("Ana Sayfa")
                }
                .tag(0)
            
            // Siparişler
            RoutesView()
                .tabItem {
                    // Image(selectedTab == 1 ? "BuyHover" : "Buy")
                    Image(systemName: selectedTab == 2 ? "cart" : "cart")
                    Text("Siparişler")
                }
                .tag(1)
            
            // Bildirimler
            NotificationsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "heart" : "heart")
                    Text("Bildirimler")
                }
                .tag(2)
            
            // Profil
            ProfileView()
                .tabItem {
                    // Image(selectedTab == 3 ? "ProfileHover" : "Profile")
                    Image(systemName: selectedTab == 2 ? "person" : "person")
                    Text("Profil")
                }
                .tag(3)
        }
        .tint(Color.white)
        .navigationBarHidden(true)
    }
}
*/

#Preview {
    HomeView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
} 
