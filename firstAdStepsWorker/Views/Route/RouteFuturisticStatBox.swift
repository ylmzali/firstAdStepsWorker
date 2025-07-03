//
//  RouteFuturisticStatBox.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 23.06.2025.
//

import SwiftUI

// Stat kutusu
struct RouteFuturisticStatBox: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .frame(width: 50, height: 50)
            Text(value)
                .font(.title3).bold()
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

