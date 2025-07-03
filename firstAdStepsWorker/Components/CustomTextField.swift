import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.black)
                .accentColor(.black)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .padding(.vertical, 0)
                .frame(height: 52)
            
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.white.opacity(0.1))
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.purple400, lineWidth: 1)
        )
    }
}

#Preview {
    CustomTextField(text: .constant(""), placeholder: "Test", icon: "person")
        // .preferredColorScheme(.dark)
        .padding()
}
