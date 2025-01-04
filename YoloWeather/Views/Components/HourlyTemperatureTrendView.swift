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
    @Environment(\.weatherTimeOfDay) var timeOfDay
    
    private func formatHour(_ date: Date) -> String {
        var calendar = Calendar.current
        let timeZone = forecast.first?.timezone ?? .current
        calendar.timeZone = timeZone
        
        if calendar.isDate(date, equalTo: Date(), toGranularity: .hour) {
            return "Now"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // Dark background with radius
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
            
            // Forecast items
            HStack(spacing: 0) {
                ForEach(0..<min(5, forecast.count), id: \.self) { index in
                    let weather = forecast[index]
                    VStack(spacing: 8) {
                        // Time
                        Text(formatHour(weather.date))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        // Weather icon
                        Image(systemName: weather.symbolName)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .yellow, .gray)
                            .font(.system(size: 28))
                            .symbolEffect(.bounce, options: .repeat(2))
                        
                        // Temperature
                        Text("\(Int(round(weather.temperature)))°")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(height: 120)
    }
}

struct HourlyTemperatureTrendView_Previews: PreviewProvider {
    static var previews: some View {
        HourlyTemperatureTrendView(forecast: [])
            .frame(height: 100)
            .padding()
            .background(Color.blue)
    }
}
