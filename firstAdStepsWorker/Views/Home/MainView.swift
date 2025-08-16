import SwiftUI

struct MainView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var routeViewModel = RouteViewModel()
    // @StateObject private var workerStatsService = WorkerStatsService.shared // Geçici olarak devre dışı
    @State private var currentTime = Date()
    @State private var selectedAssignment: Assignment?
    @State private var isLoadingPendingAssignments = false
    @State private var showNotifications = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Geçici istatistikler (API entegrasyonu sonrası gerçek verilerle değiştirilecek)
    private var todayRoutes: Int {
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: today)
        
        let todayAssignments = routeViewModel.assignments.filter { assignment in
            // Assignment'ın bugün planlandığını kontrol et (scheduleDate)
            return assignment.scheduleDate == todayString
        }.count
        
        return todayAssignments
    }
    
    private var completedRoutes: Int {
        let completedAssignments = routeViewModel.assignments.filter { assignment in
            assignment.assignmentWorkStatus == .completed
        }.count
        
        return completedAssignments
    }
    
    private var pendingRoutes: Int {
        return routeViewModel.pendingAssignments.count
    }
    
    private var activeRoutes: Int {
        // Aktif rotaları hesapla (çalışan ve duraklatılan rotalar)
        let activeAssignments = routeViewModel.assignments.filter { assignment in
            assignment.assignmentWorkStatus == .working || assignment.assignmentWorkStatus == .paused
        }.count
        
        return activeAssignments
    }
    
    private var totalEarnings: Double {
        return 1250.0 // Geçici değer
    }
    
    private var todayEarnings: Double {
        return 450.0 // Geçici değer
    }
    
    private var weeklyEarnings: Double {
        return 850.0 // Geçici değer
    }
    
    private var totalDistance: Double {
        return 45.2 // Geçici değer
    }
    
    private var averageSpeed: Double {
        return 3.2 // Geçici değer
    }
    
    private var maxSpeed: Double {
        return 8.5 // Geçici değer
    }
    
    private var totalWorkHours: Double {
        return 24.5 // Geçici değer
    }
    
    private var averagePerHour: Double {
        return 51.02 // Geçici değer
    }
    
    private var averageBattery: Double {
        return 78.5 // Geçici değer
    }
    
    private var averageSignal: Double {
        return 4.2 // Geçici değer
    }
    
    var body: some View {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Onay Bekleyen Görevler (Öncelikli)
                    if routeViewModel.isLoading {
                        pendingAssignmentsLoadingSection
                    } else if !routeViewModel.pendingAssignments.isEmpty {
                        pendingAssignmentsSection
                    } else {
                        pendingAssignmentsEmptySection
                    }

                    // Günlük Özet Kartları
                    dailySummaryCards
                    
                    // Detaylı İstatistikler
                    detailedStatsSection
                    
                    // Cihaz İstatistikleri
                    deviceStatsSection
                    
                    // Hızlı Erişim
                    // quickAccessSection
                    
                    // Son Aktiviteler
                    // recentActivitiesSection
                    
                    Spacer(minLength: 200)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Theme.gray100)
            .navigationBarTitleDisplayMode(.large)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkStatusUpdated"))) { _ in
                routeViewModel.loadAssignments()
            }
            .onAppear {
                routeViewModel.loadAssignments()
            }
            .refreshable {
                routeViewModel.loadAssignments()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationListView()
            }
            .sheet(item: $selectedAssignment) { assignment in
                AssignmentDetailView(assignment: assignment) { _ in
                    routeViewModel.loadAssignments()
                }
            }
            .preferredColorScheme(.light)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Merhaba,")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(sessionManager.currentUser?.fullName ?? "Çalışan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Bildirim ikonu
                Button(action: {
                    showNotifications = true
                }) {
                    Image(systemName: "bell")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
                }
            }
            
            // Zaman bilgisi
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Text(timeString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var dailySummaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Bugünkü Rotalar
            StatCard(
                title: "Bugünkü Rotalar",
                value: "\(todayRoutes)",
                subtitle: "Toplam atanan",
                icon: "map",
                color: Theme.purple400
            )
            
            // Aktif Rotalar
            StatCard(
                title: "Aktif Rotalar",
                value: "\(activeRoutes)",
                subtitle: "Şu anda çalışan",
                icon: "location.fill",
                color: Theme.success
            )
            
            // Tamamlanan Rotalar
            StatCard(
                title: "Tamamlanan",
                value: "\(completedRoutes)",
                subtitle: "Toplam tamamlanan",
                icon: "checkmark.circle",
                color: Theme.green400
            )
            
            // Bekleyen Rotalar
            StatCard(
                title: "Bekleyen",
                value: "\(pendingRoutes)",
                subtitle: "Onay bekleyen",
                icon: "clock",
                color: Theme.warning
            )
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detaylı İstatistikler")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Günlük Kazanç
                StatCard(
                    title: "Günlük Kazanç",
                    value: "₺\(Int(todayEarnings))",
                    subtitle: "Bugün kazanılan",
                    icon: "banknote",
                    color: Theme.accentPink
                )
                
                // Haftalık Kazanç
                StatCard(
                    title: "Haftalık Kazanç",
                    value: "₺\(Int(weeklyEarnings))",
                    subtitle: "Bu hafta kazanılan",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Theme.accentYellow
                )
                
                // Toplam Kazanç
                StatCard(
                    title: "Toplam Kazanç",
                    value: "₺\(Int(totalEarnings))",
                    subtitle: "Tüm zamanlar",
                    icon: "creditcard",
                    color: Theme.primary
                )
                
                // Saatlik Ortalama
                StatCard(
                    title: "Saatlik Ortalama",
                    value: "₺\(Int(averagePerHour))",
                    subtitle: "Saat başına kazanç",
                    icon: "clock.arrow.circlepath",
                    color: Theme.green400
                )
                
                // Toplam Mesafe
                StatCard(
                    title: "Toplam Mesafe",
                    value: "\(Int(totalDistance)) km",
                    subtitle: "Kat edilen mesafe",
                    icon: "speedometer",
                    color: Theme.blue400
                )
                
                // Ortalama Hız
                StatCard(
                    title: "Ortalama Hız",
                    value: "\(Int(averageSpeed)) km/h",
                    subtitle: "Ortalama seyahat hızı",
                    icon: "gauge",
                    color: Theme.orange400
                )
                
                // Maksimum Hız
                StatCard(
                    title: "Maksimum Hız",
                    value: "\(Int(maxSpeed)) km/h",
                    subtitle: "En yüksek hız",
                    icon: "speedometer",
                    color: Theme.red400
                )
                
                // Toplam Çalışma Saati
                StatCard(
                    title: "Toplam Çalışma",
                    value: "\(Int(totalWorkHours)) saat",
                    subtitle: "Toplam çalışma süresi",
                    icon: "clock",
                    color: Theme.purple400
                )
            }
        }
    }
    
    private var statsLoadingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.primary))
            
            Text("İstatistikler yükleniyor...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Çalışan performans verileri getiriliyor")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var deviceStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cihaz İstatistikleri")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Ortalama Batarya
                StatCard(
                    title: "Ortalama Batarya",
                    value: "\(Int(averageBattery))%",
                    subtitle: "Cihaz batarya seviyesi",
                    icon: "battery.75",
                    color: Theme.green400
                )
                
                // Ortalama Sinyal
                StatCard(
                    title: "Ortalama Sinyal",
                    value: "\(Int(averageSignal))/5",
                    subtitle: "GPS sinyal gücü",
                    icon: "antenna.radiowaves.left.and.right",
                    color: Theme.blue400
                )
                
                // Toplam Oturum
                StatCard(
                    title: "Toplam Oturum",
                    value: "150",
                    subtitle: "Toplam çalışma oturumu",
                    icon: "person.2.circle",
                    color: Theme.purple400
                )
                
                // Aktif Oturum
                StatCard(
                    title: "Aktif Oturum",
                    value: "12",
                    subtitle: "Şu anda aktif oturum",
                    icon: "person.2.circle.fill",
                    color: Theme.accentPink
                )
            }
        }
    }
    
    private var errorSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("İstatistik Hatası")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "info.circle")
                        .foregroundColor(Theme.gray500)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bilinmeyen hata")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.gray700)
                        
                        Text("İstatistikler yüklenirken bir sorun oluştu")
                            .font(.caption)
                            .foregroundColor(Theme.gray500)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Theme.gray100)
                .cornerRadius(12)
                
                Button(action: {
                    // workerStatsService.refreshStats() // Geçici olarak devre dışı
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Tekrar Dene")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .orange.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hızlı Erişim")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickAccessButton(
                    title: "Rotalarım",
                    subtitle: "Atanan rotaları gör",
                    icon: "list.bullet",
                    color: Theme.purple400
                ) {
                    NotificationCenter.default.post(
                        name: .navigateToTab,
                        object: nil,
                        userInfo: ["tabIndex": 2]
                    )
                }
                
                QuickAccessButton(
                    title: "Konum Takibi",
                    subtitle: "Aktif rota takibi",
                    icon: "location",
                    color: Theme.success
                ) {
                    // Konum takibi başlat
                }
                
                QuickAccessButton(
                    title: "Raporlar",
                    subtitle: "Günlük raporlar",
                    icon: "chart.bar",
                    color: Theme.accentYellow
                ) {
                    // Raporlar sayfası
                }
                
                QuickAccessButton(
                    title: "Ayarlar",
                    subtitle: "Uygulama ayarları",
                    icon: "gear",
                    color: Theme.gray600
                ) {
                    // Ayarlar sayfası
                }
            }
        }
    }
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Son Aktiviteler")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ActivityRow(
                    title: "Rota tamamlandı",
                    subtitle: "Kadıköy - Moda rotası",
                    time: "2 saat önce",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                ActivityRow(
                    title: "Yeni rota atandı",
                    subtitle: "Beşiktaş - Ortaköy rotası",
                    time: "4 saat önce",
                    icon: "plus.circle.fill",
                    color: .blue
                )
                
                ActivityRow(
                    title: "Konum güncellendi",
                    subtitle: "GPS sinyali güçlü",
                    time: "6 saat önce",
                    icon: "location.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: currentTime)
    }
    
    // MARK: - Pending Assignments Loading Section
    private var pendingAssignmentsLoadingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Onay Bekleyen Görevler")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                Spacer()
                
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.orange))
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1)
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.gray400))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bekleyen atamalar kontrol ediliyor...")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.gray700)
                        
                        Text("Lütfen bekleyin")
                            .font(.caption)
                            .foregroundColor(Theme.gray500)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Theme.gray100)
                .cornerRadius(12)
                
                Button(action: {
                    // isLoadingPendingAssignments = false // This line was removed
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("İptal Et")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.gray600)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    // .background(Theme.gray200)
                    // .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Pending Assignments Empty Section
    private var pendingAssignmentsEmptySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.green400)
                    .font(.system(size: 18))
                
                Text("Bekleyen Görev Yok")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "info.circle")
                        .foregroundColor(Theme.gray500)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Şu anda onay bekleyen görev bulunmuyor")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.gray700)
                        
                        Text("Yeni atamalar geldiğinde burada görünecek")
                            .font(.caption)
                            .foregroundColor(Theme.gray500)
                    }
                    
                    Spacer()
                    
                }
                .padding(16)
                .background(Theme.gray100)
                .cornerRadius(12)
                
                Button(action: refreshPendingAssignments) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                        Text("Yenile")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.green400)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.green400.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.green400.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Pending Assignments Section
    private var pendingAssignmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Onay Bekleyen Görevler")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let pendingAssignments = routeViewModel.pendingAssignments.filter { $0.assignmentStatus == .pending }
                Text("\(pendingAssignments.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                let pendingAssignments = routeViewModel.pendingAssignments.filter { $0.assignmentStatus == .pending }
                ForEach(pendingAssignments.prefix(3), id: \.id) { assignment in
                    PendingAssignmentCard(assignment: assignment) {
                        // Teklif detayına git
                        selectedAssignment = assignment
                    }
                }
                
                if pendingAssignments.count > 3 {
                    Button("Tümünü Gör (\(pendingAssignments.count))") {
                        NotificationCenter.default.post(
                            name: .navigateToTab,
                            object: nil,
                            userInfo: ["tabIndex": 1]
                        )
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .orange.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Functions
    private func refreshPendingAssignments() {
        routeViewModel.loadAssignments()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.gray700)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .cornerRadius(12)
        .purpleShadow()
    }
}

struct QuickAccessButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .purpleShadow()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pending Assignment Card
struct PendingAssignmentCard: View {
    let assignment: Assignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(assignment.assignmentStatus.statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: assignment.assignmentStatus.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(assignment.assignmentStatus.statusColor)
                }
                
                // Assignment Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Görev #\(assignment.id)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(assignment.assignmentOfferDescription ?? "Açıklama yok")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    VStack(spacing: 8) {
                        Text("\(formatAssignmentDateTime(assignment))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            AssignmentStatusBadge(status: assignment.assignmentStatus)
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                // Action Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(assignment.assignmentStatus.statusColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(assignment.assignmentStatus.statusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAssignmentDateTime(_ assignment: Assignment) -> String {
        // Tarih formatlaması
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: assignment.scheduleDate) else {
            return "\(assignment.scheduleDate) \(assignment.startTime)-\(assignment.endTime)"
        }
        
        // Türkçe tarih formatı
        let turkishDateFormatter = DateFormatter()
        turkishDateFormatter.locale = Locale(identifier: "tr_TR")
        turkishDateFormatter.dateFormat = "d MMMM yyyy"
        let turkishDate = turkishDateFormatter.string(from: date)
        
        // Saat formatlaması
        let startTime = formatTime(assignment.startTime)
        let endTime = formatTime(assignment.endTime)
        
        return "\(turkishDate) saat \(startTime) - \(endTime) arası"
    }
    
    private func formatTime(_ timeString: String) -> String {
        // "16:00:00" formatından "16:00" formatına çevir
        if timeString.count >= 5 {
            return String(timeString.prefix(5))
        }
        return timeString
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = dateString.toDate else { return "Geçersiz tarih" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

#Preview {
    MainView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
        .environmentObject(AppStateManager.shared)
}
