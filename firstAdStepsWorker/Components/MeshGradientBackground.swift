//
//  MeshGradientBackground.swift
//  firstAdStepsEmp2
//
//  Created by Ali YILMAZ on 17.06.2025.
//

import SwiftUI

struct MeshGradientBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Blob 1
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.9), Color.blue.opacity(0.7)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 220, height: 220)
                .offset(x: animate ? -60 : 40, y: animate ? -80 : 30)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)

            // Blob 2
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.9), Color.red.opacity(0.8)]),
                    startPoint: .top, endPoint: .bottomTrailing))
                .frame(width: 180, height: 180)
                .offset(x: animate ? 80 : -40, y: animate ? 60 : -50)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)

            // Blob 3
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.cyan.opacity(0.9), Color.green.opacity(0.8)]),
                    startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 200, height: 200)
                .offset(x: animate ? 40 : -60, y: animate ? 100 : -80)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
    }
}

struct MeshGradientBackgroundDark: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Blob 1
            Circle()
                .fill(RadialGradient(colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.7)], center: UnitPoint.bottom, startRadius: 180, endRadius: 180))
                .frame(width: 320, height: 320)
                .offset(x: animate ? -60 : 40, y: animate ? -80 : 30)
                .blur(radius: 20)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)

            // Blob 2
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.7), Color.red.opacity(0.8)]),
                    startPoint: .top, endPoint: .bottomTrailing))
                .frame(width: 380, height: 380)
                .offset(x: animate ? 80 : -40, y: animate ? 60 : -50)
                .blur(radius: 30)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: animate)

            // Blob 3
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.yellow.opacity(0.8)]),
                    startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 300, height: 300)
                .offset(x: animate ? 40 : -80, y: animate ? 100 : -100)
                .blur(radius: 50)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
    }
}


struct MeshGradientBackgroundAnimated: View {
    @State private var isAnimate = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AngularGradient(colors: [Color.pink, Color.blue], center: .center, angle: Angle.degrees(isAnimate ? 360 : 0)))
                .blur(radius: 20)
                .onAppear {
                    withAnimation(Animation.linear(duration: 7).repeatForever(autoreverses: false)) {
                        isAnimate = true
                    }
                }
        }
    }
}


#Preview {
    MeshGradientBackgroundAnimated()
}
