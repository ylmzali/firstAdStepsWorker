//
//  RouteCard.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 4.07.2025.
//

import SwiftUI

// MARK: - Route Card
struct RouteCard: View {
    let route: Assignment
    let onTap: () -> Void
    @Namespace private var animation
    @State private var isAnimating = false
    @State private var currentWorkStatus: String
    
    init(route: Assignment, onTap: @escaping () -> Void) {
        self.route = route
        self.onTap = onTap
        self._currentWorkStatus = State(initialValue: route.workStatus)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                /*
                AssignmentStatusBadge(status: route.assignmentStatus)
                    .padding(.top, 2)
                    .offset(x: 12,y: -25)
                 */
                
                VStack(alignment: .leading, spacing: 14) {

                    // Work Status Indicator
                    // if currentWorkStatus == "working" {
                    HStack(spacing: 4) {
                        if currentWorkStatus == "working" {
                            Circle()
                                .fill(route.assignmentWorkStatus.statusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.6 : 0.5)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                        } else {
                            Image(systemName: route.assignmentWorkStatus.icon)
                                .font(.system(size: 18))
                                .foregroundColor(route.assignmentWorkStatus.statusColor)
                                .fontWeight(.medium)
                        }
                        Text(route.assignmentWorkStatus.displayName)
                            .font(.caption)
                            .foregroundColor(route.assignmentWorkStatus.statusColor)
                            .fontWeight(.medium)

                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(route.assignmentWorkStatus.statusColor.opacity(0.1))
                    .cornerRadius(12)
                    // .offset(x: 10, y: -18)
                    .onAppear {
                        isAnimating = true
                    }
                    // }
                
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(route.assignmentOfferDescription ?? "Görev")
                                .font(.system(size: 16, weight: .light))
                                .lineLimit(3)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    HStack(spacing: 6) {
                        Label(route.formattedTurkishDate, systemImage: "calendar")
                            .frame(maxWidth: 100)
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
                        Label("Başlangıç\n" + route.formattedStartTime, systemImage: "clock")
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
                        Label("Bitiş\n" + route.formattedEndTime, systemImage: "clock")
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top,28)
            .padding(.bottom,18)
            .padding(.horizontal,18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
            )
            .padding(.vertical, 2)
            .padding(.horizontal, 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            setupWorkStatusObserver()
        }
        .onDisappear {
            removeWorkStatusObserver()
        }
    }
    
    private func setupWorkStatusObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WorkStatusUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let scheduleId = userInfo["schedule_id"] as? String,
               let workStatus = userInfo["work_status"] as? String,
               scheduleId == route.id {
                
                
                DispatchQueue.main.async {
                    self.currentWorkStatus = workStatus
                    print("✅ [RouteCard] currentWorkStatus güncellendi: \(self.currentWorkStatus)")
                }
            }
        }
    }
    
    private func removeWorkStatusObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("WorkStatusUpdated"), object: nil)
    }
}

#Preview {
    VStack(spacing: 20) {
        RouteCard(
            route: Assignment.preview
        ) {
            print("Assignment tapped")
        }
    }
    .padding()
    .background(Color(.systemGray6))
}

extension String {
    var toYMDDate: Date? {
        return DateFormatter.dateFromYMD(self)
    }
    var toTurkishLongDate: String? {
        guard let date = toYMDDate else { return nil }
        return DateFormatter.turkishDateString(from: date)
    }
}
