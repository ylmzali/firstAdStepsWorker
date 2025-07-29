import SwiftUI

struct AssignmentListView: View {
    @StateObject private var routeViewModel = RouteViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedAssignment: Assignment?
    
    var body: some View {
        NavigationView {
            VStack {
                if routeViewModel.isLoading {
                    LoadingView()
                } else if let errorMessage = routeViewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        routeViewModel.loadAssignments()
                    }
                } else if routeViewModel.pendingAssignments.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.gray400)
                        
                        Text("Henüz teklif yok")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Size gelen teklifler burada görünecek")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(routeViewModel.pendingAssignments, id: \ .id) { assignment in
                            OfferRowView(assignment: assignment) {
                                selectedAssignment = assignment
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Teklifler")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        routeViewModel.loadAssignments()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AntColors.primary)
                    }
                }
            }
        }
        .refreshable {
            routeViewModel.loadAssignments()
        }
        .sheet(item: $selectedAssignment) { assignment in
            AssignmentDetailView(assignment: assignment) { _ in
                routeViewModel.loadAssignments()
            }
        }
        .onAppear {
            routeViewModel.loadAssignments()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkStatusUpdated"))) { _ in
            routeViewModel.loadAssignments()
        }
    }
}

struct OfferRowView: View {
    let assignment: Assignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(assignment.assignmentStatus.statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: assignment.assignmentStatus.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(assignment.assignmentStatus.statusColor)
                }
                
                // Assignment Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Görev #\(assignment.id)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(assignment.assignmentOfferDescription ?? "Açıklama yok")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    VStack(spacing: 8) {
                        Text("\(formatAssignmentDateTime(assignment))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            AssignmentStatusBadge(status: assignment.assignmentStatus)
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                // Action Icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(assignment.assignmentStatus.statusColor)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(assignment.assignmentStatus.statusColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(assignment.assignmentStatus.statusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAssignmentDateTime(_ assignment: Assignment) -> String {
        // Tarih formatlaması
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: assignment.scheduleDate) else {
            return "\(assignment.scheduleDate) \(assignment.startTime)-\(assignment.endTime)"
        }
        
        // Türkçe tarih formatı
        let turkishDateFormatter = DateFormatter()
        turkishDateFormatter.locale = Locale(identifier: "tr_TR")
        turkishDateFormatter.dateFormat = "d MMMM yyyy"
        let turkishDate = turkishDateFormatter.string(from: date)
        
        // Saat formatlaması
        let startTime = formatTime(assignment.startTime)
        let endTime = formatTime(assignment.endTime)
        
        return "\(turkishDate) saat \(startTime) - \(endTime) arası"
    }
    
    private func formatTime(_ timeString: String) -> String {
        // "16:00:00" formatından "16:00" formatına çevir
        if timeString.count >= 5 {
            return String(timeString.prefix(5))
        }
        return timeString
    }
}

#Preview {
    AssignmentListView()
        .environmentObject(SessionManager.shared)
} 
