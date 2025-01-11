import SwiftUI
import WeatherKit

struct WeatherInfo {
    let title: String
    let value: String
    let unit: String
}

struct WeatherBubbleView: View {
    let info: WeatherInfo
    @State private var offset: CGSize = .zero
    let initialPosition: CGPoint
    
    init(info: WeatherInfo, initialPosition: CGPoint) {
        self.info = info
        self.initialPosition = initialPosition
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(info.title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(info.value)
                    .font(.system(size: 16, weight: .medium))
                Text(info.unit)
                    .font(.system(size: 10))
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Circle()
                .fill(Color.white.opacity(0.12))
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
        }
        .offset(x: initialPosition.x + offset.width, y: initialPosition.y + offset.height)
        .animation(
            Animation.easeInOut(duration: 5)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...3)),
            value: offset
        )
        .onAppear {
            // 减小浮动范围，避免与其他元素重叠
            let randomOffset = CGSize(
                width: CGFloat.random(in: -12...12),
                height: CGFloat.random(in: -12...12)
            )
            offset = randomOffset
        }
    }
}

struct WeatherBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            WeatherBubbleView(
                info: WeatherInfo(title: "风速", value: "3.2", unit: "km/h"),
                initialPosition: CGPoint(x: 0, y: 0)
            )
        }
    }
}
