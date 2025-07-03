import SwiftUI
import MapKit
import WebKit

struct RouteDetailView: View {
    let route: Route

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // İstanbul
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var showApprovalAlert = false
    @State private var showRejectionAlert = false
    @State private var rejectionNote = ""
    @State private var showRejectionNoteInput = false
    @State private var showWorkPlanDetail = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    // descriptionSection
                    workflowSection
                    contactSection
                    cancelSection
                }
            }
            closeButton
        }
        .sheet(isPresented: $showWorkPlanDetail) {
            WorkPlanDetailView(route: route)
        }
        .alert("Plan Onayı", isPresented: $showApprovalAlert) {
            Button("Onayla") {
                print("Plan onaylandı")
            }
            Button("Reddet") {
                showRejectionAlert = true
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Çalışma planını onaylıyor musunuz?")
        }
        .alert("Plan Reddetme", isPresented: $showRejectionAlert) {
            Button("Not ile Reddet") {
                showRejectionNoteInput = true
            }
            Button("Yeni Plan İste") {
                print("Yeni plan istendi")
            }
            Button("İptal Et") {
                print("Plan iptal edildi")
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Planı nasıl reddetmek istiyorsunuz?")
        }
        .alert("Reddetme Notu", isPresented: $showRejectionNoteInput) {
            TextField("Reddetme nedeninizi yazın...", text: $rejectionNote)
            Button("Gönder") {
                print("Plan reddedildi, not: \(rejectionNote)")
                rejectionNote = ""
            }
            Button("İptal", role: .cancel) {
                rejectionNote = ""
            }
        } message: {
            Text("Planı neden reddettiğinizi belirtin:")
        }
    }

    // MARK: - Bölümler
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                StatusBadge(status: route.status)
                    .scaleEffect(1)
                Text(route.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(route.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
            }
            .padding(.bottom)

            /*
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reklam Durumu")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(route.status.rawValue.capitalized)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Text("\(route.completion)%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
             */

            if route.canStartLiveTracking {
                liveTrackingSection
            }
            if let assignedDate = route.formattedAssignedDate {
                assignedDateSection(assignedDate: assignedDate)
            }
            if route.shareWithEmployees {
                shareWithEmployeesSection
            }
        }
        .padding(.top, 50)
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }

    private var liveTrackingSection: some View {
        Button {
            print("Canlı takip başladı...")
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Canlı Takip")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Reklamınızı gerçek zamanlı takip edin")
                            .font(.system(size: 12))
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                .padding()
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 5)
                        )
                )
            }
        }
    }

    private func assignedDateSection(assignedDate: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                
                HStack {
                    
                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reklam Tarihi")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(assignedDate)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                HStack {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Oluşturulma")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text(route.formattedCreatedDate ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Image(systemName: "calendar.circle.fill")
                        .foregroundColor(.orange)
                    
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var shareWithEmployeesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.circle.fill")
                    .foregroundColor(.purple)
                Text("Ekip Paylaşımı")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            if !route.sharedEmployeeIds.isEmpty {
                Text("\(route.sharedEmployeeIds.count) çalışan ile paylaşıldı")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 28)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var workflowSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.green)
                Text("İş Süreci")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(spacing: 12) {
                WorkflowStepRow(
                    icon: "plus.circle.fill",
                    title: "Reklam Talebi Alındı",
                    description: "Reklam talebiniz sisteme kaydedildi ✓",
                    color: .green,
                    isCompleted: route.status.isStepCompleted(1),
                    isClickable: false,
                    isActive: route.status.isStepActive(1)
                )
                WorkflowStepRow(
                    icon: "doc.text.circle.fill",
                    title: "Plan Hazırlandı",
                    description: "Çalışma planı hazırlandı ✓",
                    color: .blue,
                    isCompleted: route.status.isStepCompleted(2),
                    isClickable: (route.status.isStepActive(2) || route.status.isStepCompleted(2)) && route.status != .plan_rejected,
                    isActive: route.status.isStepActive(2),
                    onTap: {
                        if route.status.isStepActive(2) || route.status.isStepCompleted(2) || route.status == .plan_rejected {
                            showWorkPlanDetail = true
                        }
                    }
                )
                WorkflowStepRow(
                    icon: "checkmark.circle.fill",
                    title: "Plan Onaylandı",
                    description: "Plan onaylandı, ödeme bekleniyor ✓",
                    color: .orange,
                    isCompleted: route.status.isStepCompleted(3),
                    isClickable: false,
                    isActive: route.status.isStepActive(3)
                )
                WorkflowStepRow(
                    icon: "creditcard.circle.fill",
                    title: "Ödeme Alındı",
                    description: "Ödeme alındı, yayın planına alındı ✓",
                    color: .green,
                    isCompleted: route.status.isStepCompleted(4),
                    isClickable: false,
                    isActive: route.status.isStepActive(4)
                )
                WorkflowStepRow(
                    icon: "location.circle.fill",
                    title: "Aktif Yayın",
                    description: "Reklam aktif olarak yayınlanıyor ✓",
                    color: .green,
                    isCompleted: route.status.isStepCompleted(5),
                    isClickable: false,
                    isActive: route.status.isStepActive(5)
                )
                WorkflowStepRow(
                    icon: "location.circle.fill",
                    title: "Tamamlandı",
                    description: "Reklam tamamalandı ✓",
                    color: .green,
                    isCompleted: route.status.isStepCompleted(6),
                    isClickable: false,
                    isActive: route.status.isStepActive(6)
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "phone.circle.fill")
                    .foregroundColor(.yellow)
                Text("İletişim")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(spacing: 12) {
                ContactInfoRow(
                    icon: "phone.fill",
                    title: "Telefon",
                    value: "+90 212 555 0123",
                    action: { }
                )
                ContactInfoRow(
                    icon: "envelope.fill",
                    title: "E-posta",
                    value: "destek@buisyurur.com",
                    action: { }
                )
                ContactInfoRow(
                    icon: "message.fill",
                    title: "WhatsApp",
                    value: "+90 532 555 0123",
                    action: { }
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 24)
    }

    private var descriptionSection: some View {
        Group {
            if !route.description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "text.quote.circle.fill")
                            .foregroundColor(.blue)
                        Text("Reklam Açıklaması")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text(route.description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(nil)
                    }
                    .padding(.horizontal,8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
            }
        }
    }

    private var cancelSection: some View {
        Group {
            if route.status.canCancel {
                
                    VStack(spacing: 12) {
                        Button(action: {
                            print("Reklam iptal edildi")
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Reklamı İptal Et")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Bu reklam talebini iptal etmek istediğinizden emin misiniz?")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(24)
                
            }
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 40, height: 40)
                        )
                }
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct WorkflowStepRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isCompleted: Bool
    let isClickable: Bool
    let isActive: Bool
    let onTap: (() -> Void)?
    
    init(icon: String, title: String, description: String, color: Color, isCompleted: Bool, isClickable: Bool = false, isActive: Bool = false, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.isCompleted = isCompleted
        self.isClickable = isClickable
        self.isActive = isActive
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox - Renk duruma göre değişiyor
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(checkboxColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(descriptionColor)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Tıklanabilir göstergesi
            if isClickable {
                HStack {
                    Text("Plan")
                    Image(systemName: "arrow.right.circle.fill")
                }
                .font(.system(size: 16))
                .foregroundColor(.green)
                .tint(Color.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isClickable {
                onTap?()
            }
        }
    }
    
    // Checkbox rengi
    private var checkboxColor: Color {
        if isCompleted {
            return .blue // Tamamlanan adımlar mavi tick
        } else if isActive {
            return .green // Aktif adım yeşil
        } else {
            return .gray // Gelecek adımlar gri
        }
    }
    
    // Başlık rengi
    private var textColor: Color {
        if isActive {
            return .white
        } else if isCompleted {
            return .white.opacity(0.8)
        } else {
            return .white.opacity(0.5)
        }
    }
    
    // Açıklama rengi
    private var descriptionColor: Color {
        if isActive {
            return .white.opacity(0.8)
        } else if isCompleted {
            return .white.opacity(0.6)
        } else {
            return .white.opacity(0.3)
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Route Info View
struct RouteInfoView: View {
    let route: Route

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rota Bilgileri")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Description
                if !route.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.white.opacity(0.8))
                                Text("Açıklama")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            Text(route.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(nil)
                            
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }

                // Progress Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.white.opacity(0.8))
                        Text("İlerleme Durumu")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(route.completion)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ProgressColor.fromCompletion(route.completion).color)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 12)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            ProgressColor.fromCompletion(route.completion).color,
                                            ProgressColor.fromCompletion(route.completion).color.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(route.completion) / 100, height: 12)
                        }
                    }
                    .frame(height: 12)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                // Creation Date Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Oluşturulma Tarihi")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    if let createdDate = route.formattedCreatedDate {
                        Text(createdDate)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    if let relativeCreatedTime = route.relativeCreatedTime {
                        Text(relativeCreatedTime)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// Route Reports View
struct RouteReportsView: View {
    let route: Route
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Rapor Bilgileri")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ReportCard(title: "Görüntülenme", value: "1,234", icon: "eye.fill", color: .blue)
                ReportCard(title: "Geçiş", value: "567", icon: "figure.walk", color: .green)
                ReportCard(title: "Ortalama Yaş", value: "32", icon: "person.fill", color: .orange)
                ReportCard(title: "Cinsiyet Dağılımı", value: "%60 Erkek", icon: "person.2.fill", color: .purple)
            }
        }
    }
}

// Route Map View
struct RouteMapView: View {
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Konum Bilgileri")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Map(coordinateRegion: $region)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// Helper Views
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ReportCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Proposal WebView


#Preview {
    RouteDetailView(route: Route.preview)
}
