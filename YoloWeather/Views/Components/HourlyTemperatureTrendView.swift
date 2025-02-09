import SwiftUI

struct HourlyTemperatureTrendView: View {
    let forecast: [CurrentWeather]
    @Binding var isDragging: Bool
    
    // 布局常量
    private let minItemWidth: CGFloat = 46
    private let minSpacing: CGFloat = 6
    private let containerHeight: CGFloat = 128
    
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
                                ForEach(forecast.indices, id: \.self) { index in
                                    let weather = forecast[index]
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
                        .onAppear {
                            scrollProxy.scrollTo(0, anchor: .leading)
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: containerHeight)
                .padding(.horizontal, 16)
        }
        .frame(height: containerHeight)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // 如果是当前小时
        if calendar.isDate(date, equalTo: now, toGranularity: .hour) {
            return "现在"
        }
        
        // 创建时间格式器
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = forecast.first?.timezone ?? .current
        
        // 检查是否是今天
        if calendar.isDate(date, inSameDayAs: now) {
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: date)
        }
        
        // 检查是否是明天
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        if calendar.isDate(date, inSameDayAs: tomorrow) {
            timeFormatter.dateFormat = "明天\nHH:mm"
            return timeFormatter.string(from: date)
        }
        
        // 后天及以后
        timeFormatter.dateFormat = "dd日\nHH:mm"
        return timeFormatter.string(from: date)
    }
}
