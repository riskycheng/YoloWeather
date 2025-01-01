import SwiftUI

struct WeatherLocationHeaderView: View {
    let location: String
    let isLoading: Bool
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        VStack(spacing: 4) {
            // 位置名称
            Text(location)
                .font(.title)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
            // 加载状态
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
        }
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
            .previewDisplayName("Not Loading")
            
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
