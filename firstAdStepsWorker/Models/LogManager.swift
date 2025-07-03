import Foundation
import os.log
import SwiftUI
import OSLog

final class LogManager: ObservableObject {
    static let shared = LogManager()
    
    private let logger: Logger
    @Published var logs: [LogEntry] = []
    
    private init() {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.buisyurur", category: "App")
    }
    
    func log(_ message: String, type: LogType = .info) {
        let entry = LogEntry(message: message, type: type, timestamp: Date())
        logs.append(entry)
        
        switch type {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
        
        // Log'ları sunucuya gönder
        sendLogToServer(entry)
    }
    
    func log(error: Error, context: String? = nil) {
        let message = context != nil ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        log(message, type: .error)
    }
    
    func log(event: String, parameters: [String: Any]? = nil) {
        var message = "Event: \(event)"
        if let params = parameters {
            message += " Parameters: \(params)"
        }
        log(message, type: .info)
    }
    
    private func sendLogToServer(_ entry: LogEntry) {
        // TODO: Implement server logging
        // Bu fonksiyon, logları sunucuya göndermek için kullanılacak
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}

// MARK: - Supporting Types

struct LogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogType
    let timestamp: Date
}

enum LogType {
    case debug
    case info
    case warning
    case error
    
    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var color: Color {
        switch self {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - View Extensions

struct LogView: View {
    @ObservedObject var logManager: LogManager
    
    var body: some View {
        List(logManager.logs) { entry in
            HStack {
                Text(entry.type.icon)
                Text(entry.message)
                    .foregroundColor(entry.type.color)
                Spacer()
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - View Modifier

struct LogModifier: ViewModifier {
    @ObservedObject var logManager: LogManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                logManager.log("View appeared: \(String(describing: type(of: content)))")
            }
            .onDisappear {
                logManager.log("View disappeared: \(String(describing: type(of: content)))")
            }
    }
}

extension View {
    func withLogging(_ logManager: LogManager) -> some View {
        modifier(LogModifier(logManager: logManager))
    }
} 