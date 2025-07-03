import SwiftUI

struct DebugView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔍 Device Token Debug")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Device token alma ve gönderme sürecini takip edin")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)
                    
                    // Notification Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📱 Notification Durumu")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("İzin Durumu:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(notificationManager.isPermissionGranted ? "✅ Verildi" : "❌ Verilmedi")
                                .foregroundColor(notificationManager.isPermissionGranted ? .green : .red)
                        }
                        
                        HStack {
                            Text("Authorization Status:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(notificationManager.authorizationStatus.rawValue)")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(12)
                    
                    // Device Token Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔑 Device Token Bilgileri")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Token Var mı:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(sessionManager.deviceToken != nil ? "✅ Var" : "❌ Yok")
                                .foregroundColor(sessionManager.deviceToken != nil ? .green : .red)
                        }
                        
                        if let token = sessionManager.deviceToken {
                            HStack {
                                Text("Token Uzunluğu:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(token.count) karakter")
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Token (İlk 20 karakter):")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                
                                Text(String(token.prefix(20)) + "...")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(12)
                    
                    // User Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("👤 Kullanıcı Durumu")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Giriş Yapıldı mı:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(sessionManager.isAuthenticated ? "✅ Evet" : "❌ Hayır")
                                .foregroundColor(sessionManager.isAuthenticated ? .green : .red)
                        }
                        
                        if let user = sessionManager.currentUser {
                            HStack {
                                Text("User ID:")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(user.id)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    .background(Color("SecondaryBackground"))
                    .cornerRadius(12)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("🔄 Sayfayı Yenile") {
                            // View'ı yenilemek için
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DebugView()
        .environmentObject(SessionManager.shared)
        .environmentObject(NotificationManager.shared)
} 