import SwiftUI

// Mor ağırlıklı modern renk paleti
enum AntColors {
    static let primary = Theme.purple400
    static let success = Theme.success
    static let warning = Theme.warning
    static let error = Theme.error
    
    // Nötr renkler
    static let text = Theme.gray800
    static let secondaryText = Theme.gray600
    static let disabledText = Color(hex: "#000000").opacity(0.25)
    static let border = Color(hex: "#E8E4FF")
    static let divider = Color(hex: "#F0F0FF")
    static let background = Color(hex: "F8F8FF")
    static let tableHeader = Color(hex: "#FAF8FF")
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
    // Ana Mor Renkler
    static let purple100 = Color(hex: "E8E4FF")    // En Açık Mor
    static let purple200 = Color(hex: "C4B8FF")    // Çok Açık Mor
    static let purple300 = Color(hex: "A394FF")    // Açık Mor
    static let purple400 = Color(hex: "8675FF")    // Ana Mor
    static let purple500 = Color(hex: "6B5BFF")    // Koyu Mor
    static let purple600 = Color(hex: "5A4BFF")    // Daha Koyu Mor

    // Gradyan Mor Renkler
    static let gradientPurple1 = Color(hex: "8675FF")
    static let gradientPurple2 = Color(hex: "9B8AFF")
    static let gradientPurple3 = Color(hex: "B09FFF")
    
    // Vurgu Renkler
    static let accentPink = Color(hex: "FF6B9D")   // Pembe Vurgu
    static let accentBlue = Color(hex: "4ECDC4")   // Turkuaz Vurgu
    static let accentYellow = Color(hex: "FFD93D") // Sarı Vurgu
    
    // Nötr Renkler
    static let gray900 = Color(hex: "1A1A2E")     // Çok Koyu
    static let gray800 = Color(hex: "2D2B55")     // Koyu
    static let gray700 = Color(hex: "4A4A6A")     // Orta Koyu
    static let gray600 = Color(hex: "6B6B8A")     // Orta
    static let gray500 = Color(hex: "8A8A9A")     // Orta Açık
    static let gray400 = Color(hex: "B8B8C8")     // Açık
    static let gray300 = Color(hex: "D1D1E0")     // Çok Açık
    static let gray200 = Color(hex: "E8E8F0")     // En Açık
    static let gray100 = Color(hex: "F8F8FF")     // Beyazımsı
    
    // Durum Renkleri
    static let success = Color(hex: "4ECDC4")     // Turkuaz
    static let warning = Color(hex: "FFD93D")     // Sarı
    static let error = Color(hex: "FF6B6B")       // Kırmızı
    static let info = Color(hex: "4A90E2")        // Mavi
    
    // Eski renkler (geriye uyumluluk için)
    static let blue400 = Color(hex: "4A90E2")     // Mavi
    static let yellow400 = Color(hex: "FFD93D")   // Güncellendi
    static let pink400 = Color(hex: "FF6B9D")     // Güncellendi
    static let red400 = Color(hex: "FF6B6B")      // Güncellendi
    static let green400 = Color(hex: "4ECDC4")    // Güncellendi
    static let navy400 = Color(hex: "2D2B55")     // Güncellendi
    static let orange400 = Color(hex: "FF8C42")   // Turuncu
    
    // Arka plan renkleri
    static let background = Color(hex: "F8F8FF")  // Ana arka plan
    static let secondaryBackground = Color(hex: "FFFFFF") // İkincil arka plan
    
    // Ana renkler (geriye uyumluluk için)
    static let primary = purple400    // Ana mor renk
    static let secondary = gray600     // İkincil renk
}

// Mor ağırlıklı stil bileşenleri
struct AntCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AntSpacing.md)
            .background(Color.white)
            .cornerRadius(AntCornerRadius.lg)
            .shadow(color: Theme.purple200.opacity(0.1), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AntCornerRadius.lg)
                    .stroke(Theme.purple100, lineWidth: 1)
            )
    }
}

struct AntButtonStyleModifier: ButtonStyle {
    let style: AntButtonStyle
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(AntSpacing.md)
            .background(backgroundColor(for: style))
            .foregroundColor(foregroundColor(for: style))
            .cornerRadius(AntCornerRadius.lg)
            .shadow(color: Theme.purple200.opacity(0.2), radius: 4, x: 0, y: 2)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
    
    private func backgroundColor(for style: AntButtonStyle) -> Color {
        switch style {
        case .primary:
            return Theme.purple400
        case .secondary:
            return Color.white
        case .warning:
            return Theme.warning
        case .error:
            return Theme.error
        }
    }
    
    private func foregroundColor(for style: AntButtonStyle) -> Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Theme.purple600
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
            .cornerRadius(AntCornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AntCornerRadius.lg)
                    .stroke(Theme.purple200, lineWidth: 1.5)
            )
    }
}

struct AntLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: AntSpacing.xs) {
            configuration.icon
                .foregroundColor(Theme.purple400)
            configuration.title
                .foregroundColor(Theme.gray800)
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
            .background(isSelected ? Theme.purple400 : Color.white)
            .foregroundColor(isSelected ? .white : Theme.purple600)
            .cornerRadius(AntCornerRadius.lg)
            .shadow(color: Theme.purple200.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    // Mor gradyan arka plan
    func purpleGradientBackground() -> some View {
        self.background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.gradientPurple1,
                    Theme.gradientPurple2,
                    Theme.gradientPurple3
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // Mor gölge efekti
    func purpleShadow() -> some View {
        self.shadow(color: Theme.purple200.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
} 
