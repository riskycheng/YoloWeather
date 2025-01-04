import SwiftUI

struct HourlyTemperatureTrendView: View {
    let forecast: [CurrentWeather]
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer(minLength: 8)
                ZStack {
                    // 背景和边框
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // 滚动内容
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(forecast.indices, id: \.self) { index in
                                let weather = forecast[index]
                                VStack(spacing: 8) {
                                    // 时间
                                    Text(formatDateTime(weather.date))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(height: 36)  // 固定时间显示高度
                                    
                                    // 天气图标
                                    Image(weather.condition)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                    
                                    // 温度
                                    Text("\(Int(round(weather.temperature)))°")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 52)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .frame(width: min(geometry.size.width * 0.95, 360))
                .frame(height: 128)
                Spacer(minLength: 8)
            }
        }
        .frame(height: 128)
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
