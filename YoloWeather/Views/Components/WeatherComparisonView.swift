import SwiftUI

struct WeatherComparisonView: View {
    let weatherService: WeatherService
    let selectedLocation: PresetLocation
    
    private var comparisonData: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?) {
        // 获取昨天的天气数据
        let yesterdayWeather = weatherService.getYesterdayWeather(for: selectedLocation.name)
        
        // 获取今天的天气数据
        var todayWeather: WeatherService.DayWeatherInfo?
        if let currentWeather = weatherService.getCachedWeather(for: selectedLocation.name) {
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
    
    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height * 0.85
                
                ZStack {
                    // 添加水平参考线
                    VStack(spacing: height / 4) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                    .frame(height: height)
                    
                    // 绘制折线
                    Path { path in
                        let points = calculatePoints(width: width, height: height)
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.orange, lineWidth: 2)
                    
                    // 绘制低温折线
                    Path { path in
                        let points = calculateLowPoints(width: width, height: height)
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                    
                    // 绘制节点和温度标签
                    ForEach(0..<3) { index in
                        let temp = temperatures[index]
                        let spacing = width / 2
                        let x = spacing * CGFloat(index)
                        
                        // 高温节点
                        let normalizedHighY = (temp.high - temperatureRange.min) / temperatureRange.range
                        let highY = height * (1 - normalizedHighY)
                        
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: highY)
                        
                        Text("\(Int(temp.high))°")
                            .foregroundColor(.orange)
                            .font(.system(size: 14, weight: .medium))
                            .position(x: x, y: highY - 20)
                        
                        // 低温节点
                        let normalizedLowY = (temp.low - temperatureRange.min) / temperatureRange.range
                        let lowY = height * (1 - normalizedLowY)
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: lowY)
                        
                        Text("\(Int(temp.low))°")
                            .foregroundColor(.blue)
                            .font(.system(size: 14, weight: .medium))
                            .position(x: x, y: lowY + 20)
                        
                        // 日期标签
                        Text(timePoints[index])
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .position(x: x, y: height + 25)
                    }
                }
            }
        }
    }
    
    private func calculatePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let spacing = width / 2
        return temperatures.enumerated().map { index, temp in
            let x = spacing * CGFloat(index)
            let normalizedY = (temp.high - temperatureRange.min) / temperatureRange.range
            let y = height * (1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateLowPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        let spacing = width / 2
        return temperatures.enumerated().map { index, temp in
            let x = spacing * CGFloat(index)
            let normalizedY = (temp.low - temperatureRange.min) / temperatureRange.range
            let y = height * (1 - normalizedY)
            return CGPoint(x: x, y: y)
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
