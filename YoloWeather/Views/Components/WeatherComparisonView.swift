import SwiftUI

struct WeatherComparisonView: View {
    let weatherService: WeatherService
    
    private var comparisonData: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?) {
        let today = weatherService.dailyForecast.first
        let tomorrow = weatherService.dailyForecast.dropFirst().first
        
        // 从存储中获取昨天的天气数据
        let yesterdayWeather: WeatherService.DayWeatherInfo?
        if let cityName = weatherService.currentCityName {
            yesterdayWeather = weatherService.getYesterdayWeather(for: cityName)
        } else {
            yesterdayWeather = nil
        }
        
        return (yesterdayWeather, today, tomorrow)
    }
    
    private var weatherCards: [(title: String, weather: WeatherService.DayWeatherInfo?, colors: [Color])] {
        [
            (
                title: "昨天",
                weather: comparisonData.yesterday,
                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)]
            ),
            (
                title: "今天",
                weather: comparisonData.today,
                colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)]
            ),
            (
                title: "明天",
                weather: comparisonData.tomorrow,
                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)]
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 顶部标题区域
            Text("过去24小时 - 未来24小时")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            // 温度趋势图
            EnhancedTemperatureTrendView(data: comparisonData)
                .frame(height: 160)
                .padding(.horizontal)
            
            // 天气卡片区域
            VStack(spacing: 8) {
                ForEach(weatherCards, id: \.title) { item in
                    WeatherDayCard(
                        title: item.title,
                        weather: item.weather,
                        gradientColors: item.colors
                    )
                }
            }
            .padding(.horizontal)
            
            // 底部天气变化总结
            if let today = comparisonData.today,
               let tomorrow = comparisonData.tomorrow {
                WeatherChangeSummary(today: today, tomorrow: tomorrow)
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 0)
        }
    }
}

// 增强版温度趋势图
private struct EnhancedTemperatureTrendView: View {
    let data: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?)
    
    private var timePoints: [String] {
        ["昨天", "今天", "明天"]
    }
    
    private var temperatures: [(high: Double, low: Double)] {
        [
            (data.yesterday?.highTemperature ?? 0, data.yesterday?.lowTemperature ?? 0),
            (data.today?.highTemperature ?? 0, data.today?.lowTemperature ?? 0),
            (data.tomorrow?.highTemperature ?? 0, data.tomorrow?.lowTemperature ?? 0)
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height * 0.7
                let step = width / CGFloat(timePoints.count - 1)
                
                ZStack {
                    // 背景网格
                    VStack(spacing: height / 4) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                    
                    // 温度点和标签
                    ForEach(Array(temperatures.enumerated()), id: \.offset) { index, temp in
                        let x = step * CGFloat(index)
                        
                        if index == 0 && data.yesterday == nil {
                            // 如果是昨天且没有数据，显示提示文字
                            Text("无历史数据")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .position(x: x + 10, y: height * 0.4)
                        } else {
                            // 高温点
                            TemperaturePoint(
                                temperature: temp.high,
                                position: CGPoint(
                                    x: x,
                                    y: height * (1 - (temp.high - minTemp) / tempRange)
                                ),
                                color: .orange
                            )
                            
                            // 低温点
                            TemperaturePoint(
                                temperature: temp.low,
                                position: CGPoint(
                                    x: x,
                                    y: height * (1 - (temp.low - minTemp) / tempRange)
                                ),
                                color: .blue
                            )
                        }
                    }
                    
                    // 高温曲线
                    TemperatureLine(
                        points: temperatures.map { $0.high },
                        geometry: geometry,
                        color: .orange,
                        hasYesterdayData: data.yesterday != nil,
                        minTemp: minTemp,
                        maxTemp: maxTemp
                    )
                    
                    // 低温曲线
                    TemperatureLine(
                        points: temperatures.map { $0.low },
                        geometry: geometry,
                        color: .blue,
                        hasYesterdayData: data.yesterday != nil,
                        minTemp: minTemp,
                        maxTemp: maxTemp
                    )
                }
                .frame(height: height)
                
                // 时间轴
                HStack {
                    ForEach(timePoints, id: \.self) { point in
                        Text(point)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, height + 10)
            }
        }
    }
    
    private var minTemp: Double {
        temperatures.map { min($0.high, $0.low) }.min() ?? 0
    }
    
    private var maxTemp: Double {
        temperatures.map { max($0.high, $0.low) }.max() ?? 0
    }
    
    private var tempRange: Double {
        maxTemp - minTemp
    }
}

private struct TemperatureLine: View {
    let points: [Double]
    let geometry: GeometryProxy
    let color: Color
    let hasYesterdayData: Bool
    let minTemp: Double
    let maxTemp: Double
    
    private var tempRange: Double {
        maxTemp - minTemp
    }
    
    var body: some View {
        let height = geometry.size.height * 0.7
        let width = geometry.size.width
        let step = width / CGFloat(points.count - 1)
        
        Path { path in
            let todayIndex = 1
            let tomorrowIndex = 2
            
            let todayX = step * CGFloat(todayIndex)
            let tomorrowX = step * CGFloat(tomorrowIndex)
            
            let todayY = height * (1 - (points[todayIndex] - minTemp) / tempRange)
            let tomorrowY = height * (1 - (points[tomorrowIndex] - minTemp) / tempRange)
            
            path.move(to: CGPoint(x: todayX, y: todayY))
            path.addLine(to: CGPoint(x: tomorrowX, y: tomorrowY))
        }
        .stroke(
            color,
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

private struct TemperaturePoint: View {
    let temperature: Double
    let position: CGPoint
    let color: Color
    
    var body: some View {
        ZStack {
            // 先绘制圆点，确保它在正确的位置
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 2, x: 0, y: 0)
            
            // 温度文字放在圆点上方
            Text("\(Int(round(temperature)))°")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .offset(y: -20)  // 将文字向上偏移
        }
        .position(x: position.x, y: position.y)  // 使用精确的位置
    }
}

private struct WeatherDayCard: View {
    let title: String
    let weather: WeatherService.DayWeatherInfo?
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧日期
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 45, alignment: .leading)
            
            if let weather = weather {
                // 天气图标
                Image(weather.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                
                Spacer()
                
                // 温度区域
                HStack(spacing: 20) {
                    // 最高温
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("\(Int(round(weather.highTemperature)))°")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    // 最低温
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("\(Int(round(weather.lowTemperature)))°")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(.white)
            } else {
                if title == "昨天" {
                    Text("首日无历史数据")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("暂无数据")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // 主背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.25, green: 0.35, blue: 0.45))
                    .opacity(0.6)
                
                // 顶部渐变光效
                LinearGradient(
                    colors: [
                        .white.opacity(0.2),
                        .white.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 侧边渐变光效
                LinearGradient(
                    colors: [
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .shadow(color: Color.white.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

private struct WeatherChangeSummary: View {
    let today: WeatherService.DayWeatherInfo
    let tomorrow: WeatherService.DayWeatherInfo
    
    private var temperatureChange: Double {
        tomorrow.highTemperature - today.highTemperature
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.yellow)
                Text("天气变化提醒")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 4) {
                Image(systemName: temperatureChange > 0 ? "thermometer.sun.fill" : "thermometer.snowflake")
                    .foregroundColor(temperatureChange > 0 ? .orange : .blue)
                    .font(.system(size: 16))
                
                Text("明天气温将")
                    .foregroundColor(.white) +
                Text("\(temperatureChange > 0 ? "升高" : "降低") \(String(format: "%.1f", abs(temperatureChange)))°")
                    .foregroundColor(temperatureChange > 0 ? .orange : .blue)
                    .fontWeight(.medium)
            }
            .font(.system(size: 16))
            
            if today.condition != tomorrow.condition {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.sun.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    Text("天气将从")
                        .foregroundColor(.white) +
                    Text(today.condition)
                        .foregroundColor(.white)
                        .fontWeight(.medium) +
                    Text("转为")
                        .foregroundColor(.white) +
                    Text(tomorrow.condition)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                .font(.system(size: 16))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
} 

