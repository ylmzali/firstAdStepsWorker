import SwiftUI
import WebKit

struct WorkPlanDetailView: View {
    let route: Route
    @Environment(\.dismiss) private var dismiss
    @State private var showRejectionNoteInput = false
    @State private var rejectionNote = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // WebView
                    WebView(url: URL(string: "https://buisyurur.com/proposal/\(route.id)")!, isLoading: $isLoading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Action Buttons
                    actionButtonsSection
                }
            }
            .navigationTitle("Çalışma Planı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showRejectionNoteInput) {
                rejectionNoteSheet
            }
            .alert("Başarılı", isPresented: $showSuccessAlert) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if route.status == .plan_rejected {
                // Plan reddedildiğinde sadece "Yeni Plan İste" butonu
                ActionButton(
                    title: isLoading ? "İstek Gönderiliyor..." : "Yeni Plan İste",
                    icon: "arrow.clockwise.circle.fill",
                    color: .orange,
                    isLoading: isLoading
                ) {
                    requestNewPlan()
                }
            } else {
                // Normal durumda Onayla ve Reddet butonları
                HStack(spacing: 12) {
                    ActionButton(
                        title: isLoading ? "Onaylanıyor..." : "Onayla",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        isLoading: isLoading
                    ) {
                        approvePlan()
                    }
                    
                    ActionButton(
                        title: "Reddet",
                        icon: "xmark.circle.fill",
                        color: .red,
                        isLoading: false
                    ) {
                        showRejectionNoteInput = true
                    }
                }
            }
        }
        .padding()
        .padding(.bottom, 34)
        .background(
            Rectangle()
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Rejection Note Sheet
    
    private var rejectionNoteSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Planı Reddet")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Planı neden reddettiğinizi belirtin:")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    
                    // Text Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reddetme Nedeni")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                                                
                        TextEditor(text: $rejectionNote)
                            .frame(height: 150)
                            .foregroundColor(.white)
                            .padding()
                            .textEditorStyle(PlainTextEditorStyle())
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .accentColor(.white)
                            .tint(.white)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        ActionButton(
                            title: isLoading ? "Reddediliyor..." : "Planı Reddet",
                            icon: "xmark.circle.fill",
                            color: .red,
                            isLoading: isLoading
                        ) {
                            rejectPlan()
                        }
                        .disabled(rejectionNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button(action: {
                            showRejectionNoteInput = false
                            rejectionNote = ""
                        }) {
                            Text("İptal")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        showRejectionNoteInput = false
                        rejectionNote = ""
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func approvePlan() {
        isLoading = true
        
        // TODO: Backend'e plan onayı gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            successMessage = "Plan başarıyla onaylandı!"
            showSuccessAlert = true
        }
    }
    
    private func rejectPlan() {
        isLoading = true
        
        // TODO: Backend'e plan reddi gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            showRejectionNoteInput = false
            rejectionNote = ""
            successMessage = "Plan reddedildi. Yeni plan hazırlanacak."
            showSuccessAlert = true
        }
    }
    
    private func requestNewPlan() {
        isLoading = true
        
        // TODO: Backend'e yeni plan isteği gönder
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            successMessage = "Yeni plan isteği gönderildi!"
            showSuccessAlert = true
        }
    }
}

// MARK: - Action Button Component

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

#Preview {
    WorkPlanDetailView(route: Route.preview)
} 
