import SwiftUI

struct GlassBubbleView: View {
    let info: WeatherInfo
    let initialPosition: CGPoint
    let timeOfDay: WeatherTimeOfDay
    @State private var position: CGPoint
    @State private var isExpanded = false
    @State private var isLongPressed = false
    
    // 气泡尺寸范围
    private let bubbleSize: CGFloat = 75
    
    init(info: WeatherInfo, initialPosition: CGPoint, timeOfDay: WeatherTimeOfDay) {
        self.info = info
        self.initialPosition = initialPosition
        self.timeOfDay = timeOfDay
        self._position = State(initialValue: initialPosition)
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
                }
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                    }
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
            ),
            initialPosition: CGPoint(x: 100, y: 100),
            timeOfDay: .day
        )
    }
}