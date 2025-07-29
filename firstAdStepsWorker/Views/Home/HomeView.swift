import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var showActiveTrackingWidget = false
    @State private var activeTrackingInfo: ActiveTrackingInfo?
    @State private var showDebugView = false
    @State private var showInfoSheet = false
    @State private var route: Assignment?
    @State private var totalDistance: Double = 0
    @State private var averageSpeed: Double = 0
    @State private var isRouteActive: Bool = false
    @State private var routeLocations: [LocationData] = []
    @ObservedObject var appState = AppStateManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    
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
            
            // Aktif Tracking Widget
            if showActiveTrackingWidget {
                VStack {
                    Spacer()
                    ActiveTrackingWidget(
                        trackingInfo: activeTrackingInfo,
                        onTap: {
                            // Aktif tracking varsa direkt haritayı aç
                            openActiveTrackingMap()
                        }
                    )
                    .padding(.bottom, 100) // Tab bar'ın üstünde
                }
            }
            
            // Debug Widget (sadece development'ta göster)
            #if DEBUG
            VStack {
                Spacer()
                DebugWidget {
                    showDebugView = true
                }
                .padding(.bottom, 160) // Active tracking widget'ın üstünde
            }
            #endif
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .modifier(NotificationHandlers(selectedTab: $selectedTab))
        .preferredColorScheme(.light)
        .overlay {
            if SessionManager.shared.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            checkActiveTracking()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkStatusUpdated"))) { _ in
            checkActiveTracking()
        }
        .fullScreenCover(isPresented: $showInfoSheet) {
            if let route = route {
                RouteInfoSheet(route: route, totalDistance: totalDistance, averageSpeed: averageSpeed, isRouteActive: isRouteActive, routeLocations: routeLocations)
            }
        }
        .sheet(isPresented: $showDebugView) {
            DebugView()
        }
    }
    
    private func checkActiveTracking() {
        if let info = locationManager.loadActiveTrackingInfo(),
           (info.status == "working" || info.status == "paused") && !info.isExpired {
            activeTrackingInfo = info
            showActiveTrackingWidget = true
        } else {
            showActiveTrackingWidget = false
            activeTrackingInfo = nil
        }
    }
    
    private func openActiveTrackingMap() {
        // Aktif tracking bilgilerini al
        guard let trackingInfo = activeTrackingInfo else {
            print("❌ [HomeView] Aktif tracking bilgisi bulunamadı")
            return
        }
        
        print("🗺️ [HomeView] Aktif tracking haritası açılıyor")
        print("🗺️ [HomeView] Assignment ID: \(trackingInfo.assignmentId)")
        
        // Routes sayfasına git ve aktif route'u bul
        selectedTab = 2
        
        // Kısa bir gecikme ile aktif route'u bul ve haritayı aç
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.findAndOpenActiveRoute(trackingInfo: trackingInfo)
        }
    }
    
    private func findAndOpenActiveRoute(trackingInfo: ActiveTrackingInfo) {
        // RoutesView'da aktif route'u bulmak için notification gönder
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenActiveRoute"),
            object: nil,
            userInfo: [
                "assignment_id": trackingInfo.assignmentId,
                "schedule_id": trackingInfo.routeId
            ]
        )
    }
}

// MARK: - Active Tracking Widget
struct ActiveTrackingWidget: View {
    let trackingInfo: ActiveTrackingInfo?
    let onTap: () -> Void
    
    private func formatRemainingTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours) saat \(remainingMinutes) dakika"
            } else {
                return "\(hours) saat"
            }
        } else {
            return "\(minutes) dakika"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Animasyonlu ikon - Pulse efekti
                ZStack {
                    // Pulse arka plan
                    Circle()
                        .fill(Theme.primary.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: true
                        )
                    
                    // Ana ikon
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .overlay(
                            // İç ikon (nokta)
                            Circle()
                                .fill(Theme.primary)
                                .frame(width: 6, height: 6)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rota Takibi Aktif")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let info = trackingInfo {
                        Text("Kalan: \(formatRemainingTime(info.remainingMinutes))")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.primary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .buttonStyle(PlainButtonStyle())
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
            print("\(type) bildirimi tıklandı, scheduleId: \(routeId)")
            selectedTab = tab // Rotalar tab'ına git
            // TODO: Belirli rotayı açmak için ek işlemler yapılabilir
        }
    }
    
    private func handlePushNotification(notification: Notification, type: String) {
        if let routeId = notification.userInfo?["routeId"] as? String {
            print("Push notification: \(type), scheduleId: \(routeId)")
            // Bildirimler tab'ına git ve kullanıcıya göster
            selectedTab = 3 // Bildirimler tab'ı
        }
    }
    

    
    private func handleNavigateToRoute(notification: Notification) {
        if let routeId = notification.userInfo?["routeId"] as? String {
    
            // Rotalar tab'ına git ve route'u göster
            selectedTab = 2
            // TODO: Belirli route'u açmak için ek işlemler
        }
    }
    
    private func handleTabNavigation(notification: Notification) {
        if let tabIndex = notification.userInfo?["tabIndex"] as? Int {
    
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
