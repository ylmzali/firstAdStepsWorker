//
//  DateFormatterExtension.swift
//  firstAdStepsWorker
//
//  Created by Ali YILMAZ on 17.06.2025.
//

import Foundation

extension DateFormatter {
    static let shared = DateFormatter()
    
    // MARK: - ISO8601 Formatting
    static func dateFromISO8601(_ iso8601String: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: iso8601String)
    }
    
    static func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    // MARK: - Turkish Date Formatting (using AppConfig.Timezone)
    static func turkishDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppConfig.Timezone.getCurrentLocale()
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func turkishDateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppConfig.Timezone.getCurrentLocale()
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Short Date Formatting (using AppConfig.Timezone)
    static func shortDateString(from date: Date) -> String {
        return AppConfig.Timezone.createDateFormatter(format: "dd.MM.yyyy").string(from: date)
    }
    
    static func shortDateTimeString(from date: Date) -> String {
        return AppConfig.Timezone.createDateFormatter(format: "dd.MM.yyyy HH:mm").string(from: date)
    }
    
    // MARK: - Time Formatting (using AppConfig.Timezone)
    static func timeString(from date: Date) -> String {
        return AppConfig.Timezone.createDateFormatter(format: "HH:mm").string(from: date)
    }
    
    static func timeStringWith24HourSupport(from date: Date) -> String {
        let timeString = AppConfig.Timezone.createDateFormatter(format: "HH:mm").string(from: date)
        
        // Eğer saat 00:00 ise (gece yarısı), 24:00 olarak göster
        if timeString == "00:00" {
            return "24:00"
        }
        return timeString
    }
    
    // MARK: - String Time Formatting (24:00 support)
    static func formatTimeString(_ timeString: String) -> String {
        // "16:00:00" formatından "16:00" formatına çevir
        if timeString.count >= 5 {
            let timePrefix = String(timeString.prefix(5))
            // Eğer saat 24:00 ise, 24:00 olarak göster
            if timePrefix.hasPrefix("24:") {
                return "24:00"
            }
            return timePrefix
        }
        return timeString
    }
    
    // MARK: - Relative Time Formatting
    static func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = AppConfig.Timezone.getCurrentLocale()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Turkish Short Date Formatting
    static func turkishShortDateString(from date: Date) -> String {
        return AppConfig.Timezone.createDateFormatter(format: "d MMMM yyyy").string(from: date)
    }
    
    // MARK: - Date Parsing (using AppConfig.Timezone)
    static func dateFromYMD(_ ymdString: String) -> Date? {
        return AppConfig.Timezone.createDateOnlyFormatter().date(from: ymdString)
    }
    
    static func dateFromDateTime(_ dateTimeString: String) -> Date? {
        // 24:00:00 formatını kontrol et
        if dateTimeString.contains("24:00:00") {
            // 24:00:00'ı 23:59:59 olarak değiştir ve 1 gün ekle
            let modifiedString = dateTimeString.replacingOccurrences(of: "24:00:00", with: "23:59:59")
            let baseDate = AppConfig.Timezone.createDateTimeFormatter().date(from: modifiedString)
            return baseDate?.addingTimeInterval(1) // 1 saniye ekle
        }
        
        return AppConfig.Timezone.createDateTimeFormatter().date(from: dateTimeString)
    }
    
    // MARK: - UTC to Local Timezone Conversion
    static func dateFromUTCDateTime(_ dateTimeString: String) -> Date? {
        // Önce UTC olarak parse et
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let utcDate = utcFormatter.date(from: dateTimeString) else {
            return nil
        }
        
        // UTC'den Türkiye saatine çevir
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        
        let localString = localFormatter.string(from: utcDate)
        return AppConfig.Timezone.createDateTimeFormatter().date(from: localString)
    }
}

extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    func formatDateForAPI() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return formatter.string(from: self)
    }
    
    func formatTimeForAPI() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return formatter.string(from: self)
    }
    
    func formatDateTimeForAPI() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = AppConfig.Timezone.getCurrentTimeZone()
        return formatter.string(from: self)
    }
}

// String extension'ı ile kolay kullanım
extension String {
    var toDate: Date? {
        return DateFormatter.dateFromYMD(self) ?? DateFormatter.dateFromISO8601(self)
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
    
    var toTurkishShortDate: String? {
        if let date = DateFormatter.dateFromYMD(self) {
            return DateFormatter.turkishShortDateString(from: date)
        }
        if let date = DateFormatter.dateFromISO8601(self) {
            return DateFormatter.turkishShortDateString(from: date)
        }
        return nil
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
