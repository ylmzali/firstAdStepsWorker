//
//  Helpers.swift
//  re-brick-app-1
//
//  Created by Ali YILMAZ on 25.05.2025.
//
import SwiftUI

struct DismissKeyboardOnTap: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false // Butonlar ve diğer etkileşimli alanlar çalışmaya devam eder
        view.addGestureRecognizer(tap)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.background(DismissKeyboardOnTap())
    }
}

struct BorderModifier: ViewModifier {
    var color: Color
    var width: CGFloat
    var cornerRadius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
}

extension View {
    func customBorder(color: Color, width: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        self.modifier(BorderModifier(color: color, width: width, cornerRadius: cornerRadius))
    }
}

// Kullanım örneği:
// .customBorder(color: .red, width: 2)





// Köşe yuvarlama için yardımcı extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}








/*
 // Drop shadow
 .background(
     Color
         .white
         .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
 )
 
 
 
 // gradient bg
 LinearGradient(
     gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
     startPoint: .top,
     endPoint: .bottom
 )
 .ignoresSafeArea()
 
 
 
 
 
 
 
 
 // MARK: - Supporting Views
 struct EnhancedStatCard: View {
     let title: String
     let value: String
     let icon: String
     let color: Color
     let animate: Bool
     
     var body: some View {
         VStack(spacing: 12) {
             Image(systemName: icon)
                 .font(.system(size: 28))
                 .foregroundColor(color)
                 .frame(width: 50, height: 50)
                 .background(color.opacity(0.1))
                 .clipShape(Circle())
             
             Text(value)
                 .font(.system(size: 28, weight: .bold))
                 .foregroundColor(.primary)
                 .opacity(animate ? 1 : 0)
                 .offset(y: animate ? 0 : 20)
             
             Text(title)
                 .font(.system(size: 14, weight: .medium))
                 .foregroundColor(.secondary)
         }
         .frame(maxWidth: .infinity)
         .padding()
         .background(Color.white)
         .cornerRadius(16)
         .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
     }
 }
 // kullanimi
 EnhancedStatCard(
     title: "Aktif",
     value: "\(routeViewModel.routes.filter { $0.status == .active }.count)",
     icon: "figure.walk",
     color: .green,
     animate: animateStats
 )
 
 
 
 
 
 
 struct EnhancedQuickAccessCard: View {
     let title: String
     let subtitle: String
     let icon: String
     let color: Color
     
     var body: some View {
         VStack(alignment: .leading, spacing: 12) {
             Image(systemName: icon)
                 .font(.system(size: 24))
                 .foregroundColor(color)
             
             VStack(alignment: .leading, spacing: 4) {
                 Text(title)
                     .font(.system(size: 16, weight: .semibold))
                 
                 Text(subtitle)
                     .font(.system(size: 12))
                     .foregroundColor(.secondary)
             }
         }
         .frame(width: 120, height: 100)
         .padding()
         .background(Color.white)
         .cornerRadius(16)
         .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
     }
 }
 // kullanimi
 EnhancedQuickAccessCard(
     title: "Yeni Rota",
     subtitle: "Oluştur",
     icon: "plus.circle.fill",
     color: .blue
 )
 
 
 
 
 
 struct EnhancedTabBarButton: View {
     let title: String
     let icon: String
     let isSelected: Bool
     let action: () -> Void
     
     var body: some View {
         Button(action: action) {
             VStack(spacing: 4) {
                 Image(systemName: icon)
                     .font(.system(size: 24))
                 Text(title)
                     .font(.system(size: 12, weight: .medium))
             }
             .foregroundColor(isSelected ? .blue : .gray)
             .frame(maxWidth: .infinity)
             .padding(.vertical, 8)
             .background(
                 isSelected ?
                 Color.blue.opacity(0.1) :
                 Color.clear
             )
         }
     }
 }
 // kullanimi
 EnhancedTabBarButton(
     title: "Rotalar",
     icon: "list.bullet",
     isSelected: selectedTab == 0
 ) {
     withAnimation {
         selectedTab = 0
     }
 }
 */
