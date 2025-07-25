import SwiftUI

struct AssignmentStatusBadge: View {
    let status: AssignmentStatus
    
    var body: some View {
        HStack(spacing: 4) {
            /*
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundColor(status.color)
             */
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.statusColor.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        AssignmentStatusBadge(status: .pending)
        AssignmentStatusBadge(status: .accepted)
        AssignmentStatusBadge(status: .rejected)
        AssignmentStatusBadge(status: .cancelled)
    }
    .padding()
} 
