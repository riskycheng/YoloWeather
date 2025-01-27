import SwiftUI
import WeatherKit

struct DailyForecastRow: View {
    let forecast: DayWeatherInfo
    
    init(forecast: DayWeatherInfo) {
        self.forecast = forecast
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
    
    var body: some View {
        HStack {
            Text(dayFormatter.string(from: forecast.date))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 30, alignment: .leading)
            
            Image(systemName: getWeatherSymbol(for: forecast.condition))
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 30)
            
            Text(forecast.condition)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 60)
            
            Spacer()
            
            Text("\(Int(round(forecast.lowTemperature)))°")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Text("-")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 4)
            
            Text("\(Int(round(forecast.highTemperature)))°")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
} 
