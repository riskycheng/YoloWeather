import SwiftUI

struct WaveHighlight: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let path = Path { p in
                p.move(to: CGPoint(x: 0, y: height))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let normalizedX = x / width
                    let y = height * (1 - sin(normalizedX * .pi) * 0.15)
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                
                p.addLine(to: CGPoint(x: width, y: height))
                p.closeSubpath()
            }
            
            context.fill(path, with: .color(.white.opacity(0.2)))
        }
    }
}

struct TimeSlot: View {
    let date: Date
    let isSelected: Bool
    let isCurrent: Bool
    let isSunset: Bool
    let temperature: Double
    
    private func formattedHour(from date: Date) -> String {
        if isCurrent {
            return "现在"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if isSunset {
                Image(systemName: "sunset.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
            }
            Text("\(Int(round(temperature)))°")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            
            Text(formattedHour(from: date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected || isCurrent ? .white : .white.opacity(0.7))
        }
        .frame(width: 44)
        .frame(maxHeight: .infinity)
        .background {
            if isSelected {
                Color.white.opacity(0.2)
            }
        }
    }
}

struct HourlyTemperatureTrendView: View {
    let forecast: [WeatherInfo]
    @State private var selectedHourIndex: Int?
    @GestureState private var isDragging: Bool = false
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    private func isCurrentHour(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .hour)
    }
    
    private func isSunsetHour(_ hour: Int) -> Bool {
        hour == 17 // 假设日落时间是17点，实际应该从WeatherKit获取
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let hourWidth: CGFloat = 44
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .bottom) {
                        // 温度曲线
                        Canvas { context, size in
                            let temps = forecast.map { $0.temperature }
                            guard let minTemp = temps.min(),
                                  let maxTemp = temps.max() else { return }
                            let tempRange = maxTemp - minTemp
                            
                            var path = Path()
                            let points = forecast.enumerated().map { (index, weather) in
                                CGPoint(
                                    x: CGFloat(index) * hourWidth + hourWidth/2,
                                    y: size.height * 0.5 * (1 - CGFloat((weather.temperature - minTemp) / tempRange))
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
                            context.stroke(path, with: .color(.white.opacity(0.8)), lineWidth: 2)
                            
                            // 绘制选中点
                            if let selectedIndex = selectedHourIndex {
                                let point = points[selectedIndex]
                                context.fill(Path(ellipseIn: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)), with: .color(.white))
                            }
                        }
                        .frame(height: height)
                        
                        // 时间轴
                        HStack(spacing: 0) {
                            ForEach(Array(forecast.enumerated()), id: \.0) { index, weather in
                                TimeSlot(
                                    date: weather.date,
                                    isSelected: selectedHourIndex == index,
                                    isCurrent: isCurrentHour(weather.date),
                                    isSunset: isSunsetHour(Calendar.current.component(.hour, from: weather.date)),
                                    temperature: weather.temperature
                                )
                                .id(index)
                            }
                        }
                        .frame(height: 50)
                        .background(.ultraThinMaterial.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                    }
                    .frame(width: CGFloat(forecast.count) * hourWidth)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .updating($isDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                let index = Int((value.location.x) / hourWidth)
                                if index >= 0 && index < forecast.count {
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
                }
                .onAppear {
                    if let currentIndex = forecast.firstIndex(where: { isCurrentHour($0.date) }) {
                        proxy.scrollTo(currentIndex, anchor: .leading)
                    }
                    feedbackGenerator.prepare()
                }
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
                forecast: (0..<24).map { hour in
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
