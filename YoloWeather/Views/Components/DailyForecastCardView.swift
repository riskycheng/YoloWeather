import SwiftUI

struct DailyForecastCardView: View {
    let forecast: [DayWeatherInfo]
    let timeOfDay: WeatherTimeOfDay
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func dailyForecastItem(day: DayWeatherInfo, index: Int) -> some View {
        VStack(spacing: 8) {
            Text(index == 0 ? "TODAY" : formatWeekday(day.date))
                .font(.system(.headline, design: .rounded))
            
            Image(systemName: day.symbolName)
                .font(.title2)
                .symbolRenderingMode(.multicolor)
            
            Text("\(Int(round(day.highTemperature)))°")
                .font(.system(.title3, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            if index == 0 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.blue)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
        .foregroundStyle(index == 0 ? .white : WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(forecast.prefix(3).enumerated()), id: \.element.date) { index, day in
                dailyForecastItem(day: day, index: index)
            }
        }
        .padding(.horizontal)
    }
}
