//
//  StatusBadge.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 23.06.2025.
//

import SwiftUI

struct StatusBadge: View {
    let status: RouteStatus
    
    var body: some View {
        Text(status.statusDescription)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(status.statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.statusColor.opacity(0.15))
            )
    }
}

struct SharedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10))
            Text("Paylaşılan")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.blue)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                )
        )
    }
}
