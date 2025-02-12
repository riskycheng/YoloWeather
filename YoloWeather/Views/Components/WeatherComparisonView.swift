import SwiftUI

struct WeatherComparisonView: View {
    let weatherService: WeatherService
    
    private var comparisonData: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?) {
        let today = weatherService.dailyForecast.first
        let tomorrow = weatherService.dailyForecast.dropFirst().first
        
        // 获取昨天的日期
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
        
        // 创建昨天的天气数据（这里使用模拟数据，实际应该从历史数据获取）
        let yesterdayWeather = WeatherService.DayWeatherInfo(
            date: yesterday ?? Date(),
            condition: "晴天", // 模拟数据
            symbolName: "sun.max",
            lowTemperature: 15,  // 模拟数据
            highTemperature: 20, // 模拟数据
            precipitationProbability: 0
        )
        
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
        VStack(spacing: 25) {
            // 顶部标题区域
            titleSection
            
            // 温度趋势图
            TemperatureTrendView(data: comparisonData)
                .frame(height: 120)
                .padding(.horizontal)
            
            // 天气卡片区域
            VStack(spacing: 15) {
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
                    .padding(.top, 10)
            }
            
            Spacer()
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("天气趋势")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            Text("过去24小时 - 未来24小时")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 20)
    }
}

// 温度趋势图
private struct TemperatureTrendView: View {
    let data: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?)
    
    private var temperaturePoints: [CGFloat] {
        var points: [CGFloat] = []
        if let yesterday = data.yesterday {
            points.append(contentsOf: [yesterday.lowTemperature, yesterday.highTemperature])
        }
        if let today = data.today {
            points.append(contentsOf: [today.lowTemperature, today.highTemperature])
        }
        if let tomorrow = data.tomorrow {
            points.append(contentsOf: [tomorrow.lowTemperature, tomorrow.highTemperature])
        }
        return points.map { CGFloat($0) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxTemp = temperaturePoints.max() ?? 0
            let minTemp = temperaturePoints.min() ?? 0
            let range = maxTemp - minTemp
            
            Path { path in
                for (index, temp) in temperaturePoints.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(temperaturePoints.count - 1)
                    let y = geometry.size.height * (1 - (temp - minTemp) / range)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.blue, .purple, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            
            // 添加温度点
            ForEach(temperaturePoints.indices, id: \.self) { index in
                let temp = temperaturePoints[index]
                let x = geometry.size.width * CGFloat(index) / CGFloat(temperaturePoints.count - 1)
                let y = geometry.size.height * (1 - (temp - minTemp) / range)
                
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
                
                Text("\(Int(temp))°")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .position(x: x, y: y - 15)
            }
        }
    }
}

private struct WeatherDayCard: View {
    let title: String
    let weather: WeatherService.DayWeatherInfo?
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 15) {
            // 左侧日期和图标
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if let weather = weather {
                    Image(weather.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 80)
            
            if let weather = weather {
                // 中间温度和天气状况
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.condition)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12))
                            Text("\(Int(round(weather.highTemperature)))°")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                            Text("\(Int(round(weather.lowTemperature)))°")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // 右侧降水概率
                if weather.precipitationProbability > 0 {
                    VStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("\(Int(weather.precipitationProbability * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .frame(width: 50)
                }
            } else {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct WeatherChangeSummary: View {
    let today: WeatherService.DayWeatherInfo
    let tomorrow: WeatherService.DayWeatherInfo
    
    private var temperatureChange: Double {
        tomorrow.highTemperature - today.highTemperature
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("天气变化")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                Image(systemName: temperatureChange > 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(temperatureChange > 0 ? .red : .blue)
                
                Text("明天气温将")
                    .foregroundColor(.white.opacity(0.8)) +
                Text("\(temperatureChange > 0 ? "升高" : "降低") \(String(format: "%.1f", abs(temperatureChange)))°")
                    .foregroundColor(temperatureChange > 0 ? .red : .blue)
            }
            .font(.system(size: 14))
            
            if today.condition != tomorrow.condition {
                Text("天气将从\(today.condition)转为\(tomorrow.condition)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }
} 