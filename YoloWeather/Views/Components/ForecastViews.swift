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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("7天预报")
                    .font(.headline)
                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                
                Spacer()
                
                Image(systemName: "calendar")
                    .font(.headline)
                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(forecast) { day in
                        HStack(spacing: 16) {
                            // 星期
                            Text(dateFormatter.string(from: day.date))
                                .font(.system(.body, design: .rounded))
                                .frame(width: 40, alignment: .leading)
                            
                            // 天气图标
                            Image(systemName: day.symbolName)
                                .font(.title3)
                                .symbolRenderingMode(.multicolor)
                                .frame(width: 30)
                            
                            // 天气状况
                            Text(day.condition)
                                .font(.system(.body, design: .rounded))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 温度范围
                            HStack(spacing: 4) {
                                Text("\(Int(round(day.lowTemperature)))°")
                                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.7))
                                Text("-")
                                Text("\(Int(round(day.highTemperature)))°")
                            }
                            .font(.system(.body, design: .rounded))
                            .frame(width: 80, alignment: .trailing)
                        }
                        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

extension DayWeatherInfo: Identifiable {
    var id: Date { date }
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
