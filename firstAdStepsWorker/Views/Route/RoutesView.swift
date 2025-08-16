import SwiftUI

struct RoutesView: View {
    @StateObject private var viewModel = RouteViewModel(routes: [])
    @EnvironmentObject private var navigationManager: NavigationManager
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var locationManager = LocationManager.shared
    @State private var selectedRoute: Assignment?
    // Filtre ve arama ile ilgili state'ler kaldırıldı
    
    var body: some View {
        NavigationView {
            routesTabView
                .navigationTitle("Rotalarım")
                .navigationBarTitleDisplayMode(.large)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.white, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: refreshRoutes) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                .fullScreenCover(item: $selectedRoute) { route in
                    RouteTrackingView(route: route)
                }
                .onAppear {
                    setupWorkStatusObserver()
                    setupActiveRouteObserver()
                }
                .onDisappear {
                    removeWorkStatusObserver()
                    removeActiveRouteObserver()
                }
        }
    }
    
    private func setupWorkStatusObserver() {
        // Work status güncellemelerini dinle
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkStatusUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let assignmentId = userInfo["assignment_id"] as? String,
               let status = userInfo["status"] as? String {
                
                print("🔄 [RoutesView] Work status güncellendi - Assignment ID: \(assignmentId), Status: \(status)")
                
                // Rotaları yenile
                DispatchQueue.main.async {
                    self.refreshRoutes()
                }
            }
        }
    }
    
    private func removeWorkStatusObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("WorkStatusUpdated"), object: nil)
    }
    
    private func removeActiveRouteObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("OpenActiveRoute"), object: nil)
    }
    
    private func setupActiveRouteObserver() {
        // Aktif route açma notification'ını dinle
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenActiveRoute"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let assignmentId = userInfo["assignment_id"] as? String {
                self.openActiveRoute(assignmentId: assignmentId)
            }
        }
    }
    
    private func openActiveRoute(assignmentId: String) {
        print("🔍 [RoutesView] Aktif route aranıyor - Assignment ID: \(assignmentId)")
        
        // Route'lar yüklendiyse hemen ara
        if !viewModel.routes.isEmpty {
            findAndOpenRoute(assignmentId: assignmentId)
        } else {
            // Route'lar henüz yüklenmemişse, yüklendikten sonra ara
            print("⏳ [RoutesView] Route'lar henüz yüklenmemiş, bekleniyor...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.findAndOpenRoute(assignmentId: assignmentId)
            }
        }
    }
    
    private func findAndOpenRoute(assignmentId: String) {
        print("🔍 [RoutesView] Route listesinde arama yapılıyor...")
        
        if let activeRoute = viewModel.routes.first(where: { $0.assignmentId == assignmentId }) {
            print("✅ [RoutesView] Aktif route bulundu: \(activeRoute.id)")
            selectedRoute = activeRoute
        } else {
            print("❌ [RoutesView] Aktif route bulunamadı - Assignment ID: \(assignmentId)")
            print("📋 [RoutesView] Mevcut route'lar: \(viewModel.routes.map { "\($0.id) (\($0.assignmentId))" })")
        }
    }
    

    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.purple400))
            Text("Rotalar Yükleniyor...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.gray800)
            Text("Bekleyen atamalarınız kontrol ediliyor")
                .font(.body)
                .foregroundColor(Theme.gray600)
                .multilineTextAlignment(.center)
            Button(action: cancelLoading) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16, weight: .medium))
                    Text("İptal Et")
                        .fontWeight(.medium)
                }
                .foregroundColor(Theme.gray600)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.gray200)
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(Theme.gray400)
            Text("Bekleyen Atama Yok")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Theme.gray800)
            Text("Şu anda size atanmış bekleyen rota bulunmuyor. Yeni atamalar geldiğinde burada görünecek.")
                .font(.body)
                .foregroundColor(Theme.gray600)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: refreshRoutes) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                    Text("Yenile")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.purple400)
                .cornerRadius(8)
            }
        }
        .padding()
        .padding(.bottom,100)
    }
    
    private var routesTabView: some View {
        ZStack {
            Theme.gray100.ignoresSafeArea()
            if viewModel.isLoading {
                loadingView
            } else if viewModel.routes.isEmpty {
                emptyStateView
            } else {
                routeListView
            }
        }
        .refreshable {
            refreshRoutes()
        }
        .onAppear {
            loadRoutes()
        }
    }
    
    private var routeListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Aktif Rotalar (Çalışan ve Duraklatılan)
                let activeRoutes = myRoutes.filter { 
                    $0.workStatus == "working" || $0.workStatus == "paused" 
                }
                
                if !activeRoutes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aktif Rotalar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.gray800)
                            .padding(.leading, 16)
                        LazyVStack(spacing: 12) {
                            ForEach(activeRoutes) { route in
                                RouteCard(route: route) {
                                    selectedRoute = route
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 30)
                }

                // Tamamlanan Rotalar
                let completedRoutes = myRoutes.filter { 
                    $0.workStatus == "completed" 
                }
                
                if !completedRoutes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tamamlanan Rotalar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.gray800)
                            .padding(.leading, 16)
                        LazyVStack(spacing: 12) {
                            ForEach(completedRoutes) { route in
                                RouteCard(route: route) {
                                    selectedRoute = route
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.top, 30)
                }
                
                if activeRoutes.isEmpty && completedRoutes.isEmpty {
                    emptyStateView
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100) // TabBar için daha fazla boşluk
        }
    }
    
    private func loadRoutes() {
        viewModel.loadRoutes()
    }
    
    private func refreshRoutes() {
        loadRoutes()
    }
    
    private func cancelLoading() {
        viewModel.isLoading = false
        SessionManager.shared.isLoading = false
    }

    // Only show accepted assignments (rotalarım)
    private var myRoutes: [Assignment] {
        viewModel.routes.filter { $0.assignmentStatus == .accepted }
    }
}

#Preview {
    RoutesView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
        .environmentObject(AppStateManager.shared)
        .environmentObject(LocationManager.shared)
} 
