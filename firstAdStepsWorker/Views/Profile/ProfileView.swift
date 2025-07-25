import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @StateObject private var userViewModel = UserViewModel()
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    @State private var showSupport = false
    @State private var showDeleteAlert = false
    @State private var showWorkStatusPicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeaderView
                        profileInfoCardsView
                        profileActionsView
                    }
                    .padding(.horizontal, 20)
                }
                .refreshable {
                    await refreshUserDataAsync()
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshUserData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(userViewModel: userViewModel)
            }
            .sheet(isPresented: $showSupport) {
                SupportView(showDeleteAlert: $showDeleteAlert)
            }
            .sheet(isPresented: $showWorkStatusPicker) {
                WorkStatusPickerView(
                    currentStatus: sessionManager.currentUser?.workStatus,
                    onStatusChanged: { newStatus in
                        updateWorkStatus(newStatus)
                    }
                )
            }
            .onAppear {
                refreshUserData()
            }
            .preferredColorScheme(.light)
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
        VStack(spacing: 20) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.primary,
                                Theme.primary.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: Theme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // User Info
            VStack(spacing: 8) {
                Text("\(sessionManager.currentUser?.firstName ?? "") \(sessionManager.currentUser?.lastName ?? "")")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(sessionManager.currentUser?.email ?? "")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Work Status Button
                Button(action: {
                    showWorkStatusPicker = true
                }) {
                    HStack(spacing: 8) {
                        if let workStatus = sessionManager.currentUser?.workStatus {
                            Circle()
                                .fill(workStatus.color)
                                .frame(width: 10, height: 10)
                            Text(workStatus.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(workStatus.color)
                        } else {
                            Circle()
                                .fill(Theme.gray400)
                                .frame(width: 10, height: 10)
                            Text("Durum Bilinmiyor")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.gray400)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.gray400)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.gray200, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Profile Info Cards View
    private var profileInfoCardsView: some View {
        VStack(spacing: 16) {
            personalInfoCard
        }
    }
    
    // MARK: - Personal Info Card
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primary)
                
                Text("Kişisel Bilgiler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "envelope.fill", text: sessionManager.currentUser?.email ?? "-", color: .primary)
                ProfileInfoRow(icon: "phone.fill", text: sessionManager.currentUser?.phoneNumber ?? "-", color: .primary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Profile Actions View
    private var profileActionsView: some View {
        VStack(spacing: 12) {
            editProfileButton
            supportButton
            logoutButton
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - Edit Profile Button
    private var editProfileButton: some View {
        Button {
            showEditProfile = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.primary)
                
                Text("Profili Düzenle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gray400)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Support Button
    private var supportButton: some View {
        Button {
            showSupport = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.primary)
                
                Text("Yardım & Destek")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.gray400)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(role: .destructive) {
            showLogoutAlert = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.error)
                
                Text("Çıkış Yap")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.error)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Update Work Status
    private func updateWorkStatus(_ newStatus: WorkStatus) {
        guard let currentUser = sessionManager.currentUser else { return }
        
        userViewModel.updateWorkStatus(userId: currentUser.id, workStatus: newStatus) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Yeni user objesi oluştur
                    let updatedUser = User(
                        id: currentUser.id,
                        companyId: currentUser.companyId,
                        firstName: currentUser.firstName,
                        lastName: currentUser.lastName,
                        email: currentUser.email,
                        countryCode: currentUser.countryCode,
                        phoneNumber: currentUser.phoneNumber,
                        companyName: currentUser.companyName,
                        companyTaxNumber: currentUser.companyTaxNumber,
                        companyTaxOffice: currentUser.companyTaxOffice,
                        companyAddress: currentUser.companyAddress,
                        workStatus: newStatus,
                        status: currentUser.status,
                        createdAt: currentUser.createdAt,
                        updatedAt: currentUser.updatedAt
                    )
                    
                    // Session manager'ı güncelle
                    sessionManager.updateCurrentUser(updatedUser)
                    print("Work status başarıyla güncellendi: \(newStatus.displayName)")
                    
                case .failure(let error):
                    print("Work status güncellenirken hata: \(error.localizedDescription)")
                    // Hata durumunda kullanıcıya bilgi verilebilir
                }
            }
        }
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let icon: String
    let text: String
    var color: Color = .primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.primary)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
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
        .environmentObject(AppStateManager.shared)
}

// MARK: - Work Status Picker View
struct WorkStatusPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let currentStatus: WorkStatus?
    let onStatusChanged: (WorkStatus) -> Void
    
    @State private var selectedStatus: WorkStatus?
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.badge.clock")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(Theme.primary)
                        }
                        
                        Text("Çalışma Durumu")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Mevcut durumunuzu seçin")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Status Options
                    VStack(spacing: 12) {
                        ForEach(WorkStatus.allCases, id: \.self) { status in
                            WorkStatusOptionRow(
                                status: status,
                                isSelected: selectedStatus == status,
                                onTap: {
                                    selectedStatus = status
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: {
                        if let newStatus = selectedStatus {
                            onStatusChanged(newStatus)
                            dismiss()
                        }
                    }) {
                        Text("Durumu Güncelle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedStatus != nil ? Theme.primary : Theme.gray400)
                            )
                    }
                    .disabled(selectedStatus == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
            .onAppear {
                selectedStatus = currentStatus
            }
        }
    }
}

struct WorkStatusOptionRow: View {
    let status: WorkStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(status.color)
                }
                
                // Status Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(statusDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Theme.primary.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Theme.primary : Theme.gray200, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusIcon: String {
        switch status {
        case .available:
            return "checkmark.circle"
        case .onRoute:
            return "figure.walk"
        case .offDuty:
            return "moon"
        case .busy:
            return "clock"
        }
    }
    
    private var statusDescription: String {
        switch status {
        case .available:
            return "Yeni rotalar için müsait durumdasınız"
        case .onRoute:
            return "Aktif bir rota üzerinde çalışıyorsunuz"
        case .offDuty:
            return "İzin veya dinlenme durumundasınız"
        case .busy:
            return "Şu anda meşgul durumdasınız"
        }
    }
}
