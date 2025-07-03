import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var userViewModel = UserViewModel()
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    @State private var showSupport = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        profileHeaderView
                        profileInfoCardsView
                        profileActionsView
                    }
                }
                .refreshable {
                    await refreshUserDataAsync()
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(userViewModel: userViewModel)
            }
            .sheet(isPresented: $showSupport) {
                SupportView(showDeleteAlert: $showDeleteAlert)
            }
            .onAppear {
                refreshUserData()
            }
            .overlay {
                if sessionManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        }
    }
    
    // MARK: - Profile Header View
    private var profileHeaderView: some View {
        HStack(spacing: 16) {
            // Sol tarafta ikon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Sağ tarafta kullanıcı bilgileri
            VStack(alignment: .leading, spacing: 6) {
                Text("\(sessionManager.currentUser?.firstName ?? "") \(sessionManager.currentUser?.lastName ?? "")")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let companyName = sessionManager.currentUser?.companyName, !companyName.isEmpty {
                    Text(companyName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                } else {
                    Text("Şirket bilgisi yok")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                }
                
                // Kullanıcı durumu
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Aktif")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Profile Info Cards View
    private var profileInfoCardsView: some View {
        VStack(spacing: 16) {
            personalInfoCard
            companyInfoCard
        }
        .padding(.horizontal)
    }
    
    // MARK: - Personal Info Card
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kişisel Bilgiler")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "envelope.fill", text: sessionManager.currentUser?.email ?? "-", color: .white)
                ProfileInfoRow(icon: "phone.fill", text: sessionManager.currentUser?.phoneNumber ?? "-", color: .white)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Company Info Card
    private var companyInfoCard: some View {
        Group {
            if let companyName = sessionManager.currentUser?.companyName, !companyName.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Şirket Bilgileri")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        ProfileInfoRow(icon: "building.2.fill", text: companyName, color: .white)
                        if let company_address = sessionManager.currentUser?.companyAddress, !company_address.isEmpty {
                            ProfileInfoRow(icon: "map.fill", text: company_address, color: .white)
                        }
                        if let companyTaxNumber = sessionManager.currentUser?.companyTaxNumber, !companyTaxNumber.isEmpty {
                            ProfileInfoRow(icon: "number", text: companyTaxNumber, color: .white)
                        }
                        if let companyTaxOffice = sessionManager.currentUser?.companyTaxOffice, !companyTaxOffice.isEmpty {
                            ProfileInfoRow(icon: "building.columns", text: companyTaxOffice, color: .white)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Profile Actions View
    private var profileActionsView: some View {
        VStack(spacing: 16) {
            editProfileButton
            supportButton
            Spacer()
            logoutButton
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
    }
    
    // MARK: - Edit Profile Button
    private var editProfileButton: some View {
        Button {
            showEditProfile = true
        } label: {
            HStack {
                Image(systemName: "pencil")
                Text("Profili Düzenle")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
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
    
    // MARK: - Support Button
    private var supportButton: some View {
        Button {
            showSupport = true
        } label: {
            HStack {
                Image(systemName: "questionmark.circle")
                Text("Yardım & Destek")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
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
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        VStack {
            Button(role: .destructive) {
                showLogoutAlert = true
            } label: {
                Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
            }
        }
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Çıkış Yap"),
                message: Text("Oturunuzu kapatmak istediğinize emin misiniz?"),
                primaryButton: .destructive(Text("Çıkış Yap")) {
                    sessionManager.clearSession()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Refresh User Data Async
    private func refreshUserDataAsync() async {
        guard let userId = sessionManager.currentUser?.id else { return }
        
        await withCheckedContinuation { continuation in
            userViewModel.refreshUserData(userId: userId, sessionManager: sessionManager) { success in
                if !success {
                    print("Kullanıcı bilgileri güncellenirken hata oluştu")
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Refresh User Data
    private func refreshUserData() {
        guard let userId = sessionManager.currentUser?.id else { return }
        
        userViewModel.refreshUserData(userId: userId, sessionManager: sessionManager) { success in
            if !success {
                print("Kullanıcı bilgileri güncellenirken hata oluştu")
            }
        }
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let icon: String
    let text: String
    var color: Color = .white

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 24, height: 24)
            Text(text)
                .font(.body)
                .foregroundColor(color)
            Spacer()
        }
    }
}

// MARK: - Support View
struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showDeleteAlert: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Yardım & Destek")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SSS")
                            .font(.headline)
                            .foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Rezervasyon nasıl yapılır?")
                            Text("• Canlı takip nasıl çalışır?")
                            Text("• Raporlar nereden görüntülenir?")
                        }
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )

                    Button(action: {
                        // WhatsApp ile destek
                        if let url = URL(string: "https://wa.me/905426943496") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("WhatsApp ile Destek Al")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Hesabımı Sil")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .alert(isPresented: $showDeleteAlert) {
                        Alert(
                            title: Text("Hesabınızı silmek üzeresiniz!"),
                            message: Text("Bu işlem geri alınamaz. Emin misiniz?"),
                            primaryButton: .destructive(Text("Hesabımı Sil")) {
                                // Hesap silme işlemi
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}


#Preview {
    ProfileView()
        .environmentObject(NavigationManager.shared)
        .environmentObject(SessionManager.shared)
}
