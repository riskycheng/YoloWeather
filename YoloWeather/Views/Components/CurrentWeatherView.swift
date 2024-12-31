import SwiftUI

struct TemperatureRangeView: View {
    let lowTemp: Double
    let highTemp: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(lowTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
            
            Text("—")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 8)
            
            Image(systemName: "arrow.up")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(highTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
        }
        .overlay {
            Capsule()
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct LocationHeaderView: View {
    let location: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .imageScale(.medium)
                .foregroundStyle(.white.opacity(0.9))
            
            Text(location)
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
                .overlay {
                    Capsule()
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 0.5)
                }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct CurrentWeatherView: View {
    let location: String
    let weather: WeatherInfo
    let isAnimating: Bool
    let dailyForecast: [DayWeatherInfo]
    
    var body: some View {
        VStack(spacing: 20) {
            // Location
            LocationHeaderView(location: location)
                .transition(.move(edge: .top).combined(with: .opacity))
            
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
                TemperatureRangeView(
                    lowTemp: todayForecast.lowTemperature,
                    highTemp: todayForecast.highTemperature
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    ZStack {
        Color.black
        CurrentWeatherView(
            location: "Shanghai",
            weather: WeatherInfo(
                date: Date(),
                temperature: 25,
                condition: "Sunny",
                symbolName: "sun.max.fill"
            ),
            isAnimating: true,
            dailyForecast: [
                DayWeatherInfo(
                    date: Date(),
                    condition: "Sunny",
                    symbolName: "sun.max.fill",
                    lowTemperature: 20,
                    highTemperature: 28
                )
            ]
        )
    }
}
