//
//  DateFormatterExtension.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 17.06.2025.
//

import Foundation

extension DateFormatter {
    static let shared = DateFormatter()
    
    // ISO8601 formatından Date'e çevirme
    static func dateFromISO8601(_ iso8601String: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: iso8601String)
    }
    
    // Date'i ISO8601 formatına çevirme
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    // Türkçe tarih formatı (örn: 15 Haziran 2024)
    static func turkishDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Türkçe tarih ve saat formatı (örn: 15 Haziran 2024, 14:30)
    static func turkishDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Kısa tarih formatı (örn: 15.06.2024)
    static func shortDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    // Kısa tarih ve saat formatı (örn: 15.06.2024 14:30)
    static func shortDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    // Sadece saat formatı (örn: 14:30)
    static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // Göreceli zaman formatı (örn: 2 saat önce, 3 gün önce)
    static func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// String extension'ı ile kolay kullanım
extension String {
    var toDate: Date? {
        return DateFormatter.dateFromISO8601(self)
    }
    
    var toTurkishDate: String? {
        guard let date = toDate else { return nil }
        return DateFormatter.turkishDateString(from: date)
    }
    
    var toTurkishDateTime: String? {
        guard let date = toDate else { return nil }
        return DateFormatter.turkishDateTimeString(from: date)
    }
    
    var toShortDate: String? {
        guard let date = toDate else { return nil }
        return DateFormatter.shortDateString(from: date)
    }
    
    var toShortDateTime: String? {
        guard let date = toDate else { return nil }
        return DateFormatter.shortDateTimeString(from: date)
    }
    
    var toRelativeTime: String? {
        guard let date = toDate else { return nil }
        return DateFormatter.relativeTimeString(from: date)
    }
}


/*
 // ISO8601 string'inden Date'e çevirme
 let isoDate = "2024-03-20T12:00:00Z"
 if let date = isoDate.toDate {
     // Türkçe tarih formatı
     let turkishDate = DateFormatter.turkishDateString(from: date)
     // veya
     let turkishDate2 = isoDate.toTurkishDate
     
     // Kısa tarih formatı
     let shortDate = DateFormatter.shortDateString(from: date)
     // veya
     let shortDate2 = isoDate.toShortDate
     
     // Göreceli zaman
     let relativeTime = DateFormatter.relativeTimeString(from: date)
     // veya
     let relativeTime2 = isoDate.toRelativeTime
 }
 */
