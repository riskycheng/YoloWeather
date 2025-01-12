import SwiftUI

struct GlassBubbleView: View {
    let info: WeatherInfo
    let initialPosition: CGPoint
    let timeOfDay: WeatherTimeOfDay
    @State private var position: CGPoint
    @State private var isExpanded = false
    @State private var isLongPressed = false
    @State private var floatingOffset: CGSize = .zero
    @State private var floatingAnimation: Animation? = nil
    
    // 气泡尺寸范围
    private let minSize: CGFloat = 70  // 基础最小尺寸
    private let maxSize: CGFloat = 85  // 基础最大尺寸
    private let bubbleSize: CGFloat
    private let expandedScale: CGFloat = 1.45  // 保持相同的展开比例
    private let longPressScale: CGFloat = 1.08  // 减小长按比例
    
    // 计算气泡尺寸
    private static func calculateSize(for title: String) -> CGFloat {
        let baseSize: CGFloat
        switch title {
        case "风速":
            baseSize = 80  // 风速信息较长，需要更大空间
        case "湿度":
            baseSize = 70   // 湿度信息较短
        case "降水概率":
            baseSize = 75  // 降水概率中等长度
        default:
            baseSize = 70
        }
        return min(85, max(70, baseSize))  // 使用硬编码值避免self访问
    }
    
    init(info: WeatherInfo, initialPosition: CGPoint, timeOfDay: WeatherTimeOfDay) {
        self.info = info
        self.initialPosition = initialPosition
        self.timeOfDay = timeOfDay
        self._position = State(initialValue: initialPosition)
        self.bubbleSize = Self.calculateSize(for: info.title)
    }
    
    private var textColor: Color {
        timeOfDay == .day ? .black.opacity(0.7) : .white
    }
    
    private var glassOpacity: Double {
        timeOfDay == .day ? 0.7 : 0.5
    }
    
    private var glassMaterial: Material {
        timeOfDay == .day ? .ultraThinMaterial : .ultraThinMaterial
    }
    
    private var glassStrokeGradient: LinearGradient {
        if timeOfDay == .day {
            return LinearGradient(
                colors: [
                    .black.opacity(0.3),
                    .clear,
                    .black.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    .white.opacity(0.5),
                    .clear,
                    .white.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var reflectionGradient: LinearGradient {
        if timeOfDay == .day {
            return LinearGradient(
                colors: [
                    Color(red: 1, green: 1, blue: 1).opacity(0.95),  // 明亮的白色
                    Color(red: 0.95, green: 0.95, blue: 1).opacity(0.7),  // 带一点蓝色的白
                    Color(red: 0.9, green: 0.95, blue: 1).opacity(0.4),  // 淡蓝色
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.8, green: 0.9, blue: 1).opacity(0.8),  // 带蓝色的反光
                    Color(red: 0.7, green: 0.8, blue: 1).opacity(0.5),  // 较暗的蓝色
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var secondaryReflectionGradient: LinearGradient {
        if timeOfDay == .day {
            return LinearGradient(
                colors: [
                    .clear,
                    Color(red: 1, green: 1, blue: 0.95).opacity(0.4),  // 带一点黄色的反光
                    Color(red: 1, green: 1, blue: 0.9).opacity(0.6),
                    .clear
                ],
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
        } else {
            return LinearGradient(
                colors: [
                    .clear,
                    Color(red: 0.6, green: 0.8, blue: 1).opacity(0.3),  // 蓝色反光
                    Color(red: 0.5, green: 0.7, blue: 1).opacity(0.4),
                    .clear
                ],
                startPoint: .bottomTrailing,
                endPoint: .topLeading
            )
        }
    }
    
    private var highlightGradient: LinearGradient {
        if timeOfDay == .day {
            return LinearGradient(
                colors: [
                    Color(red: 1, green: 1, blue: 0.9).opacity(0.9),  // 温暖的高光
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.7, green: 0.8, blue: 1).opacity(0.7),  // 冷色调高光
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
    }
    
    private var effectiveSize: CGFloat {
        isExpanded ? bubbleSize * expandedScale : bubbleSize
    }
    
    private func startFloatingAnimation() {
        // 创建随机的浮动动画
        let randomDuration = Double.random(in: 2.5...3.5)
        let randomOffset = CGFloat.random(in: -5...5)
        
        withAnimation(Animation.easeInOut(duration: randomDuration).repeatForever(autoreverses: true)) {
            floatingOffset = CGSize(width: randomOffset, height: randomOffset)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 主背景 - 磨砂玻璃效果
                Circle()
                    .fill(glassMaterial)
                    .overlay {
                        Circle()
                            .stroke(
                                glassStrokeGradient,
                                lineWidth: 1
                            )
                    }
                    .shadow(color: timeOfDay == .day ? .black.opacity(0.15) : .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // 主反光效果层
                Circle()
                    .fill(reflectionGradient)
                    .scaleEffect(0.95)
                
                // 次要反光效果层
                Circle()
                    .fill(secondaryReflectionGradient)
                    .scaleEffect(0.92)
                
                // 高光效果层
                Circle()
                    .fill(highlightGradient)
                    .scaleEffect(0.7)
                    .offset(x: -5, y: -5)
                    .blur(radius: 2)
                
                // 额外的小高光点
                Circle()
                    .fill(.white.opacity(timeOfDay == .day ? 0.8 : 0.6))
                    .frame(width: 10, height: 10)
                    .offset(x: -15, y: -15)
                    .blur(radius: 1)
                
                // 内容层
                VStack(spacing: isExpanded ? 2 : 3) {  
                    Text(info.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor.opacity(0.8))
                        .lineLimit(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(info.value)
                            .font(.system(size: isExpanded ? 17 : 17, weight: .bold))  
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(info.unit)
                            .font(.system(size: isExpanded ? 9 : 9, weight: .medium))  
                            .lineLimit(1)
                    }
                    .foregroundColor(textColor)
                    
                    // 展开时显示的额外信息
                    if isExpanded {
                        VStack(spacing: 1) {  
                            Divider()
                                .background(textColor.opacity(0.3))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 0)  
                            
                            // 这里可以根据不同类型的信息显示不同的详情
                            switch info.title {
                            case "风速":
                                Text("微风")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .lineLimit(1)
                            case "湿度":
                                Text("潮湿")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .lineLimit(1)
                            case "降水概率":
                                Text("可能降水")
                                    .font(.system(size: 10))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .lineLimit(1)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.top, 0)  
                    }
                }
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: effectiveSize * 0.7)
                .padding(.horizontal, isExpanded ? 8 : 6)
                .padding(.vertical, isExpanded ? 4 : 4)  
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(isExpanded ? expandedScale : (isLongPressed ? longPressScale : 1.0))
            .offset(floatingOffset)  // 添加浮动效果
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
                startFloatingAnimation()  // 开始浮动动画
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
            initialPosition: CGPoint(x: 100, y: 100),
            timeOfDay: .day
        )
    }
}