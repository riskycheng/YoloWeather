import SwiftUI
import WeatherKit

struct HourlyForecastView: View {
    let forecast: [CurrentWeather]
    @Environment(\.weatherTimeOfDay) private var timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24小时预报")
                .font(.headline)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(0..<forecast.count, id: \.self) { index in
                        let weather = forecast[index]
                        let hour = Calendar.current.component(.hour, from: weather.date)
                        
                        VStack(spacing: 8) {
                            Text("\(hour)时")
                                .font(.system(.footnote, design: .monospaced))
                            
                            Image(weather.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
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

struct DailyForecast: Identifiable {
    let id = UUID()
    let weekday: String
    let date: Date
    let temperatureMin: Double
    let temperatureMax: Double
    let symbolName: String
}

struct DailyForecastView: View {
    let forecast: [DailyForecast]
    
    // 计算7天内的全局温度范围
    private var globalTempRange: (min: Double, max: Double) {
        let minTemp = forecast.map { $0.temperatureMin }.min() ?? 0
        let maxTemp = forecast.map { $0.temperatureMax }.max() ?? 0
        return (minTemp, maxTemp)
    }
    
    private func temperatureBar(low: Double, high: Double, width: CGFloat = 100) -> some View {
        let (minTemp, maxTemp) = globalTempRange
        let tempRange = maxTemp - minTemp
        
        let lowX = (low - minTemp) / tempRange * width
        let highX = (high - minTemp) / tempRange * width
        
        return ZStack(alignment: .leading) {
            // 背景条
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: width, height: 4)
            
            // 温度范围条
            Capsule()
                .fill(.teal)
                .frame(width: highX - lowX, height: 4)
                .offset(x: lowX)
            
            // 当前温度点
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .offset(x: highX - 3)
        }
        .frame(width: width, height: 6)
    }
    
    var body: some View {
        VStack(spacing: 8) {  // 减小整体间距
            ForEach(forecast.prefix(7)) { day in
                HStack(spacing: 12) {
                    // 星期
                    Text(day.weekday)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 45, alignment: .leading)
                    
                    // 天气图标
                    Image(day.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    // 温度条和温度
                    HStack(spacing: 8) {
                        Text("\(Int(round(day.temperatureMin)))°")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 30, alignment: .trailing)
                            .lineLimit(1)
                        
                        temperatureBar(low: day.temperatureMin, high: day.temperatureMax, width: 80)
                            .frame(height: 6)
                        
                        Text("\(Int(round(day.temperatureMax)))°")
                            .font(.system(.subheadline, design: .rounded))
                            .frame(width: 30, alignment: .leading)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                
                if forecast.firstIndex(where: { $0.id == day.id }) != forecast.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 12)  // 减小顶部和底部边距
    }
}

// 预览数据
extension DailyForecast {
    static let previewData = [
        DailyForecast(weekday: "Sun", date: Date(), temperatureMin: 5, temperatureMax: 9, symbolName: "sunny"),
        DailyForecast(weekday: "Mon", date: Date().addingTimeInterval(86400), temperatureMin: 0, temperatureMax: 6, symbolName: "cloudy"),
        DailyForecast(weekday: "Tue", date: Date().addingTimeInterval(172800), temperatureMin: -2, temperatureMax: 7, symbolName: "partly_cloudy_daytime"),
        DailyForecast(weekday: "Wed", date: Date().addingTimeInterval(259200), temperatureMin: -1, temperatureMax: 10, symbolName: "moderate_rain"),
        DailyForecast(weekday: "Thu", date: Date().addingTimeInterval(345600), temperatureMin: 2, temperatureMax: 14, symbolName: "sunny"),
        DailyForecast(weekday: "Fri", date: Date().addingTimeInterval(432000), temperatureMin: 7, temperatureMax: 12, symbolName: "cloudy"),
        DailyForecast(weekday: "Sat", date: Date().addingTimeInterval(518400), temperatureMin: 7, temperatureMax: 11, symbolName: "partly_cloudy_daytime")
    ]
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        DailyForecastView(forecast: DailyForecast.previewData)
    }
}
