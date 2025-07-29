import Foundation
import CoreLocation

enum AppConfig {
    // API Configuration
    enum API {
        static let baseURL = "https://buisyurur.com/workersapi"
        static let appToken = "cd786d6d-daf7-4e3f-bff2-24c144c9f013"
        static let tokenHeader = "app_token"
    } 

    // API Endpoints
    enum Endpoints {
        static let requestOTP = "/requestotp"
        static let verifyOTP = "/verifyotp"
        static let getUser = "/getuser"
        static let addUser = "/adduser"
        static let updateUser = "/updateuser"
        static let deleteUser = "/deleteuser"

        static let addRoute = "/addroute"
        static let updateRoute = "/updateroute"
        static let deleteRoute = "/deleteroute"
        static let getRoutes = "/getroutes"
        static let getRouteTrackings = "/getroutetrackings"
        // static let startRouteTracking = "/startRouteTracking"
        static let trackRouteLocation = "/trackroutelocation"
        static let updateAssignmentWorkStatus = "/updateassignmentworkstatus"
        static let getRouteTrack = "/getRouteTrack"
        static let uploadCheckpointPhoto = "/uploadCheckpointPhoto"
        static let getCheckpointPhotos = "/getCheckpointPhotos"

        static let logEvent = "/logevent"

        static let updateDeviceToken = "/updatedevicetoken"

        static let acceptAssignment = "/acceptassignment"
        static let rejectAssignment = "/rejectassignment"
        static let updateWorkStatus = "/updateworkstatus"
        static let getAssignments = "/getassigments"
        static let getCompanyEmployees = "/getcompanyemployees"

        static let employeeLocationUpdate = "/employee_location_update"
    }
    
    // Headers
    enum Headers {
        static let contentType = "application/json"
    }
    
    // Timeouts
    enum Timeouts {
        static let request: TimeInterval = 30
        static let session: TimeInterval = 300
    }
    
    // Cache
    enum Cache {
        static let maxAge = 3600 // 1 hour in seconds
    }
    
    // UserDefaults Keys
    enum UserDefaultsKeys {
        static let sessionToken = "sessionToken"
        static let userData = "userData"
        static let lastLoginDate = "lastLoginDate"
        static let deviceToken = "deviceToken"
    }
    
    // Validation
    enum Validation {
        static let phoneNumberMinLength = 10
        static let phoneNumberMaxLength = 15
        static let otpLength = 6
        static let passwordMinLength = 6
        static let passwordMaxLength = 50
    }
    
    // Notification
    enum Notification {
        static let defaultSound = "default"
        static let defaultBadge = 1
    }
    
    // UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let buttonHeight: CGFloat = 50
    }
    
    // Timezone Configuration
    enum Timezone {
        static let defaultTimeZone = TimeZone(identifier: "Europe/Istanbul") ?? TimeZone.current
        static let defaultLocale = Locale(identifier: "tr_TR")
        
        // Dynamic Timezone Support
        private static var _currentTimeZone: TimeZone = defaultTimeZone
        private static var _currentLocale: Locale = defaultLocale
        
        // Timezone Management
        static var currentTimeZone: TimeZone {
            get { return _currentTimeZone }
            set { _currentTimeZone = newValue }
        }
        
        static var currentLocale: Locale {
            get { return _currentLocale }
            set { _currentLocale = newValue }
        }
        
        // Timezone Helper Functions
        static func getCurrentTimeZone() -> TimeZone {
            return currentTimeZone
        }
        
        static func getCurrentLocale() -> Locale {
            return currentLocale
        }
        
        // Dynamic Timezone Setup
        static func setupTimezoneForLocation(_ location: CLLocation) {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first,
                   let timeZone = placemark.timeZone {
                    DispatchQueue.main.async {
                        currentTimeZone = timeZone
                        print("🌍 Timezone updated to: \(timeZone.identifier)")
                    }
                }
            }
        }
        
        // Country-based Timezone Setup
        static func setupTimezoneForCountry(_ countryCode: String) {
            switch countryCode.uppercased() {
            case "TR":
                currentTimeZone = TimeZone(identifier: "Europe/Istanbul") ?? defaultTimeZone
                currentLocale = Locale(identifier: "tr_TR")
            case "US":
                currentTimeZone = TimeZone(identifier: "America/New_York") ?? defaultTimeZone
                currentLocale = Locale(identifier: "en_US")
            case "GB":
                currentTimeZone = TimeZone(identifier: "Europe/London") ?? defaultTimeZone
                currentLocale = Locale(identifier: "en_GB")
            case "DE":
                currentTimeZone = TimeZone(identifier: "Europe/Berlin") ?? defaultTimeZone
                currentLocale = Locale(identifier: "de_DE")
            case "FR":
                currentTimeZone = TimeZone(identifier: "Europe/Paris") ?? defaultTimeZone
                currentLocale = Locale(identifier: "fr_FR")
            default:
                // Varsayılan timezone kullan
                currentTimeZone = defaultTimeZone
                currentLocale = defaultLocale
            }
            print("🌍 Timezone set for country \(countryCode): \(currentTimeZone.identifier)")
        }
        
        // Date Formatting Helpers
        static func createDateFormatter(format: String) -> DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = currentTimeZone
            formatter.locale = currentLocale
            return formatter
        }
        
        static func createTimeFormatter() -> DateFormatter {
            return createDateFormatter(format: "HH:mm:ss")
        }
        
        static func createDateTimeFormatter() -> DateFormatter {
            return createDateFormatter(format: "yyyy-MM-dd HH:mm:ss")
        }
        
        static func createDateOnlyFormatter() -> DateFormatter {
            return createDateFormatter(format: "yyyy-MM-dd")
        }
        
        // Timezone Info
        static func getTimezoneInfo() -> String {
            return "\(currentTimeZone.identifier) (\(currentTimeZone.abbreviation() ?? "Unknown"))"
        }
        
        // Usage Examples
        static func printTimezoneUsage() {
            print("🌍 Current Timezone: \(getTimezoneInfo())")
            print("🌍 Current Locale: \(currentLocale.identifier)")
            
            // Test date formatting
            let testDate = Date()
            let formatter = createDateTimeFormatter()
            print("🌍 Test Date: \(formatter.string(from: testDate))")
        }
        
        // Timezone Change Notification
        static func notifyTimezoneChange() {
            NotificationCenter.default.post(
                name: NSNotification.Name("AppConfigTimezoneChanged"),
                object: nil,
                userInfo: ["timezone": currentTimeZone.identifier]
            )
        }
        
        // Debug Timezone Settings
        static func debugTimezoneSettings() {
            // Debug mesajları kaldırıldı
        }
    }
} 
