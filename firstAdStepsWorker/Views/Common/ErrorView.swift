import SwiftUI

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button("Tamam") {
                onDismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 200, height: 44)
            .background(Color.blue)
            .cornerRadius(22)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

#Preview {
    ErrorView(
        message: "Bir hata oluştu",
        onDismiss: {}
    )
} 