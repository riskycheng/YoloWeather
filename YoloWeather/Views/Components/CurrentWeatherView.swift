import SwiftUI

struct CurrentWeatherView: View {
    let location: String
    let weather: WeatherInfo
    let isAnimating: Bool
    let dailyForecast: [DayWeatherInfo]
    
    var body: some View {
        VStack(spacing: 20) {
            // Location
            Text(location)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Large temperature display
            Text("\(Int(round(weather.temperature)))")
                .font(.system(size: 180, weight: .thin))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            // Weather condition
            Text(weather.condition)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let todayForecast = dailyForecast.first {
                // Simple temperature range
                Text("\(Int(round(todayForecast.lowTemperature)))° — \(Int(round(todayForecast.highTemperature)))°")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
