import Foundation

/*
// Base API Response
struct APIResponse<T: Codable>: Codable {
    let status: String
    let data: T?
}

// OTP Request Response
struct OTPRequestResponse: Codable {
    let otpRequestId: String
    let expiresIn: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case otpRequestId = "otpRequestId"
        case expiresIn = "expiresIn"
        case message = "message"
    }
}

// OTP Verify Response
struct OTPVerifyResponse: Codable {
    let isUserExist: Bool
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case isUserExist = "isUserExist"
        case user = "user"
    }
}
*/





struct OTPResponse: Codable {
    let status: String
    let data: OTPData?
    let error: OTPError?
}
struct OTPData: Codable {
    let otpRequestId: String
    let expiresIn: Int
    let message: String
}
struct OTPError: Codable {
    let code: String
    let message: String
    let details: String
}

// OTP VERIFY
struct OTPVerifyResponse: Codable {
    let status: String
    let data: OTPVerifyData?
    let error: OTPVerifyError?
}
struct OTPVerifyData: Codable {
    let isUserExist: Bool?
    let user: User?
}
struct OTPVerifyError: Codable {
    let code: String
    let message: String
    let details: String
}

// ROUTE GET
struct RouteGetResponse: Codable {
    let status: String
    let data: RouteGetData?
    let error: RouteGetError?
}
struct RouteGetData: Codable {
    let issetRoute: Bool?
    let route: Route?
}
struct RouteGetError: Codable {
    let code: String
    let message: String
    let details: String
}

// ROUTES GET
struct RoutesGetResponse: Codable {
    let status: String
    let data: RoutesGetData?
    let error: RoutesGetError?
}
struct RoutesGetData: Codable {
    let issetRoutes: Bool?
    let routes: [Route]?
}
struct RoutesGetError: Codable {
    let code: String
    let message: String
    let details: String
}

// ROUTE CREATE
struct RouteCreateResponse: Codable {
    let status: String
    let data: RouteCreateData?
    let error: RouteCreateError?
}
struct RouteCreateData: Codable {
    let isRouteCreated: Bool?
    let route: Route?
}
struct RouteCreateError: Codable {
    let code: String
    let message: String
    let details: String
}
