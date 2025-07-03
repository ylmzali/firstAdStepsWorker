import SwiftUI

struct RegisterFormView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @EnvironmentObject private var sessionManager: SessionManager
    
    let phoneNumber: String
    let countryCode: String
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var companyName = ""
    @State private var companyTaxNumber = ""
    @State private var companyTaxOffice = ""
    @State private var companyAddress = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Logo ve başlık
                VStack {
                    Image("logo-black")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 120)
                }
                .padding(.top, 45)

                
                // Form alanları
                VStack(spacing: 16) {
                    CustomTextField(text: $firstName, placeholder: "Ad", icon: "person")
                    CustomTextField(text: $lastName, placeholder: "Soyad", icon: "person")
                    CustomTextField(text: $email, placeholder: "E-posta", icon: "envelope")
                    // CustomTextField(text: $companyName, placeholder: "Şirket Adı", icon: "building.2")
                    // CustomTextField(text: $companyTaxNumber, placeholder: "Vergi Numarası", icon: "number")
                    // CustomTextField(text: $companyTaxOffice, placeholder: "Vergi Dairesi", icon: "building.columns")
                    // CustomTextField(text: $companyAddress, placeholder: "Şirket Adresi", icon: "location")
                }
                .padding(.horizontal)
                
                // Kayıt ol butonu
                Button(action: {
                    Task {
                        await userViewModel.register(
                            phoneNumber: phoneNumber,
                            countryCode: countryCode,
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            companyName: companyName.isEmpty ? nil : companyName,
                            companyTaxNumber: companyTaxNumber.isEmpty ? nil : companyTaxNumber,
                            companyTaxOffice: companyTaxOffice.isEmpty ? nil : companyTaxOffice,
                            companyAddress: companyAddress.isEmpty ? nil : companyAddress
                        ) { result in
                            switch result {
                            case .success(let data):
                                if data.isUserSaved == true && sessionManager.isAuthenticated {
                                    navigationManager.goToHome()
                                }
                            case .failure:
                                // Error is handled in ViewModel and shown via errorMessage
                                break
                            }
                        }
                    }
                }) {
                    if SessionManager.shared.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Kayıt Ol")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(phoneNumber.isEmpty ? Theme.gray300 : Theme.purple400)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(SessionManager.shared.isLoading)
                
                if SessionManager.shared.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 40)
        }
        .background(AntColors.background)
        .navigationTitle("Kayıt Ol")
        .navigationBarBackButtonHidden(true)
        /*
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Kayıt Ol")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        */
    }
}

#Preview {
    RegisterFormView(phoneNumber: "+905551234567", countryCode: "TR")
        .environmentObject(NavigationManager.shared)
}
