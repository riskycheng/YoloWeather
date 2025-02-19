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
        
        // 获取当前时间
        let now = Date()
        print("\n=== 调试时间信息 ===")
        print("系统当前时间：\(now)")
        print("系统时区：\(TimeZone.current.identifier)")
        print("目标城市时区：\(timezone.identifier)")
        
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = 0
        components.second = 0
        let currentHour = calendar.date(from: components) ?? now
        
        // 过滤并排序预报
        let filtered = forecast
            .filter { weather in
                print("预报时间：\(weather.date), 是否大于当前时间：\(weather.date >= currentHour)")
                return weather.date >= currentHour
            }
            .sorted { $0.date < $1.date }
            .prefix(24)
        
        print("\n=== 更新小时预报 ===")
        print("城市时区：\(timezone.identifier)")
        print("当前整点时间：\(formatDateTime(currentHour))")
        print("第一个预报时间：\(filtered.first.map { formatDateTime($0.date) } ?? "无")")
        print("预报数量：\(filtered.count)")
        
        // 打印所有预报时间
        print("\n预报时间列表：")
        filtered.forEach { weather in
            print("\(formatDateTime(weather.date)): \(Int(round(weather.temperature)))°")
        }
        
        return Array(filtered)
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
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = timezone
        timeFormatter.dateFormat = "HH:00"
        return timeFormatter.string(from: date)
    }
}
