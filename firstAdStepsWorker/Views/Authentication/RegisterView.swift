import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var navigationManager: NavigationManager
    @StateObject private var viewModel = AuthViewModel()
    
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
                VStack(spacing: 16) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Text("Kayıt Ol")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                // Form alanları
                VStack(spacing: 16) {
                    CustomTextField(text: $firstName, placeholder: "Ad", icon: "person")
                    CustomTextField(text: $lastName, placeholder: "Soyad", icon: "person")
                    CustomTextField(text: $email, placeholder: "E-posta", icon: "envelope")
                    CustomTextField(text: $companyName, placeholder: "Şirket Adı", icon: "building.2")
                    CustomTextField(text: $companyTaxNumber, placeholder: "Vergi Numarası", icon: "number")
                    CustomTextField(text: $companyTaxOffice, placeholder: "Vergi Dairesi", icon: "building.columns")
                    CustomTextField(text: $companyAddress, placeholder: "Şirket Adresi", icon: "location")
                }
                .padding(.horizontal)
                
                // Kayıt ol butonu
                Button(action: {
                    Task {
                        await viewModel.register(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            companyName: companyName,
                            companyTaxNumber: companyTaxNumber,
                            companyTaxOffice: companyTaxOffice,
                            companyAddress: companyAddress
                        )
                    }
                }) {
                    Text("Kayıt Ol")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AntColors.primary)
                        .cornerRadius(25)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
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
        .navigationBarHidden(true)
        .onChange(of: viewModel.isRegistered) { isRegistered in
            if isRegistered {
                navigationManager.goToHome()
            }
        }
    }
} 