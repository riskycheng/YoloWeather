import SwiftUI

struct WaveHighlight: View {
    @State private var phase: CGFloat = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: height))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let normalizedX = x / width
                    let y = height * (1 - sin((normalizedX * .pi + phase) * 2) * 0.15)
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                
                p.addLine(to: CGPoint(x: width, y: height))
                p.closeSubpath()
            }
            
            context.fill(path, with: .linearGradient(
                Gradient(colors: [
                    .white.opacity(0.3),
                    .white.opacity(0.1)
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: height)
            ))
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.1)) {
                phase += 0.1
            }
        }
    }
}

struct TimeSlot: View {
    let date: Date
    let isSelected: Bool
    let isCurrent: Bool
    let temperature: Double
    let showHour: Bool
    
    private func formattedHour(from date: Date) -> String {
        if isCurrent {
            return "现在"
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let hour = calendar.component(.hour, from: date)
        let isNextDay = !calendar.isDate(date, inSameDayAs: Date())
        
        if isNextDay {
            return "\(hour)时"
        }
        return "\(hour)时"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(round(temperature)))°")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(height: 20)
            
            Text(formattedHour(from: date))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
                .frame(height: 16)
        }
        .frame(width: 44)
    }
}

struct HourlyTemperatureTrendView: View {
    let forecast: [WeatherInfo]
    @State private var selectedHourIndex: Int?
    @GestureState private var isDragging: Bool = false
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let keyTimePoints = 8 // 固定显示8个时间点
    
    private func printKeyTimeTemperatures(forecast: [WeatherInfo]) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let keyHours = [0, 1, 4, 7, 10, 13, 16, 19, 22]
        
        print("\n今天和明天的关键时间点温度：")
        print("今天:")
        for hour in keyHours {
            if let temp = forecast.first(where: { calendar.component(.hour, from: $0.date) == hour && calendar.isDate($0.date, inSameDayAs: today) })?.temperature {
                print("\(hour)时: \(temp)°")
            }
        }
        
        print("\n明天:")
        for hour in keyHours {
            if let temp = forecast.first(where: { calendar.component(.hour, from: $0.date) == hour && calendar.isDate($0.date, inSameDayAs: tomorrow) })?.temperature {
                print("\(hour)时: \(temp)°")
            }
        }
        print("------------------------")
    }
    
    private func printNext24HoursTemperature(forecast: [WeatherInfo]) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "MM月dd日"
        
        print("\n=== 未来24小时气温预报 ===")
        print("当前时间: \(dateFormatter.string(from: currentDate)) \(calendar.component(.hour, from: currentDate))时")
        
        // 按时间排序并过滤出未来24小时的数据
        let next24Hours = forecast
            .map { weather in
                // 将UTC时间转换为本地时区
                var utcCalendar = Calendar(identifier: .gregorian)
                utcCalendar.timeZone = TimeZone(identifier: "UTC")!
                let components = utcCalendar.dateComponents([.year, .month, .day, .hour], from: weather.date)
                var localCalendar = Calendar(identifier: .gregorian)
                localCalendar.timeZone = TimeZone.current
                let localDate = localCalendar.date(from: components) ?? weather.date
                
                return WeatherInfo(
                    date: localDate,
                    temperature: weather.temperature,
                    condition: weather.condition,
                    symbolName: weather.symbolName
                )
            }
            .filter { $0.date >= currentDate && $0.date <= calendar.date(byAdding: .hour, value: 24, to: currentDate)! }
            .sorted { $0.date < $1.date }
        
        var lastPrintedDate = ""
        for weather in next24Hours {
            let date = dateFormatter.string(from: weather.date)
            let hour = calendar.component(.hour, from: weather.date)
            
            // 如果日期变化了，打印一个分隔行
            if date != lastPrintedDate {
                if !lastPrintedDate.isEmpty {
                    print("------------------------")
                }
                print("\n\(date):")
                lastPrintedDate = date
            }
            
            print("\(hour)时: \(weather.temperature)°")
        }
        print("========================\n")
    }
    
    private func generateKeyTimePoints() -> [WeatherInfo] {
        // 使用本地时区的日历
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // 获取当前时间（本地时区）
        let currentDate = Date()
        let currentHour = calendar.component(.hour, from: currentDate)
        
        print("\n=== 温度预报详细信息 ===")
        print("当前时间: \(currentDate), 当前小时: \(currentHour)")
        
        // 按时间排序预报数据并转换为本地时区
        let sortedForecast = forecast.map { weather in
            // 将UTC时间转换为本地时区的日期组件
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            let utcComponents = utcCalendar.dateComponents([.year, .month, .day, .hour], from: weather.date)
            
            // 转换为本地时间
            var localComponents = DateComponents()
            localComponents.year = calendar.component(.year, from: currentDate)
            localComponents.month = calendar.component(.month, from: currentDate)
            localComponents.day = calendar.component(.day, from: currentDate)
            localComponents.hour = utcComponents.hour
            
            let localDate = calendar.date(from: localComponents) ?? weather.date
            
            // 如果本地时间小于当前时间，说明是明天的数据
            let adjustedDate = localDate < currentDate ?
                calendar.date(byAdding: .day, value: 1, to: localDate) ?? localDate :
                localDate
            
            return WeatherInfo(
                date: adjustedDate,
                temperature: weather.temperature,
                condition: weather.condition,
                symbolName: weather.symbolName
            )
        }.sorted { $0.date < $1.date }
        
        // 打印原始数据
        print("\n原始预报数据:")
        for weather in sortedForecast {
            let hour = calendar.component(.hour, from: weather.date)
            let isNextDay = !calendar.isDate(weather.date, inSameDayAs: currentDate)
            print("\(isNextDay ? "明天" : "今天") \(hour)时: \(weather.temperature)°")
        }
        
        // 生成时间点序列
        var result: [WeatherInfo] = []
        
        // 获取当前时间的温度
        let currentTemp: Double
        if let exactMatch = sortedForecast.first(where: { 
            let weatherHour = calendar.component(.hour, from: $0.date)
            return weatherHour == currentHour && calendar.isDateInToday($0.date)
        }) {
            currentTemp = exactMatch.temperature
        } else {
            // 如果找不到精确匹配，使用插值
            let nearestBefore = sortedForecast.last { $0.date <= currentDate }
            let nearestAfter = sortedForecast.first { $0.date > currentDate }
            
            if let before = nearestBefore, let after = nearestAfter {
                let totalInterval = after.date.timeIntervalSince(before.date)
                let progressInterval = currentDate.timeIntervalSince(before.date)
                let progress = totalInterval > 0 ? progressInterval / totalInterval : 0
                currentTemp = before.temperature + (after.temperature - before.temperature) * progress
            } else {
                currentTemp = nearestBefore?.temperature ?? nearestAfter?.temperature ?? 7.0 // 设置一个合理的默认值
            }
        }
        
        // 添加当前时间点
        result.append(WeatherInfo(
            date: currentDate,
            temperature: currentTemp,
            condition: "未知",
            symbolName: "moon.stars.fill"
        ))
        
        // 生成后续7个时间点，每隔3小时
        for i in 1..<8 {
            let targetDate = calendar.date(byAdding: .hour, value: i * 3, to: currentDate) ?? currentDate
            let targetHour = calendar.component(.hour, from: targetDate)
            let isNextDay = !calendar.isDate(targetDate, inSameDayAs: currentDate)
            
            // 在预报数据中查找对应时间点的温度
            let temp: Double
            if let exactMatch = sortedForecast.first(where: { weather in
                let weatherHour = calendar.component(.hour, from: weather.date)
                let weatherIsNextDay = !calendar.isDate(weather.date, inSameDayAs: currentDate)
                return weatherHour == targetHour && weatherIsNextDay == isNextDay
            }) {
                // 找到精确匹配的时间点
                temp = exactMatch.temperature
            } else {
                // 如果找不到精确匹配，使用插值
                let nearestBefore = sortedForecast.last { $0.date <= targetDate }
                let nearestAfter = sortedForecast.first { $0.date > targetDate }
                
                if let before = nearestBefore, let after = nearestAfter {
                    let totalInterval = after.date.timeIntervalSince(before.date)
                    let progressInterval = targetDate.timeIntervalSince(before.date)
                    let progress = totalInterval > 0 ? progressInterval / totalInterval : 0
                    temp = before.temperature + (after.temperature - before.temperature) * progress
                } else {
                    // 使用最近的温度
                    temp = nearestBefore?.temperature ?? nearestAfter?.temperature ?? currentTemp
                }
            }
            
            result.append(WeatherInfo(
                date: targetDate,
                temperature: temp,
                condition: "未知",
                symbolName: "moon.stars.fill"
            ))
        }
        
        // 打印最终结果
        print("\n最终生成的时间点:")
        for point in result {
            let hour = calendar.component(.hour, from: point.date)
            let isNextDay = !calendar.isDate(point.date, inSameDayAs: currentDate)
            print("\(isNextDay ? "明天" : "今天") \(hour)时: \(point.temperature)°")
        }
        
        return result
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let hourWidth = width / CGFloat(keyTimePoints)
            let keyPoints = generateKeyTimePoints()
            
            ZStack(alignment: .bottom) {
                // 背景
                Color.black.opacity(0.2)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                
                VStack(spacing: 0) {
                    // 温度曲线
                    Canvas { context, size in
                        let temps = keyPoints.map { $0.temperature }
                        guard let minTemp = temps.min(),
                              let maxTemp = temps.max() else { return }
                        let tempRange = max(1, maxTemp - minTemp)
                        
                        var path = Path()
                        let points = keyPoints.enumerated().map { (index, weather) in
                            CGPoint(
                                x: CGFloat(index) * hourWidth + hourWidth/2,
                                y: size.height * 0.6 * (1 - CGFloat((weather.temperature - minTemp) / tempRange)) + size.height * 0.2
                            )
                        }
                        
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let prev = points[i-1]
                            let curr = points[i]
                            let control1 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: prev.y)
                            let control2 = CGPoint(x: prev.x + (curr.x - prev.x) * 0.5, y: curr.y)
                            path.addCurve(to: curr, control1: control1, control2: control2)
                        }
                        
                        // 绘制温度曲线
                        context.stroke(path, with: .color(.white), lineWidth: 1.5)
                        
                        // 绘制选中点
                        if let selectedIndex = selectedHourIndex {
                            let point = points[selectedIndex]
                            context.fill(
                                Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
                                with: .color(.white)
                            )
                        }
                    }
                    .frame(height: height * 0.5)
                    
                    // 时间轴
                    HStack(spacing: 0) {
                        ForEach(Array(keyPoints.enumerated()), id: \.0) { index, weather in
                            TimeSlot(
                                date: weather.date,
                                isSelected: selectedHourIndex == index,
                                isCurrent: index == 0,
                                temperature: weather.temperature,
                                showHour: true
                            )
                        }
                    }
                    .frame(height: height * 0.5)
                }
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { value, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        let index = Int((value.location.x) / hourWidth)
                        if index >= 0 && index < keyTimePoints {
                            if selectedHourIndex != index {
                                feedbackGenerator.impactOccurred(intensity: 0.8)
                            }
                            selectedHourIndex = index
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedHourIndex = nil
                        }
                    }
            )
            .onAppear {
                // 打印温度数据
                var calendar = Calendar.current
                calendar.timeZone = TimeZone.current
                print("温度数据: \(keyPoints.map { "\(calendar.component(.hour, from: $0.date))时: \($0.temperature)°" }.joined(separator: ", "))")
            }
        }
        .frame(height: 100)
    }
}

#Preview {
    ZStack {
        Color.black
        VStack {
            Spacer()
            HourlyTemperatureTrendView(
                forecast: (0..<48).map { hour in
                    let baseTemp = 25.0
                    let variation = sin(Double(hour) * .pi / 12.0) * 5.0
                    return WeatherInfo(
                        date: Date().addingTimeInterval(Double(hour) * 3600),
                        temperature: baseTemp + variation,
                        condition: "晴",
                        symbolName: "sun.max.fill"
                    )
                }
            )
            .padding()
        }
    }
}
