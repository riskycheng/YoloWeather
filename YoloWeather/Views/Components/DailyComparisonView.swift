import SwiftUI
import WeatherKit

struct DailyComparisonView: View {
    let currentWeather: WeatherService.CurrentWeather?
    let dailyForecast: [WeatherService.DayWeatherInfo]
    let selectedLocation: PresetLocation  // 添加选中的城市
    @Binding var selectedDayOffset: Int // -1 表示前一天，0 表示今天，1 表示明天
    
    private var selectedDay: WeatherService.DayWeatherInfo? {
        guard !dailyForecast.isEmpty else { return nil }
        
        // 如果是昨天，从缓存获取历史数据
        if selectedDayOffset == -1 {
            return WeatherService.shared.getYesterdayWeather(for: selectedLocation.name)
        }
        
        // 今天和未来的数据
        let today = Calendar.current.startOfDay(for: Date())
        return dailyForecast.first { Calendar.current.startOfDay(for: $0.date) == Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: today) }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 日期指示器
            HStack(spacing: 15) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDayOffset = max(-1, selectedDayOffset - 1)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .opacity(selectedDayOffset > -1 ? 1 : 0.5)
                }
                .disabled(selectedDayOffset <= -1)
                
                Text(dayTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedDayOffset = min(6, selectedDayOffset + 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .opacity(selectedDayOffset < 6 ? 1 : 0.5)
                }
                .disabled(selectedDayOffset >= 6)
            }
            
            // 温度和天气信息
            if let day = selectedDay {
                VStack(spacing: 10) {
                    Text("\(Int(round(day.highTemperature)))°")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        WeatherDataBubble(
                            title: "最高温",
                            value: "\(Int(round(day.highTemperature)))°"
                        )
                        
                        WeatherDataBubble(
                            title: "最低温",
                            value: "\(Int(round(day.lowTemperature)))°"
                        )
                        
                        WeatherDataBubble(
                            title: "降水概率",
                            value: "\(Int(round(day.precipitationProbability * 100)))%"
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: selectedDayOffset > 0 ? .trailing : .leading)))
            } else {
                // 显示无数据提示
                VStack(spacing: 10) {
                    Text("无历史数据")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(height: 180)
                .transition(.opacity)
            }
        }
    }
    
    private var dayTitle: String {
        let today = Date()
        guard let date = Calendar.current.date(byAdding: .day, value: selectedDayOffset, to: today) else {
            return "今天"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        switch selectedDayOffset {
        case 0:
            return "今天"
        case 1:
            return "明天"
        case -1:
            return "昨天"
        default:
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
}

private struct WeatherDataBubble: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(15)
    }
}
