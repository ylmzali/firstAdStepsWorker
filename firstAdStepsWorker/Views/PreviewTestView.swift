import SwiftUI

struct PreviewTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Preview Test")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text("Bu view preview'ların çalışıp çalışmadığını test eder")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Test Button") {
                print("Test button tapped")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    PreviewTestView()
} 