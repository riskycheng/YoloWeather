import SwiftUI

struct WeatherLocationHeaderView: View {
    let location: String
    let isLoading: Bool
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    private var fontSize: CGFloat {
        // 根据文本长度动态调整字体大小
        let length = location.count
        if length <= 3 {
            return 36  // 短地名（如"北京"）
        } else if length <= 4 {
            return 32  // 中短地名（如"上海市"）
        } else if length <= 6 {
            return 28  // 中等长度（如"大理市"）
        } else {
            return 24  // 长地名（如"大理白族自治州"）
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 位置名称
            Text(location)
                .font(.system(size: fontSize, weight: .regular))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
            // 加载状态
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.5) // 进一步减小最大宽度
        .shadow(color: .black.opacity(0.3), radius: 2)
    }
}

struct WeatherLocationHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ZStack {
                Color.blue
                WeatherLocationHeaderView(
                    location: "北京市",
                    isLoading: false
                )
            }
            .previewDisplayName("Short Name")
            
            ZStack {
                Color.blue
                WeatherLocationHeaderView(
                    location: "大理白族自治州",
                    isLoading: false
                )
            }
            .previewDisplayName("Long Name")
            
            ZStack {
                Color.blue
                WeatherLocationHeaderView(
                    location: "北京市",
                    isLoading: true
                )
            }
            .previewDisplayName("Loading")
        }
    }
}
