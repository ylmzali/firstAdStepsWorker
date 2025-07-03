import Foundation

enum AppConfig {
    // API Configuration
    enum API {
        static let baseURL = "https://buisyurur.com/api"
        static let appToken = "cd786d6d-daf7-4e3f-bff2-24c144c9f013"
        static let tokenHeader = "app_token"
    } 

    // API Endpoints
    enum Endpoints {
        static let requestOTP = "/sendotp"
        static let verifyOTP = "/verifyotp"
        static let getUser = "/getuser"
        static let updateUser = "/updateuser"
        static let deleteUser = "/deleteuser"
        static let addRoute = "/addroute"
        static let updateRoute = "/updateroute"
        static let deleteRoute = "/deleteroute"
        static let getRoutes = "/getroutes"
        static let startRouteTracking = "/startRouteTracking"
        static let trackRouteLocation = "/trackRouteLocation"
        static let getRouteTrack = "/getRouteTrack"
        static let uploadCheckpointPhoto = "/uploadCheckpointPhoto"
        static let getCheckpointPhotos = "/getCheckpointPhotos"
        static let logEvent = "/logevent"
        static let updateDeviceToken = "/updatedevicetoken"
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
} 
