import SwiftUI

struct DebugView: View {
    @StateObject private var logManager = LogManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showLocalStorageInfo = false
    @State private var localStorageInfo = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Debug Panel")
                            .font(.title2.bold())
                        Spacer()
                        Button("Temizle") {
                            logManager.clearLogs()
                        }
                        .foregroundColor(.red)
                    }
                    
                                                        HStack(spacing: 12) {
                                        // Local Storage Info Button
                                        Button("Local Storage Bilgilerini Göster") {
                                            loadLocalStorageInfo()
                                            showLocalStorageInfo = true
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        // Clear Local Storage Button
                                        Button("Local Storage Temizle") {
                                            clearLocalStorage()
                                        }
                                        .foregroundColor(.red)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        // Retry Pending Location Data Button
                                        Button("Pending Konumları Gönder") {
                                            locationManager.retryPendingLocationData()
                                        }
                                        .foregroundColor(.green)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                    
                    // Smart Filtering Controls
                    VStack(spacing: 8) {
                        HStack {
                            Text("Akıllı Konum Filtreleme:")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Durum: \(locationManager.smartFilteringStatus)")
                                .font(.caption)
                                .foregroundColor(locationManager.smartFilteringStatus == "Açık" ? .green : .orange)
                        }
                        
                        HStack(spacing: 12) {
                            Button("Filtrelemeyi Aç") {
                                locationManager.setSmartFilteringEnabled(true)
                            }
                            .foregroundColor(.green)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)
                            
                            Button("Filtrelemeyi Kapat") {
                                locationManager.setSmartFilteringEnabled(false)
                            }
                            .foregroundColor(.orange)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
                // Logs
                List {
                    ForEach(logManager.logs) { entry in
                        LogEntryView(entry: entry)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
        .alert("Local Storage Bilgileri", isPresented: $showLocalStorageInfo) {
            Button("Kopyala") {
                UIPasteboard.general.string = localStorageInfo
            }
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(localStorageInfo)
        }
    }
    
    private func loadLocalStorageInfo() {
        var info = "=== LOCAL STORAGE BİLGİLERİ ===\n\n"
        
        // ActiveTrackingInfo
        if let trackingInfo = locationManager.loadActiveTrackingInfo() {
            info += "📱 ACTIVE TRACKING INFO:\n"
            info += "Schedule ID: \(trackingInfo.routeId)\n"
            info += "Assignment ID: \(trackingInfo.assignmentId)\n"
            info += "Employee ID: \(trackingInfo.employeeId)\n"
            info += "Start Time: \(trackingInfo.startTime)\n"
            info += "End Time: \(trackingInfo.endTime)\n"
            info += "Status: \(trackingInfo.status)\n"
            info += "Last Location Update: \(trackingInfo.lastLocationUpdate?.description ?? "nil")\n"
            info += "Is Time Active: \(trackingInfo.isTimeActive)\n"
            info += "Is Expired: \(trackingInfo.isExpired)\n"
            info += "Remaining Minutes: \(trackingInfo.remainingMinutes)\n\n"
        } else {
            info += "📱 ACTIVE TRACKING INFO: Bulunamadı\n\n"
        }
        
        // LocationManager State
        info += "📍 LOCATION MANAGER STATE:\n"
        info += "Is Route Tracking: \(locationManager.isRouteTracking)\n"
        info += "Active Schedule ID: \(locationManager.activeScheduleId ?? "nil")\n"
        info += "Current Location: \(locationManager.currentLocation?.coordinate.latitude ?? 0), \(locationManager.currentLocation?.coordinate.longitude ?? 0)\n"
        info += "Location Permission: \(locationManager.locationPermissionStatus.rawValue)\n"
        info += "Tracking Start Date: \(locationManager.trackingStartDate?.description ?? "nil")\n"
        info += "Last Location Update: \(locationManager.lastLocationUpdate?.description ?? "nil")\n\n"
        
        // Current Route Info
        if let currentRoute = locationManager.currentRoute {
            info += "🛣️ CURRENT SCHEDULE:\n"
            info += "Schedule ID: \(currentRoute.id)\n"
            info += "Assignment ID: \(currentRoute.assignmentId)\n"
            info += "Work Status: \(currentRoute.workStatus)\n"
            info += "Schedule Date: \(currentRoute.scheduleDate)\n"
            info += "Start Time: \(currentRoute.startTime)\n"
            info += "End Time: \(currentRoute.endTime)\n\n"
        } else {
            info += "🛣️ CURRENT SCHEDULE: Bulunamadı\n\n"
        }
        
        // User Defaults Keys
        info += "🔑 USER DEFAULTS KEYS:\n"
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys.sorted()
        for key in allKeys {
            if key.contains("ActiveTracking") || key.contains("Location") || key.contains("Route") {
                let value = UserDefaults.standard.object(forKey: key)
                info += "\(key): \(String(describing: value))\n"
            }
        }
        
        localStorageInfo = info
    }
    
    private func clearLocalStorage() {
        // ActiveTrackingInfo'yu temizle
        locationManager.clearActiveTrackingInfo()
        
        // LocationManager state'ini temizle
        locationManager.clearLocationData()
        
        // UserDefaults'tan ilgili key'leri temizle
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.contains("ActiveTracking") || key.contains("Location") || key.contains("Route") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // Log ekle
        LogManager.shared.log("Local storage temizlendi", level: .info)
        
        // Bilgileri yeniden yükle
        loadLocalStorageInfo()
    }
}

struct LogEntryView: View {
    let entry: LogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.level.emoji)
                    .font(.caption)
                Text(entry.message)
                    .font(.caption)
                    .foregroundColor(getColor(for: entry.level))
                Spacer()
                Text(formatTime(entry.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func getColor(for level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

#Preview {
    DebugView()
} 