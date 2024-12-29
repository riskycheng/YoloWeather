import SwiftUI

struct CurrentWeatherView: View {
    let location: String
    let weather: WeatherInfo
    let isAnimating: Bool
    let dailyForecast: [DayWeatherInfo]
    
    var body: some View {
        VStack(spacing: 10) {
            // Location with animation
            Text(location)
                .font(.system(size: 44, weight: .light))
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            // Weather icon with rotation animation
            Image(systemName: weather.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 120))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
            
            // Temperature with scale animation
            Text("\(Int(round(weather.temperature)))°")
                .font(.system(size: 120, weight: .thin))
                .scaleEffect(isAnimating ? 1 : 0.5)
            
            // Condition with fade animation
            Text(weather.condition)
                .font(.title)
                .foregroundStyle(.secondary)
                .opacity(isAnimating ? 1 : 0)
            
            // High/Low with slide animation
            if let todayForecast = dailyForecast.first {
                HStack(spacing: 30) {
                    Label("H: \(Int(round(todayForecast.highTemperature)))°", 
                          systemImage: "arrow.up")
                    Label("L: \(Int(round(todayForecast.lowTemperature)))°", 
                          systemImage: "arrow.down")
                }
                .font(.title2)
                .foregroundStyle(.secondary)
                .offset(x: isAnimating ? 0 : -100)
            }
        }
        .padding(.top, 50)
    }
}
