//
//  DetailRow.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 4.07.2025.
//

import SwiftUI

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        DetailRow(
            icon: "calendar",
            title: "Atanma Tarihi",
            value: "15.01.2024"
        )
        
        DetailRow(
            icon: "chart.line.uptrend.xyaxis",
            title: "Tamamlanma",
            value: "35%"
        )
        
        DetailRow(
            icon: "clock",
            title: "Oluşturulma",
            value: "14.01.2024 10:30"
        )
    }
    .padding()
}
