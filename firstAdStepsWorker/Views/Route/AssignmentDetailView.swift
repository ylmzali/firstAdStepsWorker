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
    @State private var showingAcceptConfirmSheet = false
    @State private var rejectReason = ""
    @State private var isLoading = false
    @State private var showingMapOptions = false
    @State private var isRejecting = false
    @State private var isAccepting = false
    @State private var showingCopiedAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Hero Section - Rota ID
                    heroSection
                        .padding(.top, 20) // Section'ın dış üst tarafına boşluk
                    
                    // Teklif Detayları Section
                    offerDetailsSection
                    
                    // Harita Section
                    mapSection
                    
                    // Konum Bilgileri Section
                    locationSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Tab bar için boşluk
            }
            .navigationTitle("Teklif Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.blue)
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
                MapOptionsSheet(assignment: assignment, onDismiss: { showingMapOptions = false })
                    .presentationDetents([.medium, .large])
            }
            .alert("Kopyalandı", isPresented: $showingCopiedAlert) {
                Button("Tamam") { }
            } message: {
                Text("Koordinatlar panoya kopyalandı")
            }
        }
        .onAppear {
            routeViewModel.loadAssignments()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Teklif Başlığı ve Durum
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.assignmentOfferDescription ?? "Teklif Detayları")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(assignment.formattedDateTimeRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                AssignmentStatusBadge(status: assignment.assignmentStatus)
            }
            
            // Açıklama
            if let description = assignment.assignmentOfferDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Teklif Detayları Section
    private var offerDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Teklif Detayları", icon: "doc.text.fill")
            
            VStack(spacing: 12) {
                detailRow(title: "Rota Tipi", value: assignment.routeType == "fixed_route" ? "Sabit Rota" : "Alan Rota", icon: "map.fill")
                detailRow(title: "Mesafe", value: "\(assignment.radiusMeters) metre", icon: "location.fill")
                detailRow(title: "Bütçe", value: "₺\(assignment.assignmentOfferBudget)", icon: "creditcard.fill")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Harita Section
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Harita Görüntüsü", icon: "map.fill")
            
            // Harita Görüntüsü
            if let mapUrl = assignment.mapSnapshotUrl {
                AsyncImage(url: URL(string: "https://buisyurur.com\(mapUrl)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            showingMapOptions = true
                        }
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "map")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Harita yükleniyor...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                        .onTapGesture {
                            showingMapOptions = true
                        }
                }
                
                // Harita Butonları
                HStack(spacing: 12) {
                    Button(action: openInAppleMaps) {
                        HStack {
                            Image(systemName: "map")
                            Text("Apple Maps")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    
                    Button(action: openInGoogleMaps) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Google Maps")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            } else {
                Text("Harita görüntüsü mevcut değil")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Konum Bilgileri Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Konum Bilgileri", icon: "location.fill")
            
            VStack(spacing: 12) {
                if assignment.routeType == "fixed_route" {
                    // Sabit rota için başlangıç ve bitiş konumları
                    locationRow(
                        title: "Başlangıç Konumu",
                        coordinate: "\(assignment.startLat), \(assignment.startLng)"
                    )
                    locationRow(
                        title: "Bitiş Konumu",
                        coordinate: "\(assignment.endLat), \(assignment.endLng)"
                    )
                } else {
                    // Alan rota için merkez konumu
                    locationRow(
                        title: "Merkez Konumu",
                        coordinate: "\(assignment.centerLat), \(assignment.centerLng)"
                    )
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private func locationRow(title: String, coordinate: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(coordinate)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                UIPasteboard.general.string = coordinate
                showingCopiedAlert = true
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
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
    
    private func openInAppleMaps() {
        let coordinate: CLLocationCoordinate2D
        if assignment.routeType == "fixed_route" {
            coordinate = CLLocationCoordinate2D(latitude: Double(assignment.startLat) ?? 0, longitude: Double(assignment.startLng) ?? 0)
        } else {
            coordinate = CLLocationCoordinate2D(latitude: Double(assignment.centerLat) ?? 0, longitude: Double(assignment.centerLng) ?? 0)
        }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "Rota #\(assignment.id)"
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func openInGoogleMaps() {
        let coordinate: String
        if assignment.routeType == "fixed_route" {
            coordinate = "\(assignment.startLat),\(assignment.startLng)"
        } else {
            coordinate = "\(assignment.centerLat),\(assignment.centerLng)"
        }
        let urlString = "comgooglemaps://?q=\(coordinate)&zoom=15"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Google Maps yüklü değilse web versiyonunu aç
            let webUrlString = "https://www.google.com/maps?q=\(coordinate)&zoom=15"
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}

// MARK: - Map Options Sheet
struct MapOptionsSheet: View {
    let assignment: Assignment
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(assignment.routeType == "fixed_route" ? "Rotayı Haritada Aç" : "Alanı Haritada Aç")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary) // Başlık rengini düzelttik
                        .multilineTextAlignment(.center)
                    
                    Text("Hangi harita uygulamasını kullanmak istiyorsunuz?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Options
                VStack(spacing: 12) {
                    // Apple Maps
                    Button(action: {
                        openInAppleMaps()
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Maps")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Varsayılan harita uygulaması")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Google Maps
                    Button(action: {
                        openInGoogleMaps()
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "globe")
                                .font(.title2)
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Google Maps")
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("Detaylı harita ve navigasyon")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func openInAppleMaps() {
        let coordinate: CLLocationCoordinate2D
        if assignment.routeType == "fixed_route" {
            coordinate = CLLocationCoordinate2D(latitude: Double(assignment.startLat) ?? 0, longitude: Double(assignment.startLng) ?? 0)
        } else {
            coordinate = CLLocationCoordinate2D(latitude: Double(assignment.centerLat) ?? 0, longitude: Double(assignment.centerLng) ?? 0)
        }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "Rota #\(assignment.id)"
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func openInGoogleMaps() {
        let coordinate: String
        if assignment.routeType == "fixed_route" {
            coordinate = "\(assignment.startLat),\(assignment.startLng)"
        } else {
            coordinate = "\(assignment.centerLat),\(assignment.centerLng)"
        }
        let urlString = "comgooglemaps://?q=\(coordinate)&zoom=15"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Google Maps yüklü değilse web versiyonunu aç
            let webUrlString = "https://www.google.com/maps?q=\(coordinate)"
            if let webUrl = URL(string: webUrlString) {
                UIApplication.shared.open(webUrl)
            }
        }
    }
}

// MARK: - Existing Sheets (Keep as is)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
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

#Preview {
    AssignmentDetailView(assignment: Assignment.preview, onAction: { _ in })
} 

