import SwiftUI

struct WeatherComparisonView: View {
    let weatherService: WeatherService
    let selectedLocation: PresetLocation
    
    private var comparisonData: (yesterday: WeatherService.DayWeatherInfo?, today: WeatherService.DayWeatherInfo?, tomorrow: WeatherService.DayWeatherInfo?) {
        // 获取昨天的天气数据
        let yesterdayWeather = weatherService.getYesterdayWeather(for: selectedLocation.name)
        
        // 获取今天的天气数据
        var todayWeather: WeatherService.DayWeatherInfo?
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
        let tomorrow = weatherService.dailyForecast.first { forecast in
            let calendar = Calendar.current
            let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
            return calendar.isDate(forecast.date, inSameDayAs: tomorrowDate)
        }
        
        return (yesterdayWeather, todayWeather, tomorrow)
    }
    
    private var hasHistoricalData: Bool {
        return comparisonData.yesterday != nil
    }
    
    private var hasAnyData: Bool {
        // 只要今天或明天有数据，就认为有数据可显示
        return comparisonData.today != nil || comparisonData.tomorrow != nil
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
            
            if hasAnyData {
                // 温度趋势图
                EnhancedTemperatureTrendView(data: comparisonData)
                    .frame(height: 180)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.horizontal, 12)
            } else {
                // 无数据提示
                VStack {
                    Text("暂无数据")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 12)
            }
            
            // 天气卡片区域
            HStack(spacing: 8) {
                ForEach(weatherCards, id: \ .title) { item in
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
        .id(selectedLocation.id) // 添加 id 以在城市切换时强制刷新
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
        // 根据是否有昨天的数据，选择要计算的温度数据
        let tempsToConsider: [(high: Double, low: Double)]
        if data.yesterday != nil {
            // 如果有昨天的数据，考虑所有三天
            tempsToConsider = temperatures
        } else {
            // 如果没有昨天的数据，只考虑今天和明天
            tempsToConsider = [temperatures[1], temperatures[2]]
        }
        
        let allTemps = tempsToConsider.flatMap { [$0.high, $0.low] }
            .filter { $0 != 0 } // 过滤掉默认值 0
        let minTemp = round((allTemps.min() ?? 0) - 2)
        let maxTemp = round((allTemps.max() ?? 0) + 2)
        return (minTemp, maxTemp, max(maxTemp - minTemp, 1.0))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height * 0.85
                let horizontalPadding: CGFloat = 20 // 添加水平边距
                let effectiveWidth = width - (horizontalPadding * 2) // 计算实际可用宽度
                
                ZStack {
                    // 添加水平参考线，但只在温度区域显示
                    VStack(spacing: height / 4) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                    .frame(height: height * 0.8) // 减小高度，使分隔线不延伸到底部日期轴
                    .padding(.horizontal, horizontalPadding)
                    .offset(y: -height * 0.1) // 向上偏移以避免触及底部日期轴
                    
                    // 绘制高温折线
                    if data.today != nil && data.tomorrow != nil {
                        // 高温折线
                        if data.yesterday != nil {
                            // 如果有昨天的数据，绘制完整的三日折线
                            Path { path in
                                let points = calculatePoints(width: effectiveWidth, height: height, horizontalPadding: horizontalPadding)
                                path.move(to: points[0])
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                            .stroke(Color.orange, lineWidth: 2)
                        } else {
                            // 如果没有昨天的数据，只绘制今天到明天的折线
                            Path { path in
                                let points = calculatePoints(width: effectiveWidth, height: height, horizontalPadding: horizontalPadding)
                                path.move(to: points[1]) // 从今天开始
                                path.addLine(to: points[2]) // 到明天
                            }
                            .stroke(Color.orange, lineWidth: 2)
                        }
                        
                        // 低温折线
                        if data.yesterday != nil {
                            // 如果有昨天的数据，绘制完整的三日折线
                            Path { path in
                                let points = calculateLowPoints(width: effectiveWidth, height: height, horizontalPadding: horizontalPadding)
                                path.move(to: points[0])
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                            .stroke(Color.blue, lineWidth: 2)
                        } else {
                            // 如果没有昨天的数据，只绘制今天到明天的折线
                            Path { path in
                                let points = calculateLowPoints(width: effectiveWidth, height: height, horizontalPadding: horizontalPadding)
                                path.move(to: points[1]) // 从今天开始
                                path.addLine(to: points[2]) // 到明天
                            }
                            .stroke(Color.blue, lineWidth: 2)
                        }
                    }
                    
                    // 绘制节点和温度标签
                    ForEach(0..<3) { index in
                        let temp = temperatures[index]
                        let spacing = effectiveWidth / 2
                        let x = spacing * CGFloat(index) + horizontalPadding
                        
                        // 只有在有数据时才显示节点和温度标签
                        if (index == 0 && data.yesterday != nil) || index > 0 {
                            if temp.high != 0 || temp.low != 0 {
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
                            } else {
                                // 如果没有数据，显示"暂无数据"
                                Text("暂无数据")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .position(x: x, y: height / 2)
                            }
                        } else if index == 0 {
                            // 昨天没有数据时显示"暂无数据"
                            Text("暂无数据")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .position(x: x, y: height / 2)
                        }
                        
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
    
    private func calculatePoints(width: CGFloat, height: CGFloat, horizontalPadding: CGFloat) -> [CGPoint] {
        let spacing = width / 2
        return temperatures.enumerated().map { index, temp in
            let x = spacing * CGFloat(index) + horizontalPadding
            let normalizedY = (temp.high - temperatureRange.min) / temperatureRange.range
            let y = height * (1 - normalizedY)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateLowPoints(width: CGFloat, height: CGFloat, horizontalPadding: CGFloat) -> [CGPoint] {
        let spacing = width / 2
        return temperatures.enumerated().map { index, temp in
            let x = spacing * CGFloat(index) + horizontalPadding
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
    
    // 统一图标大小
    private let iconSize: CGFloat = 32
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.top, 16)
            
            // 图标容器，确保所有图标大小一致
            if let weather = weather {
                Image(weather.symbolName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 0)
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .opacity(0.5)
                    .foregroundColor(.white)
            }
            
            // 温度信息
            HStack(spacing: 8) {
                if let weather = weather {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12))
                        Text("\(Int(round(weather.highTemperature)))°")
                            .font(.system(size: 18, weight: .medium))
                            .frame(minWidth: 25, alignment: .leading)
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12))
                        Text("\(Int(round(weather.lowTemperature)))°")
                            .font(.system(size: 18, weight: .medium))
                            .frame(minWidth: 25, alignment: .leading)
                    }
                    .foregroundColor(.blue)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 12))
                        Text("--")
                            .font(.system(size: 18, weight: .medium))
                            .frame(minWidth: 25, alignment: .leading)
                    }
                    .foregroundColor(.orange.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 12))
                        Text("--")
                            .font(.system(size: 18, weight: .medium))
                            .frame(minWidth: 25, alignment: .leading)
                    }
                    .foregroundColor(.blue.opacity(0.5))
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
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
