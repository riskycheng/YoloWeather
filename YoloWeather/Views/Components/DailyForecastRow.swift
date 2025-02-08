import SwiftUI
import WeatherKit

struct DailyForecastRow: View {
    let forecast: DayWeatherInfo
    let precipitationProbability: Double?
    
    init(forecast: DayWeatherInfo, precipitationProbability: Double? = nil) {
        self.forecast = forecast
        self.precipitationProbability = precipitationProbability
    }
    
    private var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    private func getWeatherSymbol(for condition: String) -> String {
        switch condition {
        case "晴":
            return "sun.max.fill"
        case "多云":
            return "cloud.fill"
        case "阴":
            return "cloud.fill"
        case "小雨":
            return "cloud.drizzle.fill"
        case "中雨":
            return "cloud.rain.fill"
        case "大雨":
            return "cloud.heavyrain.fill"
        case "雷阵雨":
            return "cloud.bolt.rain.fill"
        case "小雪":
            return "cloud.snow.fill"
        case "中雪":
            return "cloud.snow.fill"
        case "大雪":
            return "cloud.snow.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private func temperatureGradient(lowTemp: Double, highTemp: Double) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let minTemp = min(lowTemp, highTemp)
            let maxTemp = max(lowTemp, highTemp)
            let tempRange = maxTemp - minTemp
            let startPoint = max(0.1, (lowTemp - minTemp) / tempRange)
            let endPoint = min(0.9, (highTemp - minTemp) / tempRange)
            
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.cyan.opacity(0.6),
                    Color.green.opacity(0.6)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * CGFloat(endPoint - startPoint))
            .frame(width: width, alignment: .leading)
            .offset(x: width * CGFloat(startPoint))
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Day of week
            Text(dayFormatter.string(from: forecast.date))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 50, alignment: .leading)
            
            // Weather icon and precipitation probability
            VStack(alignment: .center, spacing: 2) {
                Image(systemName: getWeatherSymbol(for: forecast.condition))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                if let probability = precipitationProbability, probability > 0 {
                    Text("\(Int(probability * 100))%")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan)
                }
            }
            .frame(width: 40)
            
            // Add spacing before temperature range
            Spacer()
                .frame(width: 20)
            
            // Temperature range with gradient bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // Gradient temperature bar
                    temperatureGradient(
                        lowTemp: forecast.lowTemperature,
                        highTemp: forecast.highTemperature
                    )
                    .clipShape(Capsule())
                    .frame(height: 4)
                }
                .frame(height: geometry.size.height)
                .overlay(
                    HStack(spacing: 0) {
                        Text("\(Int(forecast.lowTemperature))°")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 45, alignment: .trailing)
                        
                        Spacer()
                            .frame(width: geometry.size.width - 100)
                        
                        Text("\(Int(forecast.highTemperature))°")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 45, alignment: .leading)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}
