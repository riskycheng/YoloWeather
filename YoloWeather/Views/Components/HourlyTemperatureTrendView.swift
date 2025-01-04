import SwiftUI

struct HourlyTemperatureTrendView: View {
    let forecast: [CurrentWeather]
    
    var body: some View {
        ZStack {
            // 背景和边框
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            // 滚动内容
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(forecast.indices, id: \.self) { index in
                        let weather = forecast[index]
                        VStack(spacing: 8) {
                            // 时间
                            Text(formatHour(weather.date))
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            // 天气图标
                            Image(mapWeatherConditionToAsset(weather.condition))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            
                            // 温度
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 60)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(height: 120)
        .padding(.horizontal, 20)
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        if let firstWeather = forecast.first {
            formatter.timeZone = firstWeather.timezone
        }
        
        // 如果是当前小时，显示"现在"
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .hour) {
            return "现在"
        }
        
        return formatter.string(from: date)
    }
    
    private func mapWeatherConditionToAsset(_ condition: String) -> String {
        // WeatherService 现在直接返回图标名称，所以直接使用
        return condition
    }
}
