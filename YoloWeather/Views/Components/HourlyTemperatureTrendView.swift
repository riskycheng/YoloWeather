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
    let forecast: [WeatherInfo]
    @State private var selectedHourIndex: Int?
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.weatherTimeOfDay) var timeOfDay
    @GestureState private var isDragging: Bool = false
    
    private let keyTimePoints = 8
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    
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
        context.stroke(path, with: .color(textColor.opacity(0.8)), lineWidth: 2)
        
        // Draw points
        for point in points {
            context.fill(
                Path(ellipseIn: CGRect(
                    x: point.x - 3,
                    y: point.y - 3,
                    width: 6,
                    height: 6
                )),
                with: .color(textColor.opacity(0.8))
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
                        
                        // Temperature labels
                        HStack(spacing: 0) {
                            ForEach(Array(keyPoints.enumerated()), id: \.0) { index, point in
                                Text("\(Int(round(point.temperature)))°")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                                    .frame(width: hourWidth)
                                    .opacity(selectedHourIndex == nil ? 0 : 1)
                            }
                        }
                        .offset(y: 10)
                        
                        // Weather bubble
                        if let selectedIndex = selectedHourIndex {
                            let weather = keyPoints[selectedIndex]
                            Image(systemName: weather.symbolName)
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 32))
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.8)
                                        .background {
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.white.opacity(0.2))
                                        }
                                }
                                .offset(x: CGFloat(selectedIndex) * hourWidth + hourWidth/2 - width/2, y: -60)
                                .transition(.opacity)
                        }
                    }
                    .frame(height: height * 0.7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedHourIndex)
                    
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
            .frame(height: isExpanded ? 150 : 100)
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
        .frame(height: isExpanded ? 150 : 100)
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
