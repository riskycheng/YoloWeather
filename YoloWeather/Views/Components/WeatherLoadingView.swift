import SwiftUI

struct WeatherLoadingView: View {
    @State private var isAnimating = false
    @State private var sunRotation = 0.0
    @State private var sunScale: CGFloat = 1.0
    @State private var cloudOffset1: CGFloat = 0
    @State private var cloudOffset2: CGFloat = 0
    @State private var cloudOpacity1: Double = 0
    @State private var cloudOpacity2: Double = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 旋转光环
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
            
            // 太阳
            Image(systemName: "sun.max.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 60))
                .rotationEffect(.degrees(sunRotation))
                .scaleEffect(sunScale)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).repeatForever(autoreverses: true), value: sunScale)
            
            // 云朵1
            Image(systemName: "cloud.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white.opacity(0.8))
                .font(.system(size: 40))
                .offset(x: cloudOffset1)
                .opacity(cloudOpacity1)
                .offset(y: -35)
            
            // 云朵2
            Image(systemName: "cloud.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white.opacity(0.6))
                .font(.system(size: 35))
                .offset(x: cloudOffset2)
                .opacity(cloudOpacity2)
                .offset(y: 35)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            
            // 启动所有动画
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                sunRotation = 360
            }
            
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                sunScale = 1.1
            }
            
            // 云朵1的动画
            withAnimation(.easeInOut(duration: 0.8)) {
                cloudOpacity1 = 1
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(0.5)) {
                cloudOffset1 = 50
            }
            
            // 云朵2的动画
            withAnimation(.easeInOut(duration: 0.8)) {
                cloudOpacity2 = 1
            }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                cloudOffset2 = -50
            }
            
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
            .ignoresSafeArea()
        WeatherLoadingView()
    }
} 