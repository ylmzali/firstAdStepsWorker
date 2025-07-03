import SwiftUI
import WebKit

struct RouteProposalView: View {
    let route: Route
    @State private var showProposalPDF = false
    @State private var showApprovalSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "doc.text.circle.fill")
                    .foregroundColor(.blue)
                Text("Çalışma Planı")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Plan Durumu
                HStack {
                    Image(systemName: statusIcon)
                        .font(.system(size: 20))
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(statusTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(statusDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(statusColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Plan İçeriği Önizleme
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan İçeriği")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ProposalItemRow(title: "Rota Güzergahı", value: route.title)
                        ProposalItemRow(title: "Tahmini Süre", value: "3-5 iş günü")
                        ProposalItemRow(title: "Kapsam", value: "Tam rota analizi ve optimizasyon")
                        ProposalItemRow(title: "Deliverables", value: "Detaylı rapor + Canlı takip sistemi")
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
                
                // Aksiyon Butonları
                HStack(spacing: 16) {
                    Button(action: {
                        showProposalPDF = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                            Text("Planı Görüntüle")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    if route.status == .plan_ready {
                        Button(action: {
                            showApprovalSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Onayla")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showProposalPDF) {
            ProposalPDFViewer(route: route)
        }
        .sheet(isPresented: $showApprovalSheet) {
            ProposalApprovalView(route: route)
        }
    }
    
    private var statusIcon: String {
        switch route.status {
        case .request_received:
            return "clock.circle.fill"
        case .plan_ready:
            return "doc.text.circle.fill"
        default:
            return "doc.text.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch route.status {
        case .request_received:
            return .gray
        case .plan_ready:
            return .blue
        default:
            return .blue
        }
    }
    
    private var statusTitle: String {
        switch route.status {
        case .request_received:
            return "Plan Hazırlanıyor"
        case .plan_ready:
            return "Plan Hazır"
        default:
            return "Plan Durumu"
        }
    }
    
    private var statusDescription: String {
        switch route.status {
        case .request_received:
            return "Uzman ekibimiz detaylı çalışma planınızı hazırlıyor"
        case .plan_ready:
            return "Çalışma planınız hazır. İnceleyip onaylayabilirsiniz"
        default:
            return "Plan durumu"
        }
    }
}

struct ProposalItemRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct ProposalPDFViewer: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // PDF Viewer Placeholder
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Çalışma Planı PDF'i")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Burada PDF görüntüleyici olacak")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Çalışma Planı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProposalApprovalView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @State private var approvalText = ""
    @State private var showRejectionOptions = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Onay İkonu
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                // Başlık
                Text("Çalışma Planını Değerlendir")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Açıklama
                Text("Çalışma planını inceleyin ve onaylayın veya reddedin. Onay işlemi geri alınamaz.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Onay Notu
                VStack(alignment: .leading, spacing: 8) {
                    Text("Not (Opsiyonel)")
                        .font(.headline)
                    
                    TextField("Notunuzu buraya yazabilirsiniz...", text: $approvalText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                // Butonlar
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: Onay işlemi - payment_pending durumuna geç
                        print("Plan onaylandı")
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Planı Onayla")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showRejectionOptions = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Planı Reddet")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Vazgeç")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Plan Değerlendirme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .alert("Plan Reddetme", isPresented: $showRejectionOptions) {
                Button("Not ile Reddet") {
                    // TODO: Not ile reddetme işlemi
                    print("Plan not ile reddedildi: \(approvalText)")
                    dismiss()
                }
                Button("Yeni Plan İste") {
                    // TODO: Yeni plan isteği
                    print("Yeni plan istendi")
                    dismiss()
                }
                Button("İptal Et") {
                    // TODO: Tamamen iptal etme
                    print("Plan tamamen iptal edildi")
                    dismiss()
                }
                Button("Vazgeç", role: .cancel) { }
            } message: {
                Text("Planı nasıl reddetmek istiyorsunuz?")
            }
        }
    }
}

#Preview {
    RouteProposalView(route: Route.preview)
} 
