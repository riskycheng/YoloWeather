import SwiftUI
import WeatherKit

struct WeatherTagView: View {
    let weather: CurrentWeather
    let tag: WeatherTag
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: tag.iconName)
                .font(.title2)
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // 标题
                Text(tag.name)
                    .font(.subheadline)
                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.7))
                
                // 数值
                Text(tag.getValue(from: weather))
                    .font(.title3.monospaced())
                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
            
            Spacer()
            
            // 单位
            Text(tag.unit)
                .font(.caption)
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.5))
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct WeatherTagView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            WeatherTagView(
                weather: CurrentWeather.mock(temp: 23, condition: "晴", symbol: "sun.max"),
                tag: .temperature
            )
            WeatherTagView(
                weather: CurrentWeather.mock(temp: 23, condition: "晴", symbol: "sun.max"),
                tag: .humidity
            )
        }
        .padding()
        .background(Color.blue)
    }
}
