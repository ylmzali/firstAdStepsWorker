//
//  RouteCategorySection.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 23.06.2025.
//

import SwiftUI

// Route Category Section View
struct RouteCategorySection: View {
    let title: String
    let icon: String
    let color: Color
    let routes: [Route]
    @Binding var selectedRoute: Route?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(routes.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.2))
                    )
            }
            .padding(.horizontal, 4)
            
            // Routes in this category
            LazyVStack(spacing: 12) {
                ForEach(routes) { route in
                    Button(action: {
                        selectedRoute = route
                    }) {
                        RouteRowView(route: route)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
