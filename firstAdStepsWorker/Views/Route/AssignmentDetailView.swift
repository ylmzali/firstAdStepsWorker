import SwiftUI
import MapKit

enum AssignmentActionResult {
    case accepted
    case rejected
}

struct AssignmentDetailView: View {
    let assignment: Assignment
    var onAction: ((AssignmentActionResult) -> Void)
    @Environment(\.dismiss) private var dismiss
    @StateObject private var routeViewModel = RouteViewModel()
    @State private var showingRejectSheet = false
    @State private var showingAcceptInfoSheet = false
    @State private var showingAcceptConfirmSheet = false // yeni eklenen state
    @State private var rejectReason = ""
    @State private var isLoading = false
    @State private var showingMapOptions = false
    @State private var isRejecting = false
    @State private var isAccepting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard
                        
                        // Teklif Detayları
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Teklif Detayları")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.gray800)
                            
                            offerDetailsCard
                        }
                        
                        // Harita Görüntüsü
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Rota Haritası")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.gray800)
                            
                            mapSnapshotCard
                        }
                        
                        // Rota Bilgileri
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Rota Bilgileri")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.gray800)
                            
                            routeInfoCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100) // Buton için alan bırak
                }
                
                // Aksiyon Butonları - ScrollView dışında
                VStack {
                    actionButtons
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                }
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
            }
            .background(Theme.gray100)
            .navigationTitle("Teklif Detayı")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showingRejectSheet) {
                RedReasonSheet(reason: $rejectReason, isLoading: $isRejecting, onCancel: { showingRejectSheet = false }, onReject: { reason in
                    rejectAssignment(reason: reason)
                })
            }
            .sheet(isPresented: $showingAcceptConfirmSheet) {
                AcceptConfirmSheet(
                    onConfirm: {
                        showingAcceptConfirmSheet = false
                        acceptAssignment()
                    },
                    onCancel: {
                        showingAcceptConfirmSheet = false
                    }
                )
            }
            .sheet(isPresented: $showingAcceptInfoSheet) {
                AcceptInfoSheet(onClose: {
                    showingAcceptInfoSheet = false
                    dismiss()
                })
            }
            .sheet(isPresented: $showingMapOptions) {
                MapOptionsSheet(
                    assignment: assignment,
                    onDismiss: { showingMapOptions = false }
                )
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Helper Functions
    private func openInAppleMaps() {
        // Merkez koordinatlarını kullan
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "http://maps.apple.com/?q=\(centerLat),\(centerLng)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInGoogleMaps() {
        // Merkez koordinatlarını kullan
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "comgooglemaps://?q=\(centerLat),\(centerLng)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.google.com/?q=\(centerLat),\(centerLng)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openInYandexMaps() {
        // Merkez koordinatlarını kullan
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "yandexmaps://maps.yandex.com/?pt=\(centerLng),\(centerLat)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.yandex.com/?pt=\(centerLng),\(centerLat)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openRouteInAppleMaps() {
        // Başlangıç ve bitiş noktaları ile yürüyüş rotası aç
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        // Apple Maps ile yürüyüş rotası aç
        if let url = URL(string: "http://maps.apple.com/?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&dirflg=w") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openRouteInGoogleMaps() {
        // Başlangıç ve bitiş noktaları ile yürüyüş rotası aç
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        // Google Maps ile yürüyüş rotası aç
        if let url = URL(string: "comgooglemaps://?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&directionsmode=walking") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Google Maps yüklü değilse web versiyonunu aç
                if let webUrl = URL(string: "https://maps.google.com/?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&dirflg=w") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openRouteInYandexMaps() {
        // Başlangıç ve bitiş noktaları ile yürüyüş rotası aç
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        // Yandex Maps ile yürüyüş rotası aç
        if let url = URL(string: "yandexmaps://maps.yandex.com/?rtext=\(startLat),\(startLng)~\(endLat),\(endLng)&rtt=pd") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Yandex Maps yüklü değilse web versiyonunu aç
                if let webUrl = URL(string: "https://maps.yandex.com/?rtext=\(startLat),\(startLng)~\(endLat),\(endLng)&rtt=pd") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    

    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
    
    // RouteType'a göre geçerli koordinatları döndüren yardımcı fonksiyon
    private func getValidCoordinates() -> (lat: String, lng: String) {
        if assignment.routeType == "fixed_route" {
            // Sabit rota: Başlangıç koordinatlarını kullan
            return (assignment.startLat, assignment.startLng)
        } else {
            // Alan rota: Merkez koordinatlarını kullan
            return (assignment.centerLat, assignment.centerLng)
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Görev #\(assignment.id)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.gray800)
                    
                    Text("Plan #\(assignment.planId)")
                        .font(.subheadline)
                        .foregroundColor(Theme.gray600)
                }
                
                Spacer()
                
                AssignmentStatusBadge(status: assignment.assignmentStatus)
            }
            
            Divider()
                .background(Theme.gray300)
            
            HStack {
                Label(formatAssignmentDateTime(assignment), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(Theme.gray700)
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.purple100, lineWidth: 1)
                )
        )
        .purpleShadow()
    }
    
    // MARK: - Offer Details Card
    private var offerDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Açıklama:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.gray800)
                Spacer()
            }
            
            Text(self.assignment.assignmentOfferDescription ?? "Açıklama yok")
                .font(.body)
                .foregroundColor(Theme.gray700)
                .lineLimit(nil)
            
            Divider()
                .background(Theme.gray300)
            
            HStack {
                Text("Teklif Edilen Ücret:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.gray800)
                Spacer()
                Text("₺\(assignment.assignmentOfferBudget)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.success)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.purple100, lineWidth: 1)
                )
        )
        .purpleShadow()
    }
    
    // MARK: - Map Snapshot Card
    private var mapSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let mapUrl = assignment.mapSnapshotUrl {
                    Button(action: {
                        showingMapOptions = true
                    }) {
                        AsyncImage(url: URL(string: "https://buisyurur.com\(mapUrl)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        } placeholder: {
                            Rectangle()
                                .fill(Theme.gray200)
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.purple400))
                                        Text("Harita yükleniyor...")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.gray600)
                                    }
                                )
                                .cornerRadius(12)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        showingMapOptions = true
                    }) {
                        Rectangle()
                            .fill(Theme.gray200)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "map")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.gray400)
                                    Text("Harita görüntüsü yok")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.gray600)
                                }
                            )
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.purple100, lineWidth: 1)
                )
        )
        .purpleShadow()
    }
    
    // MARK: - Route Info Card
    private var routeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rota Tipi:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.gray800)
                Spacer()
                Text(assignment.routeType == "fixed_route" ? "Sabit Rota" : "Alan Rota")
                    .font(.subheadline)
                    .foregroundColor(Theme.gray700)
            }
            
            Divider()
                .background(Theme.gray300)
            
            if assignment.routeType == "fixed_route" {
                // Sabit Rota: Başlangıç ve Bitiş koordinatları
                HStack {
                    Text("Başlangıç:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.gray800)
                    Spacer()
                    Text("\(assignment.startLat), \(assignment.startLng)")
                        .font(.caption)
                        .foregroundColor(Theme.gray600)
                    
                    Button(action: {
                        copyToClipboard("\(assignment.startLat), \(assignment.startLng)")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primary)
                    }
                }
                
                HStack {
                    Text("Bitiş:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.gray800)
                    Spacer()
                    Text("\(assignment.endLat), \(assignment.endLng)")
                        .font(.caption)
                        .foregroundColor(Theme.gray600)
                    
                    Button(action: {
                        copyToClipboard("\(assignment.endLat), \(assignment.endLng)")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primary)
                    }
                }
                
                Divider()
                    .background(Theme.gray300)
                
                Button(action: {
                    showingMapOptions = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .medium))
                        Text("Rotayı Harita Uygulamasında Aç")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.primary.opacity(0.1))
                    )
                }
            } else {
                // Alan Rota: Merkez ve Yarıçap
                HStack {
                    Text("Merkez:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.gray800)
                    Spacer()
                    Text("\(assignment.centerLat), \(assignment.centerLng)")
                        .font(.caption)
                        .foregroundColor(Theme.gray600)
                    
                    Button(action: {
                        copyToClipboard("\(assignment.centerLat), \(assignment.centerLng)")
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.primary)
                    }
                }
                
                if assignment.radiusMeters != "0" {
                    Divider()
                        .background(Theme.gray300)
                    
                    HStack {
                        Text("Yarıçap:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.gray800)
                        Spacer()
                        Text("\(assignment.radiusMeters) m")
                            .font(.subheadline)
                            .foregroundColor(Theme.gray700)
                    }
                }
                
                Divider()
                    .background(Theme.gray300)
                
                Button(action: {
                    showingMapOptions = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map")
                            .font(.system(size: 16, weight: .medium))
                        Text("Alanı Harita Uygulamasında Aç")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.primary.opacity(0.1))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.purple100, lineWidth: 1)
                )
        )
        .purpleShadow()
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if assignment.assignmentStatus == .pending {
                HStack(spacing: 12) {
                    // Kabul Et Butonu
                    Button(action: {
                        showingAcceptConfirmSheet = true
                    }, label: {
                        Text(isAccepting ? "Kabul Ediliyor..." : "Kabul Et")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.success)
                            .cornerRadius(12)
                            .buttonStyle(PlainButtonStyle())
                    })
                    .disabled(isAccepting)

                    // Reddet Butonu
                    Button(action: {
                        showingRejectSheet = true
                    }, label: {
                        Text("Reddet")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.error)
                            .cornerRadius(12)
                            .buttonStyle(PlainButtonStyle())
                    })
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: assignment.assignmentStatus == .accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(assignment.assignmentStatus == .accepted ? Color.green : Theme.error)
                    Text(assignment.assignmentStatus == .accepted ? "Görev Kabul Edildi" : "Görev Reddedildi")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(assignment.assignmentStatus == .accepted ? Color.green : Theme.error)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(assignment.assignmentStatus == .accepted ? Color.green.opacity(0.1) : Theme.error.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(assignment.assignmentStatus == .accepted ? Theme.success.opacity(0.3) : Theme.error.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Actions
    private func acceptAssignment() {
        isAccepting = true
        routeViewModel.acceptAssignment(assignmentId: assignment.assignmentId) { result in
            DispatchQueue.main.async {
                isAccepting = false
                switch result {
                case .success(_):
                    showingAcceptInfoSheet = true
                    onAction(.accepted)
                case .failure(_):
                    // TODO: Hata göster
                    break
                }
            }
        }
    }
    
    private func rejectAssignment(reason: String) {
        isRejecting = true
        routeViewModel.rejectAssignment(assignmentId: assignment.assignmentId, reason: reason) { result in
            DispatchQueue.main.async {
                isRejecting = false
                switch result {
                case .success(_):
                    onAction(.rejected)
                    dismiss()
                case .failure(_):
                    // TODO: Hata göster
                    break
                }
            }
        }
    }
    
    // MARK: - Helper Functions
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
}

struct RedReasonSheet: View {
    @Binding var reason: String
    @Binding var isLoading: Bool
    var onCancel: () -> Void
    var onReject: (String) -> Void
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.error)
            Text("Teklifi Reddetmek Üzeresiniz")
                .font(.title2).fontWeight(.bold)
            Text("Bir görevi reddettiğinizde, bu teklif listeden kaldırılır ve tekrar geri alınamaz. Lütfen reddetme nedeninizi belirtin.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            TextEditor(text: $reason)
                .focused($isFocused)
                .frame(height: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true } }
            HStack(spacing: 16) {
                
                Button(action: onCancel, label: {
                    Text("Vazgeç")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                })

                Button(action: { onReject(reason) }) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Reddet")
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.error)
                .cornerRadius(10)
                .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}

struct AcceptInfoSheet: View {
    var onClose: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.success)
            Text("Tebrikler! Görevi Kabul Ettiniz")
                .font(.title2).fontWeight(.bold)
            Text("Bu görevi artık Rotalar bölümünden takip edebilirsiniz. Görevle ilgili tüm detaylar ve ilerleme burada yer alacak.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onClose, label: {
                Text("Tamam")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .cornerRadius(12)
            })
        }
        .padding(32)
        .presentationDetents([.medium, .large])
    }
}

// Yeni bottom sheet view
struct AcceptConfirmSheet: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.primary)
            Text("Görevi kabul etmek istediğinize emin misiniz?")
                .font(.title2).fontWeight(.bold)
            Text("Bu görevi kabul ettikten sonra, görev listenize eklenecek ve sorumluluğu size ait olacak.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button(action: onCancel, label: {
                    Text("Vazgeç")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                })
                Button(action: onConfirm, label: {
                    Text("Evet, Kabul Et")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.success)
                        .cornerRadius(10)
                })
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Map Options Sheet
struct MapOptionsSheet: View {
    let assignment: Assignment
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(assignment.routeType == "fixed_route" ? "Rotayı Haritada Aç" : "Alanı Haritada Aç")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.gray800)
                
                Text(assignment.routeType == "fixed_route" ? 
                     "Bu rotayı harita uygulamasında açarak detayları görebilirsiniz." :
                     "Bu alanı harita uygulamasında açarak konumu görebilirsiniz.")
                    .font(.body)
                    .foregroundColor(Theme.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    if assignment.routeType == "fixed_route" {
                        // Sabit rota için rota seçenekleri
                        MapOptionButton(
                            title: "Apple Maps'te Rota Aç",
                            subtitle: "Yürüyüş rotası ile",
                            icon: "map",
                            color: Theme.primary
                        ) {
                            openRouteInAppleMaps()
                            dismiss()
                        }
                        
                        MapOptionButton(
                            title: "Google Maps'te Rota Aç",
                            subtitle: "Yürüyüş rotası ile",
                            icon: "map",
                            color: Theme.success
                        ) {
                            openRouteInGoogleMaps()
                            dismiss()
                        }
                        
                        MapOptionButton(
                            title: "Yandex Maps'te Rota Aç",
                            subtitle: "Yürüyüş rotası ile",
                            icon: "map",
                            color: Theme.warning
                        ) {
                            openRouteInYandexMaps()
                            dismiss()
                        }
                    } else {
                        // Alan rota için konum seçenekleri
                        MapOptionButton(
                            title: "Apple Maps'te Aç",
                            subtitle: "Merkez konumu göster",
                            icon: "location",
                            color: Theme.primary
                        ) {
                            openInAppleMaps()
                            dismiss()
                        }
                        
                        MapOptionButton(
                            title: "Google Maps'te Aç",
                            subtitle: "Merkez konumu göster",
                            icon: "location",
                            color: Theme.success
                        ) {
                            openInGoogleMaps()
                            dismiss()
                        }
                        
                        MapOptionButton(
                            title: "Yandex Maps'te Aç",
                            subtitle: "Merkez konumu göster",
                            icon: "location",
                            color: Theme.warning
                        ) {
                            openInYandexMaps()
                            dismiss()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Harita Seçenekleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Map Functions
    private func openInAppleMaps() {
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "http://maps.apple.com/?q=\(centerLat),\(centerLng)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openInGoogleMaps() {
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "comgooglemaps://?q=\(centerLat),\(centerLng)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.google.com/?q=\(centerLat),\(centerLng)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openInYandexMaps() {
        let centerLat = assignment.centerLat
        let centerLng = assignment.centerLng
        
        if let url = URL(string: "yandexmaps://maps.yandex.com/?pt=\(centerLng),\(centerLat)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.yandex.com/?pt=\(centerLng),\(centerLat)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openRouteInAppleMaps() {
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        if let url = URL(string: "http://maps.apple.com/?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&dirflg=w") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openRouteInGoogleMaps() {
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        if let url = URL(string: "comgooglemaps://?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&directionsmode=walking") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.google.com/?saddr=\(startLat),\(startLng)&daddr=\(endLat),\(endLng)&dirflg=w") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
    
    private func openRouteInYandexMaps() {
        let startLat = assignment.startLat
        let startLng = assignment.startLng
        let endLat = assignment.endLat
        let endLng = assignment.endLng
        
        if let url = URL(string: "yandexmaps://maps.yandex.com/?rtext=\(startLat),\(startLng)~\(endLat),\(endLng)&rtt=pd") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://maps.yandex.com/?rtext=\(startLat),\(startLng)~\(endLat),\(endLng)&rtt=pd") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
}

// MARK: - Map Option Button
struct MapOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.gray800)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.gray600)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.gray400)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.gray200, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AssignmentDetailView(assignment: Assignment.preview) { _ in }
} 

