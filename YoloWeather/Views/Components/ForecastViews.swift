import SwiftUI

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

struct DailyForecastView: View {
    let forecast: [DayWeatherInfo]
    @Environment(\.weatherTimeOfDay) private var timeOfDay: WeatherTimeOfDay
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    // 计算7天内的全局温度范围
    private var globalTempRange: (min: Double, max: Double) {
        let minTemp = forecast.map { $0.lowTemperature }.min() ?? 0
        let maxTemp = forecast.map { $0.highTemperature }.max() ?? 0
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
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                Text("7天预报")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 预报列表
            VStack(spacing: 12) {
                ForEach(0..<forecast.count, id: \.self) { index in
                    let day = forecast[index]
                    HStack(spacing: 12) {
                        // 星期
                        Text(dateFormatter.string(from: day.date))
                            .font(.system(.body, design: .rounded))
                            .frame(width: 45, alignment: .leading)
                        
                        // 天气图标
                        Image(systemName: day.symbolName)
                            .font(.title3)
                            .frame(width: 24)
                            .symbolRenderingMode(.multicolor)
                        
                        // 温度条和温度
                        HStack(spacing: 8) {
                            Text("\(Int(round(day.lowTemperature)))°")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 30, alignment: .trailing)
                                .lineLimit(1)
                            
                            temperatureBar(low: day.lowTemperature, high: day.highTemperature, width: 80)
                                .frame(height: 6)
                            
                            Text("\(Int(round(day.highTemperature)))°")
                                .font(.system(.subheadline, design: .rounded))
                                .frame(width: 30, alignment: .leading)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    if index != forecast.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal, 20)
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
