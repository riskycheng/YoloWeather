import SwiftUI

struct HourlyForecastView: View {
    let forecast: [CurrentWeather]
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24小时预报")
                .font(.headline)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecast.indices, id: \.self) { index in
                        let weather = forecast[index]
                        let hour = Calendar.current.component(.hour, from: weather.date)
                        
                        VStack(spacing: 8) {
                            Text("\(hour)时")
                                .font(.system(.footnote, design: .monospaced))
                            
                            Image(systemName: weather.symbolName)
                                .font(.title2)
                            
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(.body, design: .monospaced))
                        }
                        .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.2))
        }
    }
}

struct DailyForecastView: View {
    let forecast: [DayWeatherInfo]
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7天预报")
                .font(.headline)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
            VStack(spacing: 12) {
                ForEach(forecast.indices, id: \.self) { index in
                    let weather = forecast[index]
                    let isToday = Calendar.current.isDateInToday(weather.date)
                    
                    HStack {
                        // 日期
                        Text(isToday ? "今天" : formatDate(weather.date))
                            .frame(width: 60, alignment: .leading)
                        
                        // 天气图标
                        Image(systemName: weather.symbolName)
                            .frame(width: 30)
                        
                        // 天气描述
                        Text(weather.condition)
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        // 温度范围
                        HStack(spacing: 8) {
                            Text("\(Int(round(weather.lowTemperature)))°")
                                .foregroundColor(.secondary)
                            Text("\(Int(round(weather.highTemperature)))°")
                        }
                        .font(.system(.body, design: .monospaced))
                    }
                    .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                    
                    if index < forecast.count - 1 {
                        Divider()
                            .background(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.2))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct ForecastViews_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            VStack {
                HourlyForecastView(forecast: [
                    .mock(temp: 25, condition: "晴", symbol: "sun.max"),
                    .mock(temp: 27, condition: "晴", symbol: "sun.max"),
                    .mock(temp: 28, condition: "多云", symbol: "cloud"),
                    .mock(temp: 26, condition: "多云", symbol: "cloud"),
                    .mock(temp: 24, condition: "阴", symbol: "cloud.fill")
                ])
                
                DailyForecastView(forecast: [
                    .mock(low: 20, high: 28, condition: "晴", symbol: "sun.max"),
                    .mock(low: 21, high: 29, condition: "多云", symbol: "cloud"),
                    .mock(low: 19, high: 27, condition: "阴", symbol: "cloud.fill")
                ])
            }
            .padding()
        }
    }
}
