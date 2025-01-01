import SwiftUI

struct WeatherTagView: View {
    let weather: CurrentWeather
    let tag: WeatherTag
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    @State private var isPressed = false
    
    private var value: String {
        switch tag {
        case .temperature:
            return String(format: "%.0f°", weather.temperature)
        case .feelsLike:
            return String(format: "%.0f°", weather.feelsLike)
        case .windSpeed:
            return String(format: "%.1f m/s", weather.windSpeed)
        case .rainProbability:
            return String(format: "%.0f%%", weather.precipitationChance * 100)
        case .uvIndex:
            return String(weather.uvIndex)
        case .humidity:
            return String(format: "%.0f%%", weather.humidity * 100)
        case .pressure:
            return String(format: "%.0f hPa", weather.pressure)
        case .visibility:
            return String(format: "%.1f km", weather.visibility)
        case .airQuality:
            return String(weather.airQualityIndex)
        }
    }
    
    var body: some View {
        HStack {
            // 标签名称
            Label(tag.name, systemImage: tag.iconName)
                .font(.system(.body, design: .rounded))
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            // 数值显示
            Text(value)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                .frame(minWidth: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.2))
        }
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    WeatherTagManager.shared.toggleTag(tag)
                }
        )
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
