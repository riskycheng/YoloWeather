import SwiftUI
import Foundation
import CoreLocation
import CoreGraphics
import UIKit

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
        Image(systemName: symbolName)
            .symbolRenderingMode(.multicolor)
            .font(.system(size: 24))
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(timeOfDay == .day ? 0.5 : 0.3)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(timeOfDay == .day ? 0.2 : 0.1))
                    }
            }
            .shadow(
                color: .black.opacity(timeOfDay == .day ? 0.1 : 0.2),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}

struct HourlyTemperatureTrendView: View {
    let forecast: [CurrentWeather]
    @State private var selectedHourIndex: Int?
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.weatherTimeOfDay) var timeOfDay
    @GestureState private var isDragging: Bool = false
    
    private let keyTimePoints = 8
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    private var temperatureRange: ClosedRange<Double> {
        let temperatures = forecast.map { $0.temperature }
        if let min = temperatures.min(), let max = temperatures.max() {
            // 添加一些边距以使图表更美观
            return (min - 2)...(max + 2)
        }
        return 0...30 // 默认范围
    }
    
    // Calculate temperature range and normalized position
    private func calculateTemperaturePosition(temperature: Double, minTemp: Double, maxTemp: Double, height: CGFloat) -> CGFloat {
        let tempRange = max(1, maxTemp - minTemp)
        let normalizedTemp = (temperature - minTemp) / tempRange
        return height * 0.35 * (1 - CGFloat(normalizedTemp)) + height * 0.1
    }
    
    // Create point for temperature curve
    private func createPoint(index: Int, temperature: Double, minTemp: Double, maxTemp: Double, width: CGFloat, height: CGFloat) -> CGPoint {
        let x = CGFloat(index) * (width / CGFloat(keyTimePoints)) + (width / CGFloat(keyTimePoints)) / 2
        let y = calculateTemperaturePosition(temperature: temperature, minTemp: minTemp, maxTemp: maxTemp, height: height)
        return CGPoint(x: x, y: y)
    }
    
    private func generateKeyTimePoints() -> [CurrentWeather] {
        guard let firstItem = forecast.first else { return [] }
        
        var calendar = Calendar.current
        calendar.timeZone = firstItem.timezone
        
        let currentDate = firstItem.date
        var result: [CurrentWeather] = []
        
        // Add current time point
        result.append(firstItem)
        
        // Add future time points at 3-hour intervals
        for i in 1..<8 {
            let targetDate = calendar.date(byAdding: .hour, value: i * 3, to: currentDate) ?? currentDate
            
            // Find the closest weather info to the target date
            if let weather = forecast
                .min(by: { abs($0.date.timeIntervalSince(targetDate)) < abs($1.date.timeIntervalSince(targetDate)) }) {
                let _ = weather.timezone
                result.append(weather)
            }
        }
        
        return result
    }
    
    // Temperature curve view
    private func TemperatureCurveView(points: [CGPoint], context: GraphicsContext, selectedIndex: Int?) {
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
        
        // Draw line with lower opacity
        context.stroke(path, with: .color(textColor.opacity(0.5)), lineWidth: 2)
        
        // Draw points with lower opacity
        for (index, point) in points.enumerated() {
            let isSelected = index == selectedIndex
            let pointSize: CGFloat = isSelected ? 8 : 6
            let opacity: CGFloat = isSelected ? 0.8 : 0.5
            
            // Draw highlight for selected point
            if isSelected {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: point.x - pointSize/2 - 2,
                        y: point.y - pointSize/2 - 2,
                        width: pointSize + 4,
                        height: pointSize + 4
                    )),
                    with: .color(textColor.opacity(0.2))
                )
            }
            
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - pointSize/2,
                    y: point.y - pointSize/2,
                    width: pointSize,
                    height: pointSize
                )),
                with: .color(textColor.opacity(opacity))
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
                RoundedRectangle(cornerRadius: 15)
                    .fill(.ultraThinMaterial)
                    .opacity(timeOfDay == .day ? 0.3 : 0.2)
                    .background {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(timeOfDay == .day ? 0.15 : 0.1))
                    }
                
                VStack(spacing: 0) {
                    // Temperature curve and bubble
                    ZStack {
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
                            TemperatureCurveView(points: points, context: context, selectedIndex: selectedHourIndex)
                        }
                        
                        // Temperature labels and weather bubble
                        HStack(spacing: 0) {
                            ForEach(Array(keyPoints.enumerated()), id: \.0) { index, point in
                                VStack(spacing: 0) {
                                    // Weather bubble
                                    if index == selectedHourIndex {
                                        Image(systemName: point.symbolName)
                                            .symbolRenderingMode(.multicolor)
                                            .font(.system(size: 24))
                                            .padding(10)
                                            .background {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(.ultraThinMaterial)
                                                    .opacity(0.8)
                                                    .background {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color.white.opacity(0.2))
                                                    }
                                            }
                                            .offset(y: -45)
                                            .transition(.opacity)
                                    }
                                    
                                    Spacer()
                                    
                                    // Temperature text - 固定在底部上方
                                    Text("\(Int(round(point.temperature)))°")
                                        .font(.system(
                                            size: index == selectedHourIndex ? 16 : 13,
                                            weight: index == selectedHourIndex ? .bold : .medium
                                        ))
                                        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                                        .opacity(selectedHourIndex == nil ? 0 : 1)
                                        .padding(.bottom, 40) // 增加底部间距到 40pt
                                }
                                .frame(width: hourWidth)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedHourIndex)
                            }
                        }
                    }
                    .frame(height: height * 0.45)
                    
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
            .frame(height: isExpanded ? 110 : 80)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { value, state, _ in
                        if !state {
                            // 只在开始拖动时触发震动
                            impactGenerator.impactOccurred()
                            withAnimation {
                                isExpanded = true
                            }
                        }
                        state = true
                    }
                    .onChanged { value in
                        let index = Int((value.location.x) / hourWidth)
                        if index >= 0 && index < keyTimePoints {
                            if selectedHourIndex != index {
                                // 当选中的时间点改变时触发震动
                                impactGenerator.impactOccurred(intensity: 0.7)
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedHourIndex = index
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedHourIndex = nil
                            isExpanded = false
                        }
                    }
            )
        }
        .frame(height: isExpanded ? 110 : 80)
    }
}

struct HourlyTemperatureTrendView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue
            HourlyTemperatureTrendView(
                forecast: [
                    CurrentWeather(
                        date: Date(),
                        temperature: 25,
                        feelsLike: 27,
                        condition: "晴",
                        symbolName: "sun.max.fill",
                        windSpeed: 3.4,
                        precipitationChance: 0.2,
                        uvIndex: 5,
                        humidity: 0.65,
                        pressure: 1013,
                        visibility: 10,
                        airQualityIndex: 75,
                        timezone: TimeZone.current
                    ),
                    CurrentWeather(
                        date: Date().addingTimeInterval(3600),
                        temperature: 26,
                        feelsLike: 28,
                        condition: "晴",
                        symbolName: "sun.max.fill",
                        windSpeed: 3.4,
                        precipitationChance: 0.2,
                        uvIndex: 5,
                        humidity: 0.65,
                        pressure: 1013,
                        visibility: 10,
                        airQualityIndex: 75,
                        timezone: TimeZone.current
                    )
                ]
            )
        }
    }
}
