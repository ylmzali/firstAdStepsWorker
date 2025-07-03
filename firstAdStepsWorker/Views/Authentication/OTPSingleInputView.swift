import SwiftUI

struct OTPSingleInputView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    let phoneNumber: String
    let countryCode: String
    let otpRequestId: String
    
    @State private var otpCode = ""
    @State private var timeRemaining = 120 // 2 minutes
    @State private var timer: Timer?
    @State private var errorMessage: String?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                Image("logo-black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 120)
            }
            .padding(.top, 45)
            
            Text("Doğrulama Kodu")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(countryCode) \(phoneNumber) numaralı telefonunuza gönderilen 6 haneli doğrulama kodunu giriniz.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Single OTP Input with Visual Feedback
            VStack(spacing: 8) {
                TextField("000000", text: $otpCode)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isInputFocused ? Theme.purple400 : Theme.purple400.opacity(0.3), lineWidth: isInputFocused ? 3 : 1)
                    )
                    .focused($isInputFocused)
                    .onChange(of: otpCode) { newValue in
                        handleOTPChange(newValue)
                    }
                    .onTapGesture {
                        isInputFocused = true
                    }
                
                // Visual OTP Display
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(index < otpCode.count ? Theme.purple400 : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index < otpCode.count ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: otpCode.count)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 40)
            
            if timeRemaining > 0 {
                Text("Kalan süre: \(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                    .foregroundColor(.gray)
            } else {
                Button("Kodu Tekrar Gönder") {
                    viewModel.requestOTP(
                        phoneNumber: phoneNumber,
                        countryCode: countryCode
                    ) { result in
                        switch result {
                        case .success(let data):
                            navigationManager.goToOTPVerification(
                                phoneNumber: phoneNumber,
                                countryCode: countryCode,
                                otpRequestId: data.otpRequestId
                            )
                        case .failure:
                            break
                        }
                    }
                }
                .foregroundColor(.blue)
            }

            Button(action: {
                viewModel.verifyOTP(
                    phoneNumber: phoneNumber,
                    countryCode: countryCode,
                    otpRequestId: otpRequestId,
                    otpCode: otpCode
                ) { result in
                    switch result {
                    case .success(let data):
                        if data.isUserExist == true, let user = data.user {
                            print("✅ User verified successfully")
                            print("📱 User data: \(user)")
                            navigationManager.goToHome()
                        } else {
                            print("❌ User verification failed")
                            navigationManager.goToRegistration(phoneNumber: phoneNumber, countryCode: countryCode)
                        }
                    case .failure:
                        break
                    }
                }
            }) {
                Text("Doğrula")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(otpCode.count != 6 ? Theme.gray300 : Theme.purple400)
                    .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || SessionManager.shared.isLoading)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Doğrulama Kodu")
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
            // Auto-focus input when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .overlay {
            if SessionManager.shared.isLoading {
                LoadingView()
            }
        }
    }
    
    private func handleOTPChange(_ newValue: String) {
        // Sadece rakam girişine izin ver
        let filtered = newValue.filter { $0.isNumber }
        
        if filtered != newValue {
            otpCode = filtered
        }
        
        // Maksimum 6 rakam
        if filtered.count > 6 {
            otpCode = String(filtered.prefix(6))
        }
        
        // Eğer 6 rakam girildiyse, klavyeyi kapat
        if filtered.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = false
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

#Preview {
    OTPSingleInputView(
        phoneNumber: "5551234567",
        countryCode: "+90",
        otpRequestId: "123456"
    )
    .environmentObject(NavigationManager.shared)
} 