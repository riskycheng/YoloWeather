import SwiftUI

struct WeatherComparisonView: View {
    let weatherService: WeatherService
    let selectedLocation: PresetLocation
    
    private var comparisonData: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?) {
        // 获取昨天的天气数据
        let yesterdayWeather = weatherService.getYesterdayWeather(for: selectedLocation.name)
        
        // 获取今天的天气数据，使用当前天气的温度
        var todayWeather = weatherService.dailyForecast.first
        if let currentWeather = weatherService.currentWeather {
            todayWeather = WeatherService.DayWeatherInfo(
                date: Date(),
                condition: currentWeather.condition,
                symbolName: currentWeather.symbolName,
                lowTemperature: currentWeather.lowTemperature,
                highTemperature: currentWeather.highTemperature,
                precipitationProbability: 0.0
            )
        }
        
        // 获取明天的天气数据
        let tomorrow = weatherService.dailyForecast.dropFirst().first
        
        return (yesterdayWeather, todayWeather, tomorrow)
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
        VStack(spacing: 20) {
            // 顶部标题区域
            VStack(spacing: 4) {
                Text("天气趋势")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                Text("过去24小时 - 未来24小时")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 16)
            
            // 温度趋势图
            EnhancedTemperatureTrendView(data: comparisonData)
                .frame(height: 180)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 12)
            
            // 天气卡片区域
            HStack(spacing: 8) {
                ForEach(weatherCards, id: \.title) { item in
                    WeatherDayCard(
                        title: item.title,
                        weather: item.weather,
                        gradientColors: item.colors
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer(minLength: 20)
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
            (round(data.yesterday?.highTemperature ?? 0), round(data.yesterday?.lowTemperature ?? 0)),
            (round(data.today?.highTemperature ?? 0), round(data.today?.lowTemperature ?? 0)),
            (round(data.tomorrow?.highTemperature ?? 0), round(data.tomorrow?.lowTemperature ?? 0))
        ]
    }
    
    private var temperatureRange: (min: Double, max: Double, range: Double) {
        let allTemps = temperatures.flatMap { [$0.high, $0.low] }
        let minTemp = round((allTemps.min() ?? 0) - 2)
        let maxTemp = round((allTemps.max() ?? 0) + 2)
        return (minTemp, maxTemp, max(maxTemp - minTemp, 1.0))
    }
    
    private func calculateY(for temperature: Double, height: CGFloat) -> CGFloat {
        let roundedTemp = round(temperature)
        return height * (1 - (roundedTemp - temperatureRange.min) / temperatureRange.range)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height * 0.7
                let step = width / CGFloat(timePoints.count - 1)
                
                ZStack {
                    // 背景网格
                    VStack(spacing: height / 4) {
                        ForEach(0..<5) { _ in
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                    
                    // 温度曲线区域
                    Path { path in
                        // 高温曲线
                        path.move(to: CGPoint(x: 0, y: calculateY(for: temperatures[0].high, height: height)))
                        for i in 1..<temperatures.count {
                            path.addLine(to: CGPoint(x: step * CGFloat(i), y: calculateY(for: temperatures[i].high, height: height)))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    
                    // 低温曲线
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: calculateY(for: temperatures[0].low, height: height)))
                        for i in 1..<temperatures.count {
                            path.addLine(to: CGPoint(x: step * CGFloat(i), y: calculateY(for: temperatures[i].low, height: height)))
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    
                    // 温度点和标签
                    ForEach(Array(temperatures.enumerated()), id: \.offset) { index, temp in
                        let x = step * CGFloat(index)
                        
                        // 高温点
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: calculateY(for: temp.high, height: height))
                            .overlay(
                                Text("\(Int(round(temp.high)))°")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                    .offset(y: -16)
                            )
                        
                        // 低温点
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: calculateY(for: temp.low, height: height))
                            .overlay(
                                Text("\(Int(round(temp.low)))°")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .offset(y: 16)
                            )
                    }
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
                .padding(.top, height + 24)
            }
        }
    }
}

private struct WeatherDayCard: View {
    let title: String
    let weather: WeatherService.DayWeatherInfo?
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            if let weather = weather {
                VStack(spacing: 12) {
                    // 天气图标
                    Image(weather.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 0)
                    
                    // 温度信息
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12))
                            Text("\(Int(round(weather.highTemperature)))°")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12))
                            Text("\(Int(round(weather.lowTemperature)))°")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
            } else {
                Text("暂无数据")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            ZStack {
                // 主背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // 玻璃态效果
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 1)
                
                // 边框
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            }
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
