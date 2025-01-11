import SwiftUI

struct GlassBubbleView: View {
    let info: WeatherInfo
    let initialPosition: CGPoint
    @State private var position: CGPoint
    @State private var isExpanded = false
    @State private var isLongPressed = false
    @State private var floatingOffset: CGSize = .zero
    
    // 气泡尺寸范围
    private let minSize: CGFloat = 65
    private let maxSize: CGFloat = 75
    private let bubbleSize: CGFloat
    private let expandedScale: CGFloat = 1.3
    private let longPressScale: CGFloat = 1.15
    
    init(info: WeatherInfo, initialPosition: CGPoint) {
        self.info = info
        self.initialPosition = initialPosition
        self._position = State(initialValue: initialPosition)
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
                    
                    // 展开时显示的额外信息
                    if isExpanded {
                        VStack(spacing: 4) {
                            Divider()
                                .background(.white.opacity(0.3))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                            
                            // 这里可以根据不同类型的信息显示不同的详情
                            switch info.title {
                            case "风速":
                                Text("微风")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            case "湿度":
                                Text("潮湿")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            case "降水概率":
                                Text("可能降水")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            default:
                                EmptyView()
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(isLongPressed ? longPressScale : (isExpanded ? expandedScale : 1.0))
            .offset(floatingOffset)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .gesture(
                LongPressGesture(minimumDuration: 0.3)
                    .onEnded { _ in
                        isLongPressed = true
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isLongPressed = false
                            }
                        }
                    }
            )
            .onAppear {
                // 启动浮动动画
                withAnimation(
                    Animation
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2))
                ) {
                    floatingOffset = CGSize(
                        width: CGFloat.random(in: -5...5),
                        height: CGFloat.random(in: -5...5)
                    )
                }
            }
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
            ),
            initialPosition: CGPoint(x: 100, y: 100)
        )
    }
} 