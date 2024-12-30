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
        VStack(spacing: 4) {
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
    
    private func generateKeyTimePoints() -> [WeatherInfo] {
        // 使用本地时区的日历
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        // 获取当前时间（本地时区）
        let currentDate = Date()
        let currentHour = calendar.component(.hour, from: currentDate)
        
        print("当前时间: \(currentDate), 当前小时: \(currentHour)")
        
        // 按时间排序预报数据并转换为本地时区
        let sortedForecast = forecast.map { weather in
            // 将UTC时间转换为本地时区的日期组件
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            let components = utcCalendar.dateComponents([.year, .month, .day, .hour], from: weather.date)
            let localDate = calendar.date(from: components) ?? weather.date
            
            return WeatherInfo(
                date: localDate,
                temperature: weather.temperature,
                condition: weather.condition,
                symbolName: weather.symbolName
            )
        }.sorted { $0.date < $1.date }
        
        print("预报数据: \(sortedForecast.map { "\($0.date): \($0.temperature)°" }.joined(separator: "\n"))")
        
        // 生成时间点序列
        var result: [WeatherInfo] = []
        
        // 第一个点是当前时间
        if let currentPoint = sortedForecast.first(where: { calendar.isDate($0.date, equalTo: currentDate, toGranularity: .hour) }) {
            result.append(currentPoint)
        } else {
            // 如果找不到精确匹配，使用插值
            let nearestBefore = sortedForecast.last { $0.date <= currentDate }
            let nearestAfter = sortedForecast.first { $0.date > currentDate }
            
            if let before = nearestBefore, let after = nearestAfter {
                let totalInterval = after.date.timeIntervalSince(before.date)
                let progressInterval = currentDate.timeIntervalSince(before.date)
                let progress = totalInterval > 0 ? progressInterval / totalInterval : 0
                let interpolatedTemp = before.temperature + (after.temperature - before.temperature) * progress
                
                result.append(WeatherInfo(
                    date: currentDate,
                    temperature: interpolatedTemp,
                    condition: before.condition,
                    symbolName: before.symbolName
                ))
            } else {
                result.append(WeatherInfo(
                    date: currentDate,
                    temperature: nearestBefore?.temperature ?? nearestAfter?.temperature ?? 0,
                    condition: "未知",
                    symbolName: "questionmark"
                ))
            }
        }
        
        // 计算下一个3小时整点
        let nextThreeHour = ((currentHour + 2) / 3 * 3 + 3) % 24
        
        // 生成后续7个时间点，每隔3小时
        for i in 0..<7 {
            let targetHour = (nextThreeHour + i * 3) % 24
            let daysToAdd = (nextThreeHour + i * 3) / 24
            
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: currentDate)
            components.hour = targetHour
            components.day! += daysToAdd
            
            guard let targetDate = calendar.date(from: components) else { continue }
            
            print("目标时间点[\(i+1)]: \(targetDate), 小时: \(targetHour), 天数偏移: \(daysToAdd)")
            
            // 在预报数据中查找最接近的时间点
            let nearestBefore = sortedForecast.last { $0.date <= targetDate }
            let nearestAfter = sortedForecast.first { $0.date > targetDate }
            
            if let before = nearestBefore, let after = nearestAfter {
                // 如果目标时间在两个预报点之间，进行插值计算
                let totalInterval = after.date.timeIntervalSince(before.date)
                let progressInterval = targetDate.timeIntervalSince(before.date)
                let progress = totalInterval > 0 ? progressInterval / totalInterval : 0
                
                let interpolatedTemp = before.temperature + (after.temperature - before.temperature) * progress
                print("插值计算: \(interpolatedTemp)° (前: \(before.temperature)°, 后: \(after.temperature)°)")
                
                result.append(WeatherInfo(
                    date: targetDate,
                    temperature: interpolatedTemp,
                    condition: before.condition,
                    symbolName: before.symbolName
                ))
            } else if let point = nearestBefore ?? nearestAfter {
                result.append(WeatherInfo(
                    date: targetDate,
                    temperature: point.temperature,
                    condition: point.condition,
                    symbolName: point.symbolName
                ))
            }
        }
        
        print("生成的时间点: \(result.map { "\(calendar.component(.hour, from: $0.date))时: \($0.temperature)°" }.joined(separator: ", "))")
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
                            y: size.height * 0.25 * (1 - CGFloat((weather.temperature - minTemp) / tempRange)) + size.height * 0.15
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
                .frame(height: height)
                
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
                .frame(height: 50)
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
        .frame(height: 70)
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
