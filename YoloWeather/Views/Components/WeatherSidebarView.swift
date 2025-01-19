import SwiftUI
import WeatherKit

struct WeatherSidebarView: View {
    let weather: WeatherService.CurrentWeather?
    let timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        VStack(spacing: 20) {
            // 时间显示
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(Date()))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text(weather?.temperature.formatted(.number.precision(.fractionLength(0))) ?? "--" + "°")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // 天气指标
            VStack(spacing: 16) {
                WeatherIndicatorBubble(
                    title: "风速",
                    value: String(format: "%.1f", weather?.windSpeed ?? 0),
                    unit: "km/h",
                    isSelected: true
                )
                
                WeatherIndicatorBubble(
                    title: "气压",
                    value: String(format: "%.0f", weather?.pressure ?? 0),
                    unit: "hPa",
                    isSelected: true
                )
                
                WeatherIndicatorBubble(
                    title: "紫外线",
                    value: "\(weather?.uvIndex ?? 0)",
                    unit: "",
                    isSelected: false
                )
                
                WeatherIndicatorBubble(
                    title: "能见度",
                    value: String(format: "%.1f", weather?.visibility ?? 0),
                    unit: "km",
                    isSelected: false
                )
            }
        }
        .padding(.vertical, 20)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct WeatherIndicatorBubble: View {
    let title: String
    let value: String
    let unit: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .medium))
                Text(unit)
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isSelected ? 0.15 : 0.1))
        )
    }
} 