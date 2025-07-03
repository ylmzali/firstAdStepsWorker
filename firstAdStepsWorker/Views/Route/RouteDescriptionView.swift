import SwiftUI

struct RouteDescriptionView: View {
    @Binding var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rota Açıklaması")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            TextEditor(text: $description)
                .frame(height: 200)
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    RouteDescriptionView(description: .constant(""))
        .background(Color.black)
} 