import SwiftUI

// 导入WeatherInfo模型
struct GlassBubbleView: View {
    let info: WeatherInfo
    @State private var offset: CGSize = .zero
    
    // 气泡尺寸范围
    private let minSize: CGFloat = 70
    private let maxSize: CGFloat = 85
    private let bubbleSize: CGFloat
    
    init(info: WeatherInfo) {
        self.info = info
        // 在初始化时确定气泡大小
        self.bubbleSize = CGFloat.random(in: minSize...maxSize)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 主背景 - 磨砂玻璃效果
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.5),
                                        .clear,
                                        .white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // 3D 反光效果层
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.7),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .scaleEffect(0.85)
                    .blur(radius: 1)
                
                // 内容层
                VStack(spacing: 4) {
                    Text(info.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(info.value)
                            .font(.system(size: 18, weight: .bold))
                        Text(info.unit)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            .offset(offset)
            .animation(
                Animation.easeInOut(duration: 3)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2)), // 随机延迟，使气泡运动不同步
                value: offset
            )
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .onAppear {
            // 设置随机的轻微浮动范围
            let floatingRange: CGFloat = 8
            offset = CGSize(
                width: CGFloat.random(in: -floatingRange...floatingRange),
                height: CGFloat.random(in: -floatingRange...floatingRange)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        GlassBubbleView(
            info: WeatherInfo(
                title: "风速",
                value: "3.2",
                unit: "km/h"
            )
        )
    }
} 