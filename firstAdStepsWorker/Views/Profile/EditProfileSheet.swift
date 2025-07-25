import SwiftUI

// MARK: - Hide Keyboard
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct EditProfileSheet: View {
    @EnvironmentObject private var sessionManager: SessionManager
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userViewModel: UserViewModel
    @StateObject private var authViewModel = AuthViewModel()
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var companyName: String = ""
    @State private var companyTaxNumber: String = ""
    @State private var companyTaxOffice: String = ""
    @State private var companyAddress: String = ""
    
    // Ülke kodu seçimi için
    @State private var selectedCountry = Country(code: "+90", name: "Türkiye", flag: "🇹🇷")
    @State private var showCountryPicker = false
    
    // OTP doğrulaması için
    @State private var showOTPVerification = false
    @State private var otpCode = ""
    @State private var otpRequestId = ""
    @State private var timeRemaining = 120
    @State private var timer: Timer?
    @State private var originalPhone = ""
    @State private var originalCountryCode = ""
    @State private var showSuccessAlert = false
    @State private var isUpdatingProfile = false
    
    private let countries = [
        Country(code: "+90", name: "Türkiye", flag: "🇹🇷"),
        Country(code: "+49", name: "Almanya", flag: "🇩🇪"),
        Country(code: "+44", name: "İngiltere", flag: "🇬🇧")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if showOTPVerification {
                    otpVerificationView
                } else {
                    profileEditFormView
                }
            }
            .navigationTitle(showOTPVerification ? "Telefon Doğrulaması" : "Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                if !showOTPVerification {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") {
                            dismiss()
                        }
                        .foregroundColor(Theme.primary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            checkPhoneChangeAndSave()
                        }
                        .disabled(sessionManager.isLoading)
                        .foregroundColor(Theme.primary)
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onChange(of: userViewModel.isUserUpdated) { isUpdated in
                guard let userId = sessionManager.currentUser?.id else { return }


                if isUpdated {
                    showSuccessAlert = true
                    userViewModel.resetState() // Reset the state after showing alert
                    userViewModel.refreshUserData(userId: userId, sessionManager: sessionManager) { result in
                        
                    }
                }
            }
            .alert("Başarılı", isPresented: $showSuccessAlert) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Bilgileriniz başarıyla güncellendi.")
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
    
    // MARK: - OTP Verification View
    private var otpVerificationView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "phone.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Theme.primary)
                    }
                    
                    Text("Telefon Doğrulaması")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(selectedCountry.code) \(phoneNumber) numaralı telefonunuza gönderilen 6 haneli doğrulama kodunu giriniz.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                        .padding(.horizontal)
                }
            }
            
            otpInputView
            timerView
            verifyButton
            cancelButton
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(Theme.error)
                    .font(.system(size: 14))
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(24)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Kapat") {
                    hideKeyboard()
                }
                .foregroundColor(Theme.primary)
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    // MARK: - OTP Input View
    private var otpInputView: some View {
        VStack(spacing: 16) {
            TextField("000000", text: $otpCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.primary.opacity(0.3), lineWidth: 1.5)
                )
                .foregroundColor(.primary)
                .onChange(of: otpCode) { newValue in
                    // Sadece rakam girişine izin ver
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered != newValue {
                        otpCode = filtered
                    }
                    // Maksimum 6 rakam
                    if filtered.count > 6 {
                        otpCode = String(filtered.prefix(6))
                    }
                }
            
            // Visual OTP Display
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < otpCode.count ? Theme.primary : Theme.gray300)
                        .frame(width: 12, height: 12)
                        .scaleEffect(index < otpCode.count ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: otpCode.count)
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Timer View
    private var timerView: some View {
        Group {
            if timeRemaining > 0 {
                Text("Kalan süre: \(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            } else {
                Button("Kodu Tekrar Gönder") {
                    requestOTP()
                }
                .foregroundColor(Theme.primary)
                .font(.system(size: 14, weight: .medium))
            }
        }
    }
    
    // MARK: - Verify Button
    private var verifyButton: some View {
        Button(action: {
            verifyOTP()
        }) {
            Text("Doğrula")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(otpCode.count == 6 ? Theme.primary : Theme.gray400)
                .cornerRadius(12)
        }
        .disabled(otpCode.count != 6 || sessionManager.isLoading)
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button("İptal") {
            showOTPVerification = false
            otpCode = ""
            timer?.invalidate()
        }
        .foregroundColor(Theme.error)
        .font(.system(size: 16, weight: .medium))
    }
    
    // MARK: - Profile Edit Form View
    private var profileEditFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                personalInfoSection
                
                if let error = userViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Theme.error)
                        .font(.system(size: 14))
                        .padding(.horizontal)
                }
            }
            .padding(20)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Kapat") {
                    hideKeyboard()
                }
                .foregroundColor(Theme.primary)
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primary)
                
                Text("Kişisel Bilgiler")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                customTextField("Ad", text: $firstName)
                customTextField("Soyad", text: $lastName)
                customTextField("E-posta", text: $email, keyboardType: .emailAddress, autocapitalization: .never)
                phoneField
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Company Info Section
    private var companyInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Şirket Bilgileri")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                customTextField("Şirket Adı", text: $companyName)
                customTextField("Vergi Numarası", text: $companyTaxNumber, keyboardType: .numberPad)
                customTextField("Vergi Dairesi", text: $companyTaxOffice)
                customTextField("Şirket Adresi", text: $companyAddress)
            }
        }
        /*
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
         */
    }
    
    // MARK: - Custom Text Field
    private func customTextField(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, autocapitalization: TextInputAutocapitalization = .sentences) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(Theme.gray500))
            .foregroundColor(.primary)
            .textFieldStyle(PlainTextFieldStyle())
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.gray200, lineWidth: 1)
                    )
            )
            .accentColor(Theme.primary)
            .tint(Theme.primary)
    }
    
    // MARK: - Phone Field
    private var phoneField: some View {
        HStack(spacing: 0) {
            Button(action: { showCountryPicker = true }) {
                HStack {
                    Text(selectedCountry.flag)
                    Text(selectedCountry.code)
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.gray400)
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(12)
            }
            .sheet(isPresented: $showCountryPicker) {
                UserUpdateCountryPickerView(selectedCountry: $selectedCountry, countries: countries)
            }
            
            TextField("", text: $phoneNumber, prompt: Text("Telefon").foregroundColor(Theme.gray500))
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.white)
                .accentColor(Theme.primary)
                .tint(Theme.primary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.gray200, lineWidth: 1)
        )
    }
    
    // MARK: - Load User Data
    private func loadUserData() {
        let user = sessionManager.currentUser

        firstName = user?.firstName ?? ""
        lastName = user?.lastName ?? ""
        email = user?.email ?? ""
        phoneNumber = user?.phoneNumber ?? ""
        companyName = user?.companyName ?? ""
        companyTaxNumber = user?.companyTaxNumber ?? ""
        companyTaxOffice = user?.companyTaxOffice ?? ""
        companyAddress = user?.companyAddress ?? ""
        
        // Ülke kodunu ayarla
        if let countryCode = user?.countryCode {
            selectedCountry = countries.first { $0.code == countryCode } ?? selectedCountry
        }
        
        // Orijinal değerleri sakla
        originalPhone = phoneNumber
        originalCountryCode = selectedCountry.code
    }
    
    // MARK: - Check Phone Change and Save
    private func checkPhoneChangeAndSave() {
        let currentPhoneWithCode = "\(selectedCountry.code)\(phoneNumber)"
        let originalPhoneWithCode = "\(originalCountryCode)\(originalPhone)"
        
        if currentPhoneWithCode != originalPhoneWithCode {
            // Telefon değişmiş, OTP iste
            requestOTP()
        } else {
            // Telefon değişmemiş, direkt kaydet
            saveUserProfile()
        }
    }
    
    // MARK: - Request OTP
    private func requestOTP() {
        authViewModel.requestOTP(
            phoneNumber: phoneNumber,
            countryCode: selectedCountry.code
        ) { result in
            switch result {
            case .success(let data):
                otpRequestId = data.otpRequestId
                showOTPVerification = true
                startTimer()
            case .failure:
                // Hata mesajı ViewModel'de gösteriliyor
                break
            }
        }
    }
    
    // MARK: - Verify OTP
    private func verifyOTP() {
        authViewModel.verifyOTP(
            phoneNumber: phoneNumber,
            countryCode: selectedCountry.code,
            otpRequestId: otpRequestId,
            otpCode: otpCode
        ) { result in
            switch result {
            case .success:
                // OTP doğrulandı, profili kaydet
                saveUserProfile()
                showOTPVerification = false
                timer?.invalidate()
            case .failure:
                // Hata mesajı ViewModel'de gösteriliyor
                break
            }
        }
    }
    
    // MARK: - Start Timer
    private func startTimer() {
        timeRemaining = 120
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Save User Profile
    private func saveUserProfile() {
        guard let userId = sessionManager.currentUser?.id else { return }
        
        isUpdatingProfile = false
        
        userViewModel.updateUser(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            countryCode: selectedCountry.code,
            phoneNumber: phoneNumber,
            companyName: companyName,
            companyTaxNumber: companyTaxNumber,
            companyTaxOffice: companyTaxOffice,
            companyAddress: companyAddress
        ) { result in
            switch result {
            case .success(let data):
                if let isUserUpdated = data.isUserUpdated,
                   isUserUpdated == true,
                   let user = data.user {
                    isUpdatingProfile = true
                    userViewModel.isUserUpdated = true
                    print("✅ User update successfully")
                    print("📱 User data: \(user)")
                } else {
                    print("❌ User update failed")
                    userViewModel.isUserUpdated = false
                }
            case .failure:
                // Error is handled in ViewModel and shown via errorMessage
                break
            }
        }
    }
    
}


// MARK: - Country Picker View
struct UserUpdateCountryPickerView: View {
    @Binding var selectedCountry: Country
    let countries: [Country]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                List(countries, id: \.self) { country in
                    HStack {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.name)
                            .foregroundColor(.primary)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        if country.code == selectedCountry.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.primary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCountry = country
                        dismiss()
                    }
                    .listRowBackground(Color.white)
                }
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
            .navigationTitle("Ülke Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(Theme.primary)
                }
            }
        }
    }
}
