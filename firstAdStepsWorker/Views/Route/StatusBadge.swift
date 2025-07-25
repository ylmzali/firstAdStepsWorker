//
//  StatusBadge.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 4.07.2025.
//

import SwiftUI

// MARK: - Status Badge for WorkStatus
struct WorkStatusBadge: View {
    let workStatus: WorkStatus?
    
    var body: some View {
        if let status = workStatus {
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status.color.opacity(0.1))
                .foregroundColor(status.color)
                .cornerRadius(12)
        } else {
            Text("Bilinmiyor")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.gray)
                .cornerRadius(12)
        }
    }
}

// MARK: - Legacy StatusBadge (for backward compatibility)
struct StatusBadge: View {
    let workStatus: WorkStatus?
    
    var body: some View {
        WorkStatusBadge(workStatus: workStatus)
    }
}

#Preview {
    VStack(spacing: 10) {
        // WorkStatus examples
        WorkStatusBadge(workStatus: .available)
        WorkStatusBadge(workStatus: .onRoute)
        WorkStatusBadge(workStatus: .offDuty)
        WorkStatusBadge(workStatus: .busy)
        WorkStatusBadge(workStatus: nil)
    }
    .padding()
}
