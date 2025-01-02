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
    
    private func temperatureBar(low: Double, high: Double, width: CGFloat = 100) -> some View {
        GeometryReader { geometry in
            let minTemp = forecast.map { $0.lowTemperature }.min() ?? low
            let maxTemp = forecast.map { $0.highTemperature }.max() ?? high
            let tempRange = maxTemp - minTemp
            
            let lowX = (low - minTemp) / tempRange * width
            let highX = (high - minTemp) / tempRange * width
            
            ZStack(alignment: .leading) {
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
        }
        .frame(width: width, height: 6)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7天预报")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 8) {
                ForEach(forecast.indices, id: \.self) { index in
                    let day = forecast[index]
                    HStack(spacing: 16) {
                        // 星期
                        Text(dateFormatter.string(from: day.date))
                            .frame(width: 45, alignment: .leading)
                            .font(.system(.body, design: .rounded))
                        
                        // 天气图标
                        Group {
                            if day.condition.contains("Clear") {
                                Image(systemName: "sun.max.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.yellow)
                            } else if day.condition.contains("Cloudy") {
                                Image(systemName: "cloud.sun.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.yellow, .white)
                            } else if day.condition.contains("Drizzle") {
                                Image(systemName: "cloud.drizzle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.white, .blue)
                            }
                        }
                        .font(.title2)
                        .frame(width: 30)
                        
                        // 天气描述
                        Text(day.condition)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .rounded))
                        
                        // 温度范围
                        HStack(spacing: 4) {
                            Text("\(Int(round(day.lowTemperature)))°")
                            temperatureBar(low: day.lowTemperature, high: day.highTemperature)
                            Text("\(Int(round(day.highTemperature)))°")
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
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
