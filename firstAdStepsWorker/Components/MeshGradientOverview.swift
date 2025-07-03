//
//  MeshGradientOverview.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 17.06.2025.
//

import SwiftUI

struct MeshGradientOverview: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            MeshGradient(width: 3, height: 3, points: [
                [0.0, 0.0], [0.5, 0], [1.0, 0.0],
                [0.0, 0.5], [isAnimating ? 0.1 : 0.9, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ], colors: [
                .red, .purple, .indigo,
                .orange, isAnimating ? .white : .brown, .blue,
                .yellow, .green, .mint
            ],
                         
                smoothsColors: true,
                colorSpace: .perceptual
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    isAnimating.toggle()
                }
            }
            
            VStack {
                HStack {
                    Text("0.0, 0.0 Red")
                    Spacer()
                    Text("0.5, 0.0 Purple")
                    Spacer()
                    Text("1.0, 0.0 Indigo")
                }
                
                Spacer()
                
                HStack {
                    Text("0.0, 0.5 Orange")
                    Spacer()
                    Text("0.5, 0.5 White")
                    Spacer()
                    Text("1.0, 0.5 Blue")
                }
                
                Spacer()
                
                HStack {
                    Text("0.0, 1.0 Yellow")
                    Spacer()
                    Text("0.5, 1.0 Green")
                    Spacer()
                    Text("1.0, 1.0 Mint")
                }
            }
            
            
        }
        .padding()
        
    }
}

#Preview {
    MeshGradientOverview()
}
