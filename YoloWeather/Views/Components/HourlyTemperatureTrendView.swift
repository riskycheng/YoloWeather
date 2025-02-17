import SwiftUI

struct HourlyTemperatureTrendView: View {
    let forecast: [CurrentWeather]
    @Binding var isDragging: Bool
    let animationTrigger: UUID  // 添加触发器参数
    
    // 布局常量
    private let minItemWidth: CGFloat = 46
    private let minSpacing: CGFloat = 6
    private let containerHeight: CGFloat = 128
    
    // 获取城市时区下的当前时间
    private var cityCurrentDate: Date {
        guard let timezone = forecast.first?.timezone else { return Date() }
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let components = calendar.dateComponents(in: timezone, from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    // 过滤并只显示从当前时间开始的24小时预报
    private var filteredForecast: [CurrentWeather] {
        guard let timezone = forecast.first?.timezone else { return [] }
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let currentDate = cityCurrentDate
        
        let filtered = forecast.filter { weather in
            // 确保日期在当前时间之后
            if weather.date >= currentDate {
                // 计算与当前时间的小时差
                var calendarWithTimezone = calendar
                calendarWithTimezone.timeZone = timezone
                let hourDifference = calendarWithTimezone.dateComponents([.hour], from: currentDate, to: weather.date).hour ?? 0
                // 只返回24小时内的预报
                return hourDifference >= 0 && hourDifference < 24
            }
            return false
        }
        
        print("\n=== 更新小时预报 ===")
        if let timezone = forecast.first?.timezone {
            print("城市时区：\(timezone.identifier)")
            print("当前时间：\(formatDateTime(currentDate))")
            print("预报数量：\(filtered.count)")
        }
        
        return filtered
    }
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .blur(radius: 1)
                        .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 0)
                )
                .overlay(
                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: minSpacing) {
                                ForEach(filteredForecast.indices, id: \.self) { index in
                                    let weather = filteredForecast[index]
                                    VStack(spacing: 6) {
                                        Text(formatDateTime(weather.date))
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .frame(height: 36)
                                        
                                        Image(weather.condition)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 26, height: 26)
                                        
                                        Text("\(Int(round(weather.temperature)))°")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: minItemWidth)
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        .onChange(of: animationTrigger) { _, _ in
                            // 当触发器更新时，滚动到开始位置
                            scrollProxy.scrollTo(0, anchor: .leading)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: containerHeight)
                .padding(.horizontal, 16)
        }
        .frame(height: containerHeight)
        .id(animationTrigger) // 添加 id 以强制视图在触发器更新时重建
    }
    
    private func formatDateTime(_ date: Date) -> String {
        guard let timezone = forecast.first?.timezone else { return "" }
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let currentDate = cityCurrentDate
        
        // 如果是当前小时
        if calendar.isDate(date, equalTo: currentDate, toGranularity: .hour) {
            return "现在"
        }
        
        // 创建时间格式器
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timezone
        
        // 检查是否是今天
        if calendar.isDate(date, inSameDayAs: currentDate) {
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        
        // 检查是否是明天
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        if calendar.isDate(date, inSameDayAs: tomorrow) {
            timeFormatter.dateFormat = "明天\nHH:mm"
            return timeFormatter.string(from: date)
        }
        
        // 后天及以后
        timeFormatter.dateFormat = "dd日\nHH:mm"
        return timeFormatter.string(from: date)
    }
}
