import SwiftUI

struct GlassBubbleView: View {
    let info: WeatherInfo
    let initialPosition: CGPoint
    let timeOfDay: WeatherTimeOfDay
    @State private var position: CGPoint
    @State private var isExpanded = false
    @State private var isLongPressed = false
    @State private var autoCollapseTask: Task<Void, Never>?
    
    // 气泡尺寸范围
    private let bubbleSize: CGFloat = 75
    private let expandedScale: CGFloat = 1.2
    private let autoCollapseDelay: TimeInterval = 3.0 // 3秒后自动收起
    
    // 获取额外描述信息
    private var extraDescription: String? {
        switch info.title {
        case "风速":
            if let speed = Double(info.value) {
                if speed < 5 {
                    return "微风"
                } else if speed < 10 {
                    return "和风"
                } else if speed < 20 {
                    return "清风"
                } else if speed < 30 {
                    return "强风"
                } else {
                    return "大风"
                }
            }
        case "降水概率":
            if let probability = Double(info.value) {
                if probability == 0 {
                    return "可能晴天"
                } else if probability < 30 {
                    return "可能降水"
                } else if probability < 60 {
                    return "较可能降水"
                } else {
                    return "很可能降水"
                }
            }
        case "湿度":
            if let humidity = Double(info.value) {
                if humidity < 30 {
                    return "干燥"
                } else if humidity < 60 {
                    return "适宜"
                } else if humidity < 80 {
                    return "潮湿"
                } else {
                    return "非常潮湿"
                }
            }
        default:
            return nil
        }
        return nil
    }
    
    init(info: WeatherInfo, initialPosition: CGPoint, timeOfDay: WeatherTimeOfDay) {
        self.info = info
        self.initialPosition = initialPosition
        self.timeOfDay = timeOfDay
        self._position = State(initialValue: initialPosition)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func scheduleAutoCollapse() {
        // 取消之前的任务
        autoCollapseTask?.cancel()
        
        // 创建新的自动收起任务
        autoCollapseTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(autoCollapseDelay * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded = false
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 主背景
                Circle()
                    .fill(.white.opacity(timeOfDay == .day ? 0.5 : 0.2))
                    .shadow(
                        color: timeOfDay == .day ? .white.opacity(0.3) : .black.opacity(0.1),
                        radius: timeOfDay == .day ? 8 : 10,
                        x: 0,
                        y: timeOfDay == .day ? 2 : 5
                    )
                
                // 反光效果
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(timeOfDay == .day ? 0.95 : 0.4),
                                .white.opacity(timeOfDay == .day ? 0.6 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(0.95)
                
                // 内容
                VStack(spacing: 2) {
                    Text(info.title)
                        .font(.system(size: 12))
                        .foregroundColor(timeOfDay == .day ? .black.opacity(0.4) : .white)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(info.value)
                            .font(.system(size: 17, weight: .medium))
                        Text(info.unit)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(timeOfDay == .day ? .black.opacity(0.5) : .white)
                    
                    if isExpanded, let description = extraDescription {
                        // 分割线
                        HStack {
                            Spacer()
                                .frame(width: 12)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: timeOfDay == .day ? [
                                            .black.opacity(0.05),
                                            .black.opacity(0.25),
                                            .black.opacity(0.05)
                                        ] : [
                                            .white.opacity(0),
                                            .white.opacity(0.3),
                                            .white.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)
                                .frame(maxWidth: bubbleSize * 0.75)
                                .overlay(
                                    timeOfDay == .day ?
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 1, green: 1, blue: 1, opacity: 0.3),
                                                    Color(red: 1, green: 1, blue: 1, opacity: 0.8),
                                                    Color(red: 1, green: 1, blue: 1, opacity: 0.3)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 1)
                                        .frame(maxWidth: bubbleSize * 0.75)
                                        .blendMode(.softLight)
                                    : nil
                                )
                                .background(
                                    timeOfDay == .day ?
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .black.opacity(0),
                                                    .black.opacity(0.05),
                                                    .black.opacity(0)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 3)
                                        .frame(maxWidth: bubbleSize * 0.8)
                                        .blur(radius: 0.5)
                                    : nil
                                )
                            
                            Spacer()
                                .frame(width: 12)
                        }
                        .padding(.vertical, 4)
                        
                        Text(description)
                            .font(.system(size: 10))
                            .foregroundColor(timeOfDay == .day ? .black.opacity(0.6) : .white.opacity(0.8))
                            .padding(.top, 1)
                    }
                }
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .scaleEffect(isExpanded ? expandedScale : 1.0)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                    }
            )
            .onTapGesture {
                triggerHaptic()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    scheduleAutoCollapse()
                } else {
                    autoCollapseTask?.cancel()
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isLongPressed.toggle()
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
            initialPosition: CGPoint(x: 100, y: 100),
            timeOfDay: .day
        )
    }
}