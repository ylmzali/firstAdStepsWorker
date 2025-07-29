//
//  RouteDetailView.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 4.07.2025.
//

import SwiftUI
import MapKit

struct RouteDetailView: View {
    let route: Assignment
    @Environment(\.dismiss) private var dismiss
    @State private var showTrackingView = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Başlık ve durum
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(route.assignmentOfferDescription ?? "Görev")
                                .font(.title2.bold())
                            Label(route.scheduleDate, systemImage: "calendar")
                                .font(.caption)
                            .foregroundColor(.secondary)
                            
                            // Work Status
                            if route.workStatus == "working" {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("Çalışıyor")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                        AssignmentStatusBadge(status: route.assignmentStatus)
                    }
                    
                    // Küçük Harita Önizlemesi
                    mapSection
                        .frame(height: 160)
                        .cornerRadius(14)
                        .shadow(radius: 4, y: 1)

                    // Rota Bilgileri
                    VStack(alignment: .leading, spacing: 10) {
                        DetailRow(icon: "calendar", title: "Tarih", value: route.scheduleDate)
                        DetailRow(icon: "clock", title: "Başlangıç", value: route.startTime)
                        DetailRow(icon: "clock", title: "Bitiş", value: route.endTime)
                        DetailRow(icon: "chart.line.uptrend.xyaxis", title: "Bütçe", value: "₺" + route.assignmentOfferBudget)
                    }

                    // Takip ekranına git butonu
                    Button(action: { showTrackingView = true }) {
                        Label("Rota Takip Ekranına Git", systemImage: "map")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                }
                .padding()
            }
            .navigationTitle("Rota Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showTrackingView) {
                RouteTrackingView(route: route)
            }
            .onAppear {
                updateRegionToCurrentLocation()
            }
        }
    }
    
    // Küçük harita önizlemesi
    private var mapSection: some View {
        Map(coordinateRegion: $region)
            .onAppear {
                updateRegionToCurrentLocation()
        }
    }
    
    private func updateRegionToCurrentLocation() {
        if let loc = locationManager.currentLocation {
            region.center = loc.coordinate
        }
    }
}

