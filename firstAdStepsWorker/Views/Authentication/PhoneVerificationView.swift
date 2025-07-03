import SwiftUI

struct PhoneVerificationView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    @State private var phoneNumber = ""
    @State private var selectedCountry = Country(code: "+90", name: "Türkiye", flag: "🇹🇷")
    @State private var showCountryPicker = false
    @State private var isPhoneValid = false
    @State private var isShowingKvkk = false
    @State private var isShowingTerms = false
    @State private var isKvkkAccepted = false
    @State private var isTermsAccepted = false
    @State private var isMarketingAccepted = false
    @State private var showError = false
    @State private var errorMessage: String?
    @FocusState private var isPhoneFieldFocused: Bool

    private let countries = [
        Country(code: "+90", name: "Türkiye", flag: "🇹🇷"),
        Country(code: "+49", name: "Almanya", flag: "🇩🇪"),
        Country(code: "+44", name: "İngiltere", flag: "🇬🇧")
    ]
    
    private var isFormValid: Bool {
        isPhoneValid && isKvkkAccepted && isTermsAccepted
    }
    
    private func validatePhoneNumber(_ number: String) {
        let digits = number.filter { $0.isNumber }
        // Türkiye için özel format kontrolü
        if selectedCountry.code == "+90" {
            isPhoneValid = digits.count == 10 && digits.first == "5"
        } else {
            isPhoneValid = digits.count == 10
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.purple400.ignoresSafeArea()
                VStack(spacing: 0) {
                    VStack {
                        Image("logo-white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 120)
                    }
                    .padding(.top, 45)
                    .frame(height: max(geometry.size.height * 0.35, 0))

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Telefon Numaranızı Girin")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.navy400)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.top, 10)
                        
                        // Country picker Input group
                        HStack(spacing: 0) {
                            Button(action: { showCountryPicker = true }) {
                                HStack {
                                    Text(selectedCountry.flag)
                                    Text(selectedCountry.code)
                                        .foregroundColor(Theme.gray600)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.gray400)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 52)
                                .background(Theme.gray100)
                                .cornerRadius(8)
                            }
                            .sheet(isPresented: $showCountryPicker) {
                                CountryPickerView(selectedCountry: $selectedCountry, countries: countries)
                            }
                            
                            TextField("5xx xxx xx xx", text: $phoneNumber)
                                .keyboardType(.numberPad)
                                .padding(.vertical, 0)
                                .padding(.horizontal, 12)
                                .frame(height: 52)
                                .background(Color.clear)
                                .focused($isPhoneFieldFocused)
                                .onChange(of: phoneNumber) { _, newValue in
                                    validatePhoneNumber(newValue)
                                }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.purple400, lineWidth: 1)
                        )
                        
                        // KVKK ve Şartlar
                        VStack(alignment: .leading, spacing: 20) {
                            Toggle(isOn: $isKvkkAccepted) {
                                HStack(spacing: 0) {
                                    Button(action: { isShowingKvkk = true }) {
                                        Text("KVKK Aydınlatma Metni'ni okudum kabul ediyorum.").underline()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Theme.purple400))
                            .font(.subheadline)
                            .foregroundColor(Theme.gray600)
                            .sheet(isPresented: $isShowingKvkk) {
                                KvkkSheetView()
                            }

                            Toggle(isOn: $isTermsAccepted) {
                                HStack(spacing: 0) {
                                    Button(action: { isShowingTerms = true }) {
                                        Text("Kullanım Şartları'nı okudum kabul ediyorum.").underline()
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Theme.purple400))
                            .font(.subheadline)
                            .foregroundColor(Theme.gray600)
                            .sheet(isPresented: $isShowingTerms) {
                                TermsSheetView()
                            }

                            Toggle(isOn: $isMarketingAccepted) {
                                Text("Kampanya ve yeniliklerden haberdar olmak istiyorum.")
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Theme.purple400))
                            .font(.subheadline)
                            .foregroundColor(Theme.gray600)
                        }
                        
                        // Devam Et Butonu
                        if SessionManager.shared.isLoading {
                            HStack {
                                Text("Gönderiliyor..")
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.purple400))
                            }
                            .font(.headline)
                            .foregroundColor(Theme.purple400)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isFormValid ? Theme.gray300 : Theme.purple400)
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                if isFormValid {
                                    viewModel.requestOTP(
                                        phoneNumber: phoneNumber,
                                        countryCode: selectedCountry.code
                                    ) { result in
                                        switch result {
                                        case .success(let data):
                                            navigationManager.goToOTPVerification(
                                                phoneNumber: phoneNumber,
                                                countryCode: selectedCountry.code,
                                                otpRequestId: data.otpRequestId
                                            )
                                        case .failure:
                                            // Error is handled in ViewModel and shown via errorMessage
                                            break
                                        }
                                    }
                                }
                            }) {
                                
                                Text("Devam Et")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(isFormValid ? Theme.purple400 : Theme.gray300)
                                    .cornerRadius(12)
                                
                            }
                            .disabled(!isFormValid)
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, geometry.size.height * 0.65 * 0.05)
                    .frame(height: max(geometry.size.height * 0.65, 0))
                    .padding(.horizontal, 24)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .background(
                        Color.white
                            .cornerRadius(32, corners: [.topLeft, .topRight])
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -2)
                    )
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
            }
            
        }
        // .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .navigationTitle("Telefon Doğrulama")
        .navigationBarHidden(true)
        .onAppear {
            // ... existing code ...
        }
        .onTapGesture {
            isPhoneFieldFocused = false
        }
    }
}

struct KvkkSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    Text("Buraya KVKK Aydınlatma metni gelecek. Kullanıcıya gerekli bilgilendirme burada gösterilecek.")
                        .font(.body)
                }
            }
            .navigationTitle("KVKK Aydınlatma Metni")
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

struct TermsSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView {
                    Text("Buraya Kullanım Şartları metni gelecek. Kullanıcıya gerekli bilgilendirme burada gösterilecek.")
                        .font(.body)
                }
            }
            .navigationTitle("Kullanım Şartları")
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

struct Country: Identifiable, Hashable {
    var id = UUID()
    var code: String
    var name: String
    var flag: String
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.code == rhs.code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    let countries: [Country]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(countries, id: \.self) { country in
                HStack {
                    Text(country.flag)
                    Text(country.name)
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
            }
            .navigationTitle("Ülke Seç")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}

#Preview {
    PhoneVerificationView()
        .environmentObject(NavigationManager.shared)
}
