//
//  LoadingView.swift
//  firstAdSteps
//
//  Created by Ali YILMAZ on 3.06.2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Lütfen bekleyin...")
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding()
            .padding()
            .background(Color.black.opacity(0.75))
            .cornerRadius(12)
            /*
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Gradient(colors: [Color.red, Color.green, Color.blue]), lineWidth: 5)
                    .blur(radius: 7)
                    .offset(y: 1)
            )
             */
        }
    }
}

#Preview {
    LoadingView()
}
