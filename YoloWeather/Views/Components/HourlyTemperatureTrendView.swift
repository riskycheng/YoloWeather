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
    let timezone: TimeZone
    @Environment(\.weatherTimeOfDay) var timeOfDay
    
    private func formattedHour(from date: Date) -> String {
        if isCurrent {
            return "现在"
        }
        
        var calendar = Calendar.current
        calendar.timeZone = timezone
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
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .frame(height: 20)
            
            Text(formattedHour(from: date))
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .frame(height: 16)
        }
        .frame(width: 44)
        .opacity(isSelected ? 1 : 0.8)
    }
}

struct WeatherBubble: View {
    let symbolName: String
    let temperature: Double
    @Environment(\.weatherTimeOfDay) var timeOfDay
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 24))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            
            Text("\(Int(round(temperature)))°")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(WeatherThemeManager.shared.cardBackgroundColor(for: timeOfDay))
        }
    }
}

struct HourlyTemperatureTrendView: View {
    let forecast: [WeatherInfo]
    @State private var selectedHourIndex: Int?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.weatherTimeOfDay) var timeOfDay
    @GestureState private var isDragging: Bool = false
    
    private let keyTimePoints = 8
    
    // Calculate temperature range and normalized position
    private func calculateTemperaturePosition(temperature: Double, minTemp: Double, maxTemp: Double, height: CGFloat) -> CGFloat {
        let tempRange = max(1, maxTemp - minTemp)
        let normalizedTemp = (temperature - minTemp) / tempRange
        return height * 0.6 * (1 - CGFloat(normalizedTemp)) + height * 0.2
    }
    
    // Create point for temperature curve
    private func createPoint(index: Int, temperature: Double, minTemp: Double, maxTemp: Double, width: CGFloat, height: CGFloat) -> CGPoint {
        let x = CGFloat(index) * (width / CGFloat(keyTimePoints)) + (width / CGFloat(keyTimePoints)) / 2
        let y = calculateTemperaturePosition(temperature: temperature, minTemp: minTemp, maxTemp: maxTemp, height: height)
        return CGPoint(x: x, y: y)
    }
    
    private func generateKeyTimePoints() -> [WeatherInfo] {
        guard let firstItem = forecast.first else { return [] }
        
        var calendar = Calendar.current
        calendar.timeZone = firstItem.timezone
        
        let currentDate = firstItem.date
        var result: [WeatherInfo] = []
        
        // Add current time point
        result.append(firstItem)
        
        // Add future time points at 3-hour intervals
        for i in 1..<8 {
            let targetDate = calendar.date(byAdding: .hour, value: i * 3, to: currentDate) ?? currentDate
            
            // Find the closest weather info to the target date
            if let weather = forecast
                .min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) }) {
                result.append(weather)
            }
        }
        
        return result
    }
    
    // Temperature curve view
    private func TemperatureCurveView(points: [CGPoint], context: GraphicsContext) {
        var path = Path()
        let textColor = WeatherThemeManager.shared.textColor(for: timeOfDay)
        
        // Draw curve through points
        if points.count > 1 {
            path.move(to: points[0])
            for i in 0..<points.count-1 {
                let current = points[i]
                let next = points[i+1]
                let control1 = CGPoint(
                    x: current.x + (next.x - current.x) * 0.5,
                    y: current.y
                )
                let control2 = CGPoint(
                    x: next.x - (next.x - current.x) * 0.5,
                    y: next.y
                )
                path.addCurve(to: next, control1: control1, control2: control2)
            }
        }
        
        // Draw line
        context.stroke(path, with: .color(textColor), lineWidth: 2)
        
        // Draw points
        for point in points {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - 3,
                    y: point.y - 3,
                    width: 6,
                    height: 6
                )),
                with: .color(textColor)
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let hourWidth = width / CGFloat(keyTimePoints)
            let timezone = forecast.first?.timezone ?? TimeZone.current
            let keyPoints = generateKeyTimePoints()
            
            // Calculate temperature range once
            let temperatures = keyPoints.map { $0.temperature }
            let minTemp = temperatures.min() ?? 0
            let maxTemp = temperatures.max() ?? 0
            
            ZStack(alignment: .bottom) {
                // Background
                WeatherThemeManager.shared.cardBackgroundColor(for: timeOfDay)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .overlay {
                        if isDragging {
                            WaveHighlight()
                        }
                    }
                
                VStack(spacing: 0) {
                    // Temperature curve and bubble
                    ZStack(alignment: .top) {
                        // Temperature curve
                        Canvas { context, size in
                            let points = keyPoints.enumerated().map { index, weather in
                                createPoint(
                                    index: index,
                                    temperature: weather.temperature,
                                    minTemp: minTemp,
                                    maxTemp: maxTemp,
                                    width: width,
                                    height: size.height
                                )
                            }
                            TemperatureCurveView(points: points, context: context)
                        }
                        
                        // Weather bubble
                        if let selectedIndex = selectedHourIndex {
                            let weather = keyPoints[selectedIndex]
                            GeometryReader { bubbleGeometry in
                                let yPosition = calculateTemperaturePosition(
                                    temperature: weather.temperature,
                                    minTemp: minTemp,
                                    maxTemp: maxTemp,
                                    height: bubbleGeometry.size.height
                                )
                                
                                WeatherBubble(
                                    symbolName: weather.symbolName,
                                    temperature: weather.temperature
                                )
                                .position(
                                    x: CGFloat(selectedIndex) * hourWidth + hourWidth/2,
                                    y: yPosition
                                )
                            }
                        }
                    }
                    .frame(height: height * 0.7)
                    
                    // Time slots
                    HStack(spacing: 0) {
                        ForEach(Array(keyPoints.enumerated()), id: \.0) { index, point in
                            TimeSlot(
                                date: point.date,
                                isSelected: selectedHourIndex == index,
                                isCurrent: index == 0,
                                temperature: point.temperature,
                                showHour: true,
                                timezone: point.timezone
                            )
                            .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                        }
                    }
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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedHourIndex = index
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedHourIndex = nil
                        }
                    }
            )
        }
        .frame(height: 100)
    }
}

struct HourlyTemperatureTrendView_Previews: PreviewProvider {
    static var previews: some View {
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
                            symbolName: "sun.max.fill",
                            timezone: TimeZone.current
                        )
                    }
                )
                .padding()
            }
        }
        .environment(\.weatherTimeOfDay, .day)
    }
}
