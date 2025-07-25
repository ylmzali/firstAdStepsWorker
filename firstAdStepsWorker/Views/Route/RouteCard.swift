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
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                AssignmentStatusBadge(status: route.assignmentStatus)
                    .padding(.top, 2)
                    .offset(x: 12,y: -25)
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            /*
                            Text(route.formattedTurkishDateTime)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                             */
                            Text(route.assignmentOfferDescription ?? "Görev")
                                .font(.system(size: 16, weight: .light))
                                .lineLimit(3)
                            /*
                            AssignmentStatusBadge(status: route.assignmentStatus)
                                .padding(.top, 2)
                             */
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    HStack(spacing: 6) {
                        /*
                         Label(route.formattedTurkishShortDate, systemImage: "calendar")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         Label("Bütçe: ₺" + route.assignmentOfferBudget, systemImage: "chart.line.uptrend.xyaxis")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         */
                        
                        Label(route.formattedTurkishDate, systemImage: "calendar")
                            .frame(maxWidth: 100)
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
                        Label("Başlangıç\n" + route.startTime.prefix(5), systemImage: "clock")
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
                        Label("Bitiş\n" + route.endTime.prefix(5), systemImage: "clock")
                            .font(.caption)
                            .padding(8)
                            .background(Theme.gray100)
                            .foregroundColor(Theme.purple600)
                            .cornerRadius(6)
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

extension DateFormatter {
    static func dateFromYMD(_ ymdString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.date(from: ymdString)
    }
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
