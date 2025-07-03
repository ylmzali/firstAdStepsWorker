//
//  RouteViewHeaderStats.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 24.06.2025.
//

import SwiftUI

struct RouteViewHeaderStats: View {
    @ObservedObject var viewModel: RouteViewModel
    
    var body: some View {
        if !viewModel.routes.isEmpty {
            statsContainer
        }
    }
    
    private var statsContainer: some View {
        HStack(spacing: 16) {
            totalRoutesBox
            activeRoutesBox
            pendingRoutesBox
            completedRoutesBox
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black)
    }
    
    private var totalRoutesBox: some View {
        RouteFuturisticStatBox(
            icon: "megaphone.fill",
            color: .yellow,
            title: "Toplam",
            value: String(viewModel.routes.count)
        )
    }
    
    private var activeRoutesBox: some View {
        RouteFuturisticStatBox(
            icon: "play.circle.fill",
            color: .green,
            title: "Aktif",
            value: String(activeRoutesCount)
        )
    }
    
    private var pendingRoutesBox: some View {
        RouteFuturisticStatBox(
            icon: "clock.circle.fill",
            color: .blue,
            title: "Bekleyen",
            value: String(pendingRoutesCount)
        )
    }
    
    private var completedRoutesBox: some View {
        RouteFuturisticStatBox(
            icon: "checkmark.seal.fill",
            color: .purple,
            title: "Tamam",
            value: String(completedRoutesCount)
        )
    }
    
    // Computed properties for route counts
    private var activeRoutesCount: Int {
        viewModel.routes.filter { $0.status == .active }.count
    }
    
    private var pendingRoutesCount: Int {
        viewModel.routes.filter { 
            $0.status == .request_received || 
            $0.status == .plan_ready || 
            $0.status == .payment_pending ||
            $0.status == .plan_rejected
        }.count
    }
    
    private var completedRoutesCount: Int {
        viewModel.routes.filter { $0.status == .completed }.count
    }
}

#Preview {
    RouteViewHeaderStats(viewModel: RouteViewModel(routes: [Route.preview], formVal: Route(
        id: UUID().uuidString,
        userId: SessionManager.shared.currentUser?.id ?? "",
        title: "",
        description: "",
        status: .request_received,
        assignedDate: nil,
        completion: 0,
        createdAt: ISO8601DateFormatter().string(from: Date())
    )))
}
