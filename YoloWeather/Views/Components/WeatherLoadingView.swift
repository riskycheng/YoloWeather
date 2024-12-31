import SwiftUI

struct WeatherLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 加载动画
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(lineWidth: 8)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white.opacity(0.2))
                
                // 动画圆环
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.8), .white.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                
                // 天气图标
                Image(systemName: "cloud.sun.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 30))
                    .opacity(0.8)
            }
            
            Text("正在获取天气信息...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        Color.black
        WeatherLoadingView()
    }
} 