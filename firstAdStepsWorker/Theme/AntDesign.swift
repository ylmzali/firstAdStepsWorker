import SwiftUI

// Ant Design renk paleti
enum AntColors {
    static let primary = Color("Primary")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    
    // Nötr renkler
    static let text = Color("Text")
    static let secondaryText = Color("SecondaryText")
    static let disabledText = Color(hex: "#000000").opacity(0.25)
    static let border = Color(hex: "#d9d9d9")
    static let divider = Color(hex: "#f0f0f0")
    static let background = Color("Background")
    static let tableHeader = Color(hex: "#fafafa")
}

// Ant Design metin boyutları
enum AntTypography {
    static let heading1: CGFloat = 32
    static let heading2: CGFloat = 28
    static let heading3: CGFloat = 24
    static let heading4: CGFloat = 20
    static let heading5: CGFloat = 16
    static let paragraph: CGFloat = 14
    static let caption: CGFloat = 12
}

// Ant Design boşluk değerleri
enum AntSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// Ant Design yuvarlak köşe değerleri
enum AntCornerRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 16
    static let xl: CGFloat = 16
}

// Ant Design gölge değerleri
enum AntShadow {
    static let level1: CGFloat = 0.05
    static let level2: CGFloat = 0.08
    static let level3: CGFloat = 0.12
}

// Ant Design buton stil değerleri
enum AntButtonStyle {
    case primary
    case secondary
    case warning
    case error
}

// Yardımcı renk uzantısı
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct Theme {
    // Ana Renkler
    static let blue400 = Color(hex: "008cf5")    // Canlı Mavi
    static let yellow400 = Color(hex: "fac400")  // Parlak Sarı
    static let pink400 = Color(hex: "ff16a2")    // Neon Pembe
    static let purple400 = Color(hex: "332a7c")  // Koyu Mor
    static let red400 = Color(hex: "ff2b05")     // Kırmızı
    
    // İkincil Renkler
    static let purple300 = Color(hex: "8675ff")  // Açık Mor
    static let purple200 = Color(hex: "baccfd")  // Çok Açık Mor
    static let green300 = Color(hex: "16dbcc")   // Canlı Turkuaz
    static let yellow300 = Color(hex: "ffbb38")  // Altın Sarı
    static let pink300 = Color(hex: "f44771")    // Parlak Pembe
    static let pink200 = Color(hex: "fd7289")    // Açık Pembe
    static let navy400 = Color(hex: "353e6c")    // Lacivert
    static let green200 = Color(hex: "dcfaf8")   // Açık Su Yeşili
    static let green400 = Color(hex: "00ab67")   // Yoğun Yeşil
    static let yellow200 = Color(hex: "fff5d9")  // Çok Açık Sarı
    static let blue500 = Color(hex: "2BCCFF")    // Açık Mavi

    // Gri Tonları
    static let gray600 = Color(hex: "4B5563")    // Koyu Gri
    static let gray400 = Color(hex: "9CA3AF")    // Orta Gri
    static let gray300 = Color(hex: "D1D5DB")    // Açık Gri
    static let gray100 = Color(hex: "F5F5F5")    // Çok Açık Gri

}


// Ant Design stil bileşenleri
struct AntCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AntSpacing.md)
            .background(Color.white)
            .cornerRadius(AntCornerRadius.md)
            .shadow(radius: 2, y: 1)
    }
}

struct AntButtonStyleModifier: ButtonStyle {
    let style: AntButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AntSpacing.md)
            .background(backgroundColor(for: style))
            .foregroundColor(foregroundColor(for: style))
            .cornerRadius(AntCornerRadius.md)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
    
    private func backgroundColor(for style: AntButtonStyle) -> Color {
        switch style {
        case .primary:
            return AntColors.primary
        case .secondary:
            return Color.white
        case .warning:
            return AntColors.warning
        case .error:
            return AntColors.error
        }
    }
    
    private func foregroundColor(for style: AntButtonStyle) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AntColors.text
        case .warning, .error:
            return .white
        }
    }
}

struct AntTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(AntSpacing.md)
            .background(Color.white)
            .cornerRadius(AntCornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AntCornerRadius.md)
                    .stroke(AntColors.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

struct AntLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AntSpacing.xs) {
            configuration.icon
                .foregroundColor(AntColors.primary)
            configuration.title
                .foregroundColor(AntColors.text)
        }
    }
}

// View uzantıları
extension View {
    func antCard() -> some View {
        modifier(AntCard())
    }
    
    func antButton(_ style: AntButtonStyle) -> some View {
        self.buttonStyle(AntButtonStyleModifier(style: style))
    }
    
    func mapButton(isSelected: Bool) -> some View {
        self
            .padding(.horizontal, AntSpacing.md)
            .padding(.vertical, AntSpacing.xs)
            .background(isSelected ? AntColors.primary : Color.white)
            .foregroundColor(isSelected ? .white : AntColors.text)
            .cornerRadius(AntCornerRadius.md)
    }
} 
