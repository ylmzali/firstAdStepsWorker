//
//  Log.swift
//  firstAdSteps
//
//  Created by Ali YILMAZ on 11.06.2025.
//

import Foundation

enum Log {
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("🔍 [\(fileName):\(line)] \(function): \(message)")
        #endif
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        print("❌ [\(fileName):\(line)] \(function): \(message)")
    }
    
    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("🌐 [\(fileName):\(line)] \(function): \(message)")
        #endif
    }
}

