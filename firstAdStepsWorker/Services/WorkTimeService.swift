import Foundation

class WorkTimeService {
    static let shared = WorkTimeService()
    
    func sendWorkTimeToServer(_ workTime: WorkTimeTracker) {
        let endpoint = AppConfig.API.baseURL + AppConfig.Endpoints.saveWorkTime
        
        // Türkiye timezone'u için formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        let parameters: [String: Any] = [
            "assignment_id": workTime.assignmentId,
            "schedule_id": workTime.scheduleId,
            "employee_id": workTime.employeeId,
            "start_time": formatter.string(from: workTime.startTime),
            "pause_time": workTime.pauseTime != nil ? formatter.string(from: workTime.pauseTime!) : "",
            "resume_time": workTime.resumeTime != nil ? formatter.string(from: workTime.resumeTime!) : "",
            "end_time": workTime.endTime != nil ? formatter.string(from: workTime.endTime!) : "",
            "total_work_minutes": workTime.totalMinutes,
            "status": workTime.status,
            "current_session_minutes": workTime.currentSessionMinutes
        ]
        
        print("🌐 [WorkTimeService] Çalışma zamanı gönderiliyor - Status: \(workTime.status)")
        print("🌐 [WorkTimeService] Endpoint: \(endpoint)")
        print("🌐 [WorkTimeService] Assignment ID: \(workTime.assignmentId)")
        print("🌐 [WorkTimeService] Schedule ID: \(workTime.scheduleId)")
        print("🌐 [WorkTimeService] Employee ID: \(workTime.employeeId)")
        print("🌐 [WorkTimeService] Start Time (TR): \(formatter.string(from: workTime.startTime))")
        print("🌐 [WorkTimeService] Parameters: \(parameters)")
        
        makeAPIRequest(endpoint: endpoint, parameters: parameters)
    }
    
    private func makeAPIRequest(endpoint: String, parameters: [String: Any]) {
        guard let url = URL(string: endpoint) else {
            print("❌ [WorkTimeService] Geçersiz URL: \(endpoint)")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(AppConfig.API.appToken, forHTTPHeaderField: "app_token")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters)
            request.httpBody = jsonData
            
            print("✅ [WorkTimeService] JSON data hazırlandı: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ [WorkTimeService] Network hatası: \(error.localizedDescription)")
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("📡 [WorkTimeService] HTTP Status Code: \(httpResponse.statusCode)")
                        
                        if let data = data {
                            print("📡 [WorkTimeService] Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                        }
                        
                        if httpResponse.statusCode == 200 {
                            print("✅ [WorkTimeService] Çalışma zamanı başarıyla kaydedildi")
                        } else {
                            print("❌ [WorkTimeService] Çalışma zamanı kaydedilemedi - HTTP \(httpResponse.statusCode)")
                        }
                    }
                }
            }.resume()
        } catch {
            print("❌ [WorkTimeService] JSON encode hatası: \(error)")
        }
    }
} 