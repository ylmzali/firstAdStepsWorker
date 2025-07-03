import SwiftUI

struct RoutesView: View {
    @State private var showNewRoute = false
    @StateObject private var viewModel = RouteViewModel(
        routes: [],
        formVal: Route(
            id: UUID().uuidString,
            userId: SessionManager.shared.currentUser?.id ?? "",
            title: "",
            description: "",
            status: .request_received,
            assignedDate: nil,
            completion: 0,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    )
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var selectedRoute: Route?
    @State private var viewMode: ViewMode = .list // Varsayılan olarak gruplanmış görünüm

    // Görünüm modları
    enum ViewMode: String, CaseIterable {
        case list = "Liste"
        case grouped = "Gruplanmış"
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grouped: return "folder"
            }
        }
    }

    // Rotaları kategorilere ayıran computed property'ler
    private var activeRoutes: [Route] {
        viewModel.routes.filter { $0.status == .active }
    }
    
    private var pendingRoutes: [Route] {
        viewModel.routes.filter { 
            $0.status == .request_received || 
            $0.status == .plan_ready || 
            $0.status == .payment_pending ||
            $0.status == .plan_rejected
        }
    }
    
    private var completedRoutes: [Route] {
        viewModel.routes.filter { $0.status == .completed }
    }
    
    private var cancelledRoutes: [Route] {
        viewModel.routes.filter { $0.status == .cancelled }
    }
    
    private var paymentCompletedRoutes: [Route] {
        viewModel.routes.filter { $0.status == .payment_completed }
    }
    
    private var sharedRoutes: [Route] {
        viewModel.routes.filter { $0.shareWithEmployees }
    }
    
    private var myRoutes: [Route] {
        viewModel.routes.filter { !$0.shareWithEmployees }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        RouteViewHeaderStats(viewModel: viewModel)

                        // Görünüm Seçenekleri Butonları
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Button(action: { viewMode = mode }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: mode.icon)
                                                .font(.system(size: 16))
                                            Text(mode.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(viewMode == mode ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(viewMode == mode ? Color.white : Color.white.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                Spacer()
                            }
                            .padding()

                        }

                        if viewModel.routes.isEmpty {
                            emptyStateView
                        } else {
                            if viewMode == .list {
                                listViewContent
                            } else {
                                routeListContent
                            }
                        }
                    }
                }
                .refreshable {
                    viewModel.loadRoutes()
                }
                .scrollIndicators(.hidden)
                .tint(.white)
                .overlay(loadingOverlay)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    newRouteButton
                }
            }
            .navigationTitle("Reklamlar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .sheet(isPresented: $showNewRoute, onDismiss: {
                viewModel.resetForm()
                viewModel.loadRoutes()
            }) {
                // NewRouteSheet(viewModel: viewModel)
                NewRouteSheet(onRouteCreated: {
                    viewModel.loadRoutes()
                })
            }
            .sheet(item: $selectedRoute) { route in
                RouteDetailView(route: route)
            }
            .onAppear {
                viewModel.loadRoutes()
            }
            .overlay {
                if SessionManager.shared.isLoading {
                    LoadingView()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 6) {
            Image(systemName: "map")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 8)
            
            Text("Henüz bir reklam siparişiniz yok.")
                .font(.title3).bold()
                .foregroundColor(.white.opacity(0.7))
            
            Text("Yeni bir reklam siparişi oluşturmak için sağ üstteki  Yeni Reklam butonunu kullanabilirsiniz.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 12)
            
            Button(action: { showNewRoute = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Reklam")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .font(.headline)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            Button(action: { viewModel.loadRoutes() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward.circle.fill")
                    Text("Yenile")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .font(.headline)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 500)
        .padding(.top, 50)
    }
    
    private var routeListContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !activeRoutes.isEmpty {
                RouteCategorySection(
                    title: "Aktif Rotalar",
                    icon: "play.circle.fill",
                    color: .green,
                    routes: activeRoutes,
                    selectedRoute: $selectedRoute
                )
            }
            
            if !pendingRoutes.isEmpty {
                RouteCategorySection(
                    title: "Bekleyen Rotalar",
                    icon: "clock.circle.fill",
                    color: .orange,
                    routes: pendingRoutes,
                    selectedRoute: $selectedRoute
                )
            }
            
            if !sharedRoutes.isEmpty {
                RouteCategorySection(
                    title: "Şirket Çalışanlarıyla Paylaşılan",
                    icon: "person.2.circle.fill",
                    color: .blue,
                    routes: sharedRoutes,
                    selectedRoute: $selectedRoute
                )
            }
            
            if !completedRoutes.isEmpty {
                RouteCategorySection(
                    title: "Tamamlanan Rotalar",
                    icon: "checkmark.circle.fill",
                    color: .gray,
                    routes: completedRoutes,
                    selectedRoute: $selectedRoute
                )
            }
            
            if !paymentCompletedRoutes.isEmpty {
                RouteCategorySection(
                    title: "Ödeme Tamamlanan Rotalar",
                    icon: "creditcard.circle.fill",
                    color: .purple,
                    routes: paymentCompletedRoutes,
                    selectedRoute: $selectedRoute
                )
            }
            
            if !cancelledRoutes.isEmpty {
                RouteCategorySection(
                    title: "İptal Edilen Rotalar",
                    icon: "xmark.circle.fill",
                    color: .red,
                    routes: cancelledRoutes,
                    selectedRoute: $selectedRoute
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 30)
        .padding(.bottom, 100)
    }
    
    private var loadingOverlay: some View {
        Group {
            if SessionManager.shared.isLoading {
                VStack {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 40, height: 40)
                            )
                        Spacer()
                    }
                }
                .padding(.top, 20)
                Spacer()
            }
        }
    }
    
    private var newRouteButton: some View {
        Button(action: { showNewRoute = true }) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                Text("Yeni Oluştur")
            }
            .foregroundColor(.white)
        }
    }
    
    private var listViewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Başlık
            HStack {
                Text("Tüm Reklamlar")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.routes.count) reklam")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            
            // Liste
            LazyVStack(spacing: 12) {
                ForEach(viewModel.routes.sorted { $0.createdAt > $1.createdAt }) { route in
                    RouteRowView(route: route)
                        .onTapGesture {
                            selectedRoute = route
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    RoutesView()
}
