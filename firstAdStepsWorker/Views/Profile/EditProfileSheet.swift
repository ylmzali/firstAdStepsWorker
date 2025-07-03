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
                Color.black.ignoresSafeArea()
                
                if showOTPVerification {
                    otpVerificationView
                } else {
                    profileEditFormView
                }
            }
            .navigationTitle(showOTPVerification ? "Telefon Doğrulaması" : "Profili Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                if !showOTPVerification {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            checkPhoneChangeAndSave()
                        }
                        .disabled(sessionManager.isLoading)
                        .foregroundColor(.white)
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
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Telefon Doğrulaması")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(selectedCountry.code) \(phoneNumber) numaralı telefonunuza gönderilen 4 haneli doğrulama kodunu giriniz.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
            }
            
            otpInputView
            timerView
            verifyButton
            cancelButton
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Kapat") {
                    hideKeyboard()
                }
                .foregroundColor(.accentColor)
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    // MARK: - OTP Input View
    private var otpInputView: some View {
        VStack(spacing: 12) {
            TextField("000000", text: $otpCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.white)
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
                        .fill(index < otpCode.count ? Color.blue : Color.white.opacity(0.3))
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
                    .foregroundColor(.white.opacity(0.7))
            } else {
                Button("Kodu Tekrar Gönder") {
                    requestOTP()
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Verify Button
    private var verifyButton: some View {
        Button(action: {
            verifyOTP()
        }) {
            Text("Doğrula")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(otpCode.count == 6 ? Color.blue : Color.gray)
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
        .foregroundColor(.red)
    }
    
    // MARK: - Profile Edit Form View
    private var profileEditFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                personalInfoSection
                companyInfoSection
                
                if let error = userViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Color.black)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Kapat") {
                    hideKeyboard()
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    // MARK: - Personal Info Section
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kişisel Bilgiler")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                customTextField("Ad", text: $firstName)
                customTextField("Soyad", text: $lastName)
                customTextField("E-posta", text: $email, keyboardType: .emailAddress, autocapitalization: .never)
                phoneField
            }
        }
        .padding(.bottom)
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
        TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.6)))
            .foregroundColor(.white)
            .textFieldStyle(PlainTextFieldStyle())
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .padding()
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
    
    // MARK: - Phone Field
    private var phoneField: some View {
        HStack(spacing: 0) {
            Button(action: { showCountryPicker = true }) {
                HStack {
                    Text(selectedCountry.flag)
                    Text(selectedCountry.code)
                        .foregroundColor(.white.opacity(0.8))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .sheet(isPresented: $showCountryPicker) {
                UserUpdateCountryPickerView(selectedCountry: $selectedCountry, countries: countries)
            }
            
            TextField("", text: $phoneNumber, prompt: Text("Telefon").foregroundColor(.white.opacity(0.6)))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.clear)
                .accentColor(.white)
                .tint(.white)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
                Color.black.ignoresSafeArea()
                
                List(countries, id: \.self) { country in
                    HStack {
                        Text(country.flag)
                            .font(.title2)
                        Text(country.name)
                            .foregroundColor(.white)
                        Spacer()
                        if country.code == selectedCountry.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCountry = country
                        dismiss()
                    }
                    .listRowBackground(Color.black)
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle("Ülke Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
