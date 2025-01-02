import SwiftUI
import WeatherKit

struct DailyForecastListView: View {
    let forecast: [DayWeatherInfo]
    
    private func formatWeekday(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekdaySymbols = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let weekday = calendar.component(.weekday, from: date)
        return weekdaySymbols[weekday - 1]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7天预报")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Image(systemName: "calendar")
            }
            .foregroundStyle(.white)
            
            VStack(spacing: 0) {
                ForEach(forecast.prefix(7)) { day in
                    HStack(spacing: 16) {
                        // 星期
                        Text(formatWeekday(day.date))
                            .frame(width: 45, alignment: .leading)
                            .font(.system(.body, design: .rounded))
                        
                        // 天气图标
                        Image(systemName: day.condition == "Mostly Clear" ? "sun.max.fill" : 
                              day.condition == "Partly Cloudy" ? "cloud.sun.fill" : 
                              day.condition == "Drizzle" ? "cloud.drizzle.fill" : "sun.max.fill")
                            .symbolRenderingMode(.multicolor)
                            .font(.title2)
                            .frame(width: 30)
                        
                        // 天气描述
                        Text(day.condition)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .rounded))
                        
                        // 温度范围
                        Text("\(Int(round(day.lowTemperature)))° - \(Int(round(day.highTemperature)))°")
                            .font(.system(.body, design: .rounded))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.8)
            .ignoresSafeArea()
        
        DailyForecastListView(forecast: [
            DayWeatherInfo(
                date: Date(),
                condition: "晴",
                symbolName: "sun.max.fill",
                lowTemperature: 3,
                highTemperature: 14
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400),
                condition: "晴",
                symbolName: "sun.max.fill",
                lowTemperature: 5,
                highTemperature: 12
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400 * 2),
                condition: "多云",
                symbolName: "cloud.sun.fill",
                lowTemperature: 4,
                highTemperature: 11
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400 * 3),
                condition: "晴",
                symbolName: "sun.max.fill",
                lowTemperature: 6,
                highTemperature: 13
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400 * 4),
                condition: "晴",
                symbolName: "sun.max.fill",
                lowTemperature: 3,
                highTemperature: 11
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400 * 5),
                condition: "晴",
                symbolName: "sun.max.fill",
                lowTemperature: 2,
                highTemperature: 8
            ),
            DayWeatherInfo(
                date: Date().addingTimeInterval(86400 * 6),
                condition: "多云",
                symbolName: "cloud.sun.fill",
                lowTemperature: 2,
                highTemperature: 10
            )
        ])
    }
}
