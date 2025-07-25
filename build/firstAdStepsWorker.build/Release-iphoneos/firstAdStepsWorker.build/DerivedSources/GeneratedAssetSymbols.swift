import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Buy" asset catalog image resource.
    static let buy = DeveloperToolsSupport.ImageResource(name: "Buy", bundle: resourceBundle)

    /// The "BuyHover" asset catalog image resource.
    static let buyHover = DeveloperToolsSupport.ImageResource(name: "BuyHover", bundle: resourceBundle)

    /// The "Home" asset catalog image resource.
    static let home = DeveloperToolsSupport.ImageResource(name: "Home", bundle: resourceBundle)

    /// The "Home1" asset catalog image resource.
    static let home1 = DeveloperToolsSupport.ImageResource(name: "Home1", bundle: resourceBundle)

    /// The "Home2" asset catalog image resource.
    static let home2 = DeveloperToolsSupport.ImageResource(name: "Home2", bundle: resourceBundle)

    /// The "HomeHover" asset catalog image resource.
    static let homeHover = DeveloperToolsSupport.ImageResource(name: "HomeHover", bundle: resourceBundle)

    /// The "Map" asset catalog image resource.
    static let map = DeveloperToolsSupport.ImageResource(name: "Map", bundle: resourceBundle)

    /// The "MapHover" asset catalog image resource.
    static let mapHover = DeveloperToolsSupport.ImageResource(name: "MapHover", bundle: resourceBundle)

    /// The "Marker" asset catalog image resource.
    static let marker = DeveloperToolsSupport.ImageResource(name: "Marker", bundle: resourceBundle)

    /// The "Notifications" asset catalog image resource.
    static let notifications = DeveloperToolsSupport.ImageResource(name: "Notifications", bundle: resourceBundle)

    /// The "Offer" asset catalog image resource.
    static let offer = DeveloperToolsSupport.ImageResource(name: "Offer", bundle: resourceBundle)

    /// The "Profile" asset catalog image resource.
    static let profile = DeveloperToolsSupport.ImageResource(name: "Profile", bundle: resourceBundle)

    /// The "ProfileHover" asset catalog image resource.
    static let profileHover = DeveloperToolsSupport.ImageResource(name: "ProfileHover", bundle: resourceBundle)

    /// The "Search" asset catalog image resource.
    static let search = DeveloperToolsSupport.ImageResource(name: "Search", bundle: resourceBundle)

    /// The "SearchHover" asset catalog image resource.
    static let searchHover = DeveloperToolsSupport.ImageResource(name: "SearchHover", bundle: resourceBundle)

    /// The "banner-1" asset catalog image resource.
    static let banner1 = DeveloperToolsSupport.ImageResource(name: "banner-1", bundle: resourceBundle)

    /// The "banner-2" asset catalog image resource.
    static let banner2 = DeveloperToolsSupport.ImageResource(name: "banner-2", bundle: resourceBundle)

    /// The "banner-3" asset catalog image resource.
    static let banner3 = DeveloperToolsSupport.ImageResource(name: "banner-3", bundle: resourceBundle)

    /// The "banner-4" asset catalog image resource.
    static let banner4 = DeveloperToolsSupport.ImageResource(name: "banner-4", bundle: resourceBundle)

    /// The "bazaar_bg" asset catalog image resource.
    static let bazaarBg = DeveloperToolsSupport.ImageResource(name: "bazaar_bg", bundle: resourceBundle)

    /// The "lego-1" asset catalog image resource.
    static let lego1 = DeveloperToolsSupport.ImageResource(name: "lego-1", bundle: resourceBundle)

    /// The "lego-2" asset catalog image resource.
    static let lego2 = DeveloperToolsSupport.ImageResource(name: "lego-2", bundle: resourceBundle)

    /// The "lego-3" asset catalog image resource.
    static let lego3 = DeveloperToolsSupport.ImageResource(name: "lego-3", bundle: resourceBundle)

    /// The "logo-black" asset catalog image resource.
    static let logoBlack = DeveloperToolsSupport.ImageResource(name: "logo-black", bundle: resourceBundle)

    /// The "logo-white" asset catalog image resource.
    static let logoWhite = DeveloperToolsSupport.ImageResource(name: "logo-white", bundle: resourceBundle)

    /// The "main-banner-1" asset catalog image resource.
    static let mainBanner1 = DeveloperToolsSupport.ImageResource(name: "main-banner-1", bundle: resourceBundle)

    /// The "product1-1" asset catalog image resource.
    static let product11 = DeveloperToolsSupport.ImageResource(name: "product1-1", bundle: resourceBundle)

    /// The "product1-2" asset catalog image resource.
    static let product12 = DeveloperToolsSupport.ImageResource(name: "product1-2", bundle: resourceBundle)

    /// The "product1-3" asset catalog image resource.
    static let product13 = DeveloperToolsSupport.ImageResource(name: "product1-3", bundle: resourceBundle)

    /// The "product1-4" asset catalog image resource.
    static let product14 = DeveloperToolsSupport.ImageResource(name: "product1-4", bundle: resourceBundle)

    /// The "product1-5" asset catalog image resource.
    static let product15 = DeveloperToolsSupport.ImageResource(name: "product1-5", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Buy" asset catalog image.
    static var buy: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .buy)
#else
        .init()
#endif
    }

    /// The "BuyHover" asset catalog image.
    static var buyHover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .buyHover)
#else
        .init()
#endif
    }

    /// The "Home" asset catalog image.
    static var home: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .home)
#else
        .init()
#endif
    }

    /// The "Home1" asset catalog image.
    static var home1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .home1)
#else
        .init()
#endif
    }

    /// The "Home2" asset catalog image.
    static var home2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .home2)
#else
        .init()
#endif
    }

    /// The "HomeHover" asset catalog image.
    static var homeHover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .homeHover)
#else
        .init()
#endif
    }

    /// The "Map" asset catalog image.
    static var map: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .map)
#else
        .init()
#endif
    }

    /// The "MapHover" asset catalog image.
    static var mapHover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .mapHover)
#else
        .init()
#endif
    }

    /// The "Marker" asset catalog image.
    static var marker: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .marker)
#else
        .init()
#endif
    }

    /// The "Notifications" asset catalog image.
    static var notifications: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .notifications)
#else
        .init()
#endif
    }

    /// The "Offer" asset catalog image.
    static var offer: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .offer)
#else
        .init()
#endif
    }

    /// The "Profile" asset catalog image.
    static var profile: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .profile)
#else
        .init()
#endif
    }

    /// The "ProfileHover" asset catalog image.
    static var profileHover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .profileHover)
#else
        .init()
#endif
    }

    /// The "Search" asset catalog image.
    static var search: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .search)
#else
        .init()
#endif
    }

    /// The "SearchHover" asset catalog image.
    static var searchHover: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .searchHover)
#else
        .init()
#endif
    }

    /// The "banner-1" asset catalog image.
    static var banner1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .banner1)
#else
        .init()
#endif
    }

    /// The "banner-2" asset catalog image.
    static var banner2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .banner2)
#else
        .init()
#endif
    }

    /// The "banner-3" asset catalog image.
    static var banner3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .banner3)
#else
        .init()
#endif
    }

    /// The "banner-4" asset catalog image.
    static var banner4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .banner4)
#else
        .init()
#endif
    }

    /// The "bazaar_bg" asset catalog image.
    static var bazaarBg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bazaarBg)
#else
        .init()
#endif
    }

    /// The "lego-1" asset catalog image.
    static var lego1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lego1)
#else
        .init()
#endif
    }

    /// The "lego-2" asset catalog image.
    static var lego2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lego2)
#else
        .init()
#endif
    }

    /// The "lego-3" asset catalog image.
    static var lego3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lego3)
#else
        .init()
#endif
    }

    /// The "logo-black" asset catalog image.
    static var logoBlack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logoBlack)
#else
        .init()
#endif
    }

    /// The "logo-white" asset catalog image.
    static var logoWhite: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .logoWhite)
#else
        .init()
#endif
    }

    /// The "main-banner-1" asset catalog image.
    static var mainBanner1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .mainBanner1)
#else
        .init()
#endif
    }

    /// The "product1-1" asset catalog image.
    static var product11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product11)
#else
        .init()
#endif
    }

    /// The "product1-2" asset catalog image.
    static var product12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product12)
#else
        .init()
#endif
    }

    /// The "product1-3" asset catalog image.
    static var product13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product13)
#else
        .init()
#endif
    }

    /// The "product1-4" asset catalog image.
    static var product14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product14)
#else
        .init()
#endif
    }

    /// The "product1-5" asset catalog image.
    static var product15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .product15)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Buy" asset catalog image.
    static var buy: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .buy)
#else
        .init()
#endif
    }

    /// The "BuyHover" asset catalog image.
    static var buyHover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .buyHover)
#else
        .init()
#endif
    }

    /// The "Home" asset catalog image.
    static var home: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .home)
#else
        .init()
#endif
    }

    /// The "Home1" asset catalog image.
    static var home1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .home1)
#else
        .init()
#endif
    }

    /// The "Home2" asset catalog image.
    static var home2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .home2)
#else
        .init()
#endif
    }

    /// The "HomeHover" asset catalog image.
    static var homeHover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .homeHover)
#else
        .init()
#endif
    }

    /// The "Map" asset catalog image.
    static var map: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .map)
#else
        .init()
#endif
    }

    /// The "MapHover" asset catalog image.
    static var mapHover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .mapHover)
#else
        .init()
#endif
    }

    /// The "Marker" asset catalog image.
    static var marker: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .marker)
#else
        .init()
#endif
    }

    /// The "Notifications" asset catalog image.
    static var notifications: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .notifications)
#else
        .init()
#endif
    }

    /// The "Offer" asset catalog image.
    static var offer: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .offer)
#else
        .init()
#endif
    }

    /// The "Profile" asset catalog image.
    static var profile: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .profile)
#else
        .init()
#endif
    }

    /// The "ProfileHover" asset catalog image.
    static var profileHover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .profileHover)
#else
        .init()
#endif
    }

    /// The "Search" asset catalog image.
    static var search: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .search)
#else
        .init()
#endif
    }

    /// The "SearchHover" asset catalog image.
    static var searchHover: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .searchHover)
#else
        .init()
#endif
    }

    /// The "banner-1" asset catalog image.
    static var banner1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .banner1)
#else
        .init()
#endif
    }

    /// The "banner-2" asset catalog image.
    static var banner2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .banner2)
#else
        .init()
#endif
    }

    /// The "banner-3" asset catalog image.
    static var banner3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .banner3)
#else
        .init()
#endif
    }

    /// The "banner-4" asset catalog image.
    static var banner4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .banner4)
#else
        .init()
#endif
    }

    /// The "bazaar_bg" asset catalog image.
    static var bazaarBg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bazaarBg)
#else
        .init()
#endif
    }

    /// The "lego-1" asset catalog image.
    static var lego1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lego1)
#else
        .init()
#endif
    }

    /// The "lego-2" asset catalog image.
    static var lego2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lego2)
#else
        .init()
#endif
    }

    /// The "lego-3" asset catalog image.
    static var lego3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lego3)
#else
        .init()
#endif
    }

    /// The "logo-black" asset catalog image.
    static var logoBlack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logoBlack)
#else
        .init()
#endif
    }

    /// The "logo-white" asset catalog image.
    static var logoWhite: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .logoWhite)
#else
        .init()
#endif
    }

    /// The "main-banner-1" asset catalog image.
    static var mainBanner1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .mainBanner1)
#else
        .init()
#endif
    }

    /// The "product1-1" asset catalog image.
    static var product11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product11)
#else
        .init()
#endif
    }

    /// The "product1-2" asset catalog image.
    static var product12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product12)
#else
        .init()
#endif
    }

    /// The "product1-3" asset catalog image.
    static var product13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product13)
#else
        .init()
#endif
    }

    /// The "product1-4" asset catalog image.
    static var product14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product14)
#else
        .init()
#endif
    }

    /// The "product1-5" asset catalog image.
    static var product15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .product15)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

