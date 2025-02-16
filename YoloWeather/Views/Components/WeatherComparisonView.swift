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
        VStack(spacing: 24) {
            // 顶部标题区域
            Text("过去24小时 - 未来24小时")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            // 温度趋势图
            EnhancedTemperatureTrendView(data: comparisonData)
                .frame(height: 160)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // 天气卡片区域 - 修改为3列布局，减小间距增加卡片宽度
            HStack(spacing: 4) {
                ForEach(weatherCards, id: \.title) { item in
                    WeatherDayCard(
                        title: item.title,
                        weather: item.weather,
                        gradientColors: item.colors
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)  // 减小水平内边距
            
            Spacer(minLength: 32)
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
    
    // 计算温度范围
    private var temperatureRange: (min: Double, max: Double, range: Double) {
        let allTemps = temperatures.flatMap { [$0.high, $0.low] }
        let minTemp = round((allTemps.min() ?? 0) - 1)  // 对最小值取整
        let maxTemp = round((allTemps.max() ?? 0) + 1)  // 对最大值取整
        return (minTemp, maxTemp, max(maxTemp - minTemp, 1.0))
    }
    
    // 计算Y坐标的辅助函数
    private func calculateY(for temperature: Double, height: CGFloat) -> CGFloat {
        let roundedTemp = round(temperature)  // 使用取整后的温度值
        let range = temperatureRange
        return height * (1 - (roundedTemp - range.min) / range.range)
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
                    
                    // 高温曲线
                    TemperatureLine(
                        points: temperatures.map { $0.high },
                        geometry: geometry,
                        color: .orange,
                        hasYesterdayData: data.yesterday != nil,
                        temperatureRange: temperatureRange
                    )
                    
                    // 低温曲线
                    TemperatureLine(
                        points: temperatures.map { $0.low },
                        geometry: geometry,
                        color: .blue,
                        hasYesterdayData: data.yesterday != nil,
                        temperatureRange: temperatureRange
                    )
                    
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
                                    y: calculateY(for: temp.high, height: height)
                                ),
                                color: .orange
                            )
                            
                            // 低温点
                            TemperaturePoint(
                                temperature: temp.low,
                                position: CGPoint(
                                    x: x,
                                    y: calculateY(for: temp.low, height: height)
                                ),
                                color: .blue
                            )
                        }
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
                .padding(.top, height + 10)
            }
        }
    }
}

private struct TemperatureLine: View {
    let points: [Double]
    let geometry: GeometryProxy
    let color: Color
    let hasYesterdayData: Bool
    let temperatureRange: (min: Double, max: Double, range: Double)
    
    // 计算Y坐标的辅助函数
    private func calculateY(for temperature: Double, height: CGFloat) -> CGFloat {
        let roundedTemp = round(temperature)  // 使用取整后的温度值
        return height * (1 - (roundedTemp - temperatureRange.min) / temperatureRange.range)
    }
    
    var body: some View {
        let height = geometry.size.height * 0.7
        let width = geometry.size.width
        let step = width / CGFloat(points.count - 1)
        
        Path { path in
            // 如果有昨天的数据，从昨天开始画
            let startIndex = hasYesterdayData ? 0 : 1
            
            // 移动到起始点
            let startX = step * CGFloat(startIndex)
            let startY = calculateY(for: points[startIndex], height: height)
            path.move(to: CGPoint(x: startX, y: startY))
            
            // 连续画线到后续的点
            for index in (startIndex + 1)..<points.count {
                let x = step * CGFloat(index)
                let y = calculateY(for: points[index], height: height)
                path.addLine(to: CGPoint(x: x, y: y))
            }
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
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            if let weather = weather {
                VStack(spacing: 8) {
                    Image(weather.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12))
                        Text("\(Int(round(weather.highTemperature)))°")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12))
                        Text("\(Int(round(weather.lowTemperature)))°")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.blue)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
}
