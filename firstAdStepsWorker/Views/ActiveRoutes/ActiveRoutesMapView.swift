import SwiftUI
import MapKit

struct ActiveRoutesMapView: View {
    @ObservedObject var viewModel: ActiveRoutesViewModel
    @State private var selectedAnnotation: RouteMapAnnotation?
    @State private var showingDetailSheet = false
    @State private var showingFilters = false
    @EnvironmentObject private var navigationManager: NavigationManager
    
    init(viewModel: ActiveRoutesViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // MapWithPolylines kullanarak rota çizgilerini geri getiriyorum
            MapWithPolylines(
                region: viewModel.region,
                annotations: viewModel.mapAnnotations,
                directionPolylines: viewModel.directionPolylines,
                sessionPolylines: viewModel.sessionPolylines,
                areaCircles: viewModel.areaCircles
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    
                    // Filters Button
                    Button(action: {
                        showingFilters = true
                    }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text("Filtreler")
                        }
                        .padding(8)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(24)
                    }

                    Spacer()

                    // Close Button
                    Button(action: {
                        navigationManager.goToHome()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.black.opacity(0.6))
                            .background(Color.white.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 80)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // Loading Overlay
            if SessionManager.shared.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Error Overlay
            if let error = viewModel.error {
                ErrorView(message: error.userMessage) {
                    viewModel.loadActiveSchedules()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDetailSheet) {
            if let annotation = selectedAnnotation {
                ScheduleDetailSheet(schedule: annotation.schedule)
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(viewModel: viewModel)
        }
        .onAppear {
            print("🗺️ ActiveRoutesMapView appeared")
            print("📍 Current region: \(viewModel.region.center.latitude), \(viewModel.region.center.longitude)")
            print("📍 Region span: \(viewModel.region.span.latitudeDelta), \(viewModel.region.span.longitudeDelta)")
            
            // Delay the loading to avoid publishing changes during view updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.loadActiveSchedules()
            }
        }
        .onChange(of: viewModel.mapAnnotations) { annotations in
            print("🗺️ Map annotations updated: \(annotations.count) annotations")
            for (index, annotation) in annotations.enumerated() {
                print("   \(index + 1). \(annotation.type) at \(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
            }
        }
        .onReceive(viewModel.$region) { newRegion in
            print("🗺️ Region updated: \(newRegion.center.latitude), \(newRegion.center.longitude)")
            print("🗺️ Region span: \(newRegion.span.latitudeDelta), \(newRegion.span.longitudeDelta)")
        }
    }
}

// MARK: - Custom Annotation View
struct CustomAnnotationView: View {
    let annotation: RouteMapAnnotation
    
    var body: some View {
        Button(action: {
            // Handle annotation tap
        }) {
            VStack(spacing: 2) {
                Image(systemName: annotationIcon(for: annotation.type))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(annotation.color)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 3)
            }
        }
    }
    
    private func annotationIcon(for type: RouteMapAnnotation.AnnotationType) -> String {
        switch type {
        case .start:
            return "play.circle.fill"
        case .end:
            return "stop.circle.fill"
        case .waypoint:
            return "circle.fill"
        }
    }
}

// MARK: - Map Stat Card
struct MapStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

// MARK: - Schedule Detail Sheet
struct ScheduleDetailSheet: View {
    let schedule: ActiveSchedule
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rota Detayı")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("ID: \(schedule.id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // ScreenSessions Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ScreenSessions: \(schedule.screenSessions?.count ?? 0)")
                            .font(.headline)
                        ForEach(schedule.screenSessions ?? []) { session in
                            HStack {
                                Text("Session ID: \(session.id)")
                                Spacer()
                                if let lat = session.currentLat, let lng = session.currentLng {
                                    Text("(\(lat), \(lng))")
                                } else {
                                    Text("Konum yok")
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Detay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Info Row
struct MapInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Custom Checkbox View
struct CheckboxView: View {
    let isChecked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isChecked {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 16, height: 16)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @ObservedObject var viewModel: ActiveRoutesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Aktif Rotalar") {
                    if viewModel.schedules.isEmpty {
                        Text("Henüz rota bulunmuyor")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.schedules, id: \.id) { schedule in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(schedule.title ?? "Schedule \(schedule.id)")
                                        .font(.headline)
                                    Text(schedule.routeType == "fixed_route" ? "Sabit Rota" : "Alan Rota")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    if viewModel.selectedScheduleIds.contains(schedule.id) {
                                        viewModel.selectedScheduleIds.removeAll { $0 == schedule.id }
                                    } else {
                                        viewModel.selectedScheduleIds.append(schedule.id)
                                    }
                                }) {
                                    Image(systemName: viewModel.selectedScheduleIds.contains(schedule.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedScheduleIds.contains(schedule.id) ? .blue : .gray)
                                        .font(.system(size: 32))
                                }
                            }
                            
                        }
                        
                        HStack {
                            Spacer()
                            Button("Tümünü Seç") {
                                viewModel.selectedScheduleIds = viewModel.schedules.map { $0.id }
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Filtreler")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        viewModel.prepareMapData()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    // FilterSheet(viewModel: ActiveRoutesViewModel())
    ActiveRoutesMapView(viewModel: ActiveRoutesViewModel())
}
