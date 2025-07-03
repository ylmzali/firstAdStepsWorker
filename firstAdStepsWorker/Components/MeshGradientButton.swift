//
//  MeshGradientButton.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 17.06.2025.
//
import SwiftUI

struct MeshGradientButton: View {
    var icon: String = "sparkles"
    var title: String = "Text Butonu"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                MeshGradientBackground()
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 56)
    }
}

#Preview {
    MeshGradientButton(title: "Text Butonu", action: {})
}
