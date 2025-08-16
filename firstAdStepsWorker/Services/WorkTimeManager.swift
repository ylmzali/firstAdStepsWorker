import Foundation
import SwiftUI

class WorkTimeManager: ObservableObject {
    static let shared = WorkTimeManager()
    
    @Published var currentWorkTime: WorkTimeTracker?
    @Published var totalWorkMinutes: Int = 0
    
    private let workTimeKey = "currentWorkTime"
    private let totalWorkTimeKey = "totalWorkMinutes"
    
    init() {
        loadWorkTime()
    }
    
    // Yeni çalışma başlat
    func startWork(assignment: Assignment) {
        print("⏰ [WorkTimeManager] Çalışma başlatılıyor - Assignment ID: \(assignment.assignmentId)")
        
        let workTime = WorkTimeTracker(
            assignmentId: assignment.assignmentId,
            scheduleId: assignment.id,
            employeeId: assignment.assignmentEmployeeId,
            startTime: Date(),
            totalWorkMinutes: 0,
            status: "working"
        )
        
        currentWorkTime = workTime
        saveWorkTime()
        
        // Server'a bildir
        sendWorkTimeToServer(workTime)
        
        print("✅ [WorkTimeManager] Çalışma başlatıldı")
    }
    
    // Çalışmayı duraklat
    func pauseWork() {
        guard var workTime = currentWorkTime else {
            print("❌ [WorkTimeManager] Duraklatılacak çalışma bulunamadı")
            return
        }
        
        print("⏸️ [WorkTimeManager] Çalışma duraklatılıyor")
        
        workTime.pauseTime = Date()
        workTime.status = "paused"
        workTime.totalWorkMinutes += workTime.currentSessionMinutes
        
        currentWorkTime = workTime
        saveWorkTime()
        
        // Server'a bildir
        sendWorkTimeToServer(workTime)
        
        print("✅ [WorkTimeManager] Çalışma duraklatıldı - Toplam: \(workTime.totalMinutes) dakika")
    }
    
    // Çalışmayı devam ettir
    func resumeWork() {
        guard var workTime = currentWorkTime else {
            print("❌ [WorkTimeManager] Devam ettirilecek çalışma bulunamadı")
            return
        }
        
        print("▶️ [WorkTimeManager] Çalışma devam ettiriliyor")
        
        workTime.resumeTime = Date()
        workTime.status = "working"
        
        currentWorkTime = workTime
        saveWorkTime()
        
        // Server'a bildir
        sendWorkTimeToServer(workTime)
        
        print("✅ [WorkTimeManager] Çalışma devam ettirildi")
    }
    
    // Çalışmayı tamamla
    func completeWork() {
        guard var workTime = currentWorkTime else {
            print("❌ [WorkTimeManager] Tamamlanacak çalışma bulunamadı")
            return
        }
        
        print("✅ [WorkTimeManager] Çalışma tamamlanıyor")
        
        workTime.endTime = Date()
        workTime.status = "completed"
        workTime.totalWorkMinutes += workTime.currentSessionMinutes
        
        let finalMinutes = workTime.totalMinutes
        currentWorkTime = workTime
        totalWorkMinutes += finalMinutes
        saveWorkTime()
        
        // Server'a bildir
        sendWorkTimeToServer(workTime)
        
        print("✅ [WorkTimeManager] Çalışma tamamlandı - Toplam: \(finalMinutes) dakika")
        
        // Çalışma tamamlandıktan sonra temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentWorkTime = nil
            self.saveWorkTime()
        }
    }
    
    // Mevcut çalışma süresini al
    func getCurrentWorkMinutes() -> Int {
        guard let workTime = currentWorkTime else { return 0 }
        return workTime.totalMinutes
    }
    
    // Çalışma durumunu kontrol et
    func isWorking() -> Bool {
        return currentWorkTime?.status == "working"
    }
    
    // Local storage
    private func saveWorkTime() {
        if let workTime = currentWorkTime {
            if let data = try? JSONEncoder().encode(workTime) {
                UserDefaults.standard.set(data, forKey: workTimeKey)
                print("💾 [WorkTimeManager] Çalışma zamanı kaydedildi")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: workTimeKey)
            print("🗑️ [WorkTimeManager] Çalışma zamanı temizlendi")
        }
        UserDefaults.standard.set(totalWorkMinutes, forKey: totalWorkTimeKey)
    }
    
    private func loadWorkTime() {
        if let data = UserDefaults.standard.data(forKey: workTimeKey),
           let workTime = try? JSONDecoder().decode(WorkTimeTracker.self, from: data) {
            currentWorkTime = workTime
            print("📥 [WorkTimeManager] Çalışma zamanı yüklendi - Status: \(workTime.status)")
        }
        totalWorkMinutes = UserDefaults.standard.integer(forKey: totalWorkTimeKey)
        print("📊 [WorkTimeManager] Toplam çalışma süresi: \(totalWorkMinutes) dakika")
    }
    
    // Server'a gönder
    private func sendWorkTimeToServer(_ workTime: WorkTimeTracker) {
        WorkTimeService.shared.sendWorkTimeToServer(workTime)
    }
} 