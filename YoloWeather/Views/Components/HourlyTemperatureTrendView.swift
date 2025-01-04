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
        let timeZone = forecast.first?.timezone ?? TimeZone(identifier: "Asia/Shanghai") ?? .current
        calendar.timeZone = timeZone
        
        let now = Date()
        
        // Check if this is the current hour
        if calendar.isDateInToday(date) && 
           calendar.component(.hour, from: date) == calendar.component(.hour, from: now) {
            return "Now"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"  // 24-hour format
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
    
    private var displayedForecast: [CurrentWeather] {
        guard !forecast.isEmpty else { return [] }
        
        var calendar = Calendar.current
        let timeZone = forecast.first?.timezone ?? TimeZone(identifier: "Asia/Shanghai") ?? .current
        calendar.timeZone = timeZone
        
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        
        // First, find the current hour's forecast
        let currentForecast = forecast.first { weather in
            let weatherHour = calendar.component(.hour, from: weather.date)
            return calendar.isDateInToday(weather.date) && weatherHour == currentHour
        }
        
        // Then get the future forecasts for today
        let todayForecast = forecast
            .filter { weather in
                let weatherHour = calendar.component(.hour, from: weather.date)
                return calendar.isDateInToday(weather.date) && weatherHour > currentHour
            }
            .sorted { $0.date < $1.date }
        
        // Get tomorrow's forecasts
        let tomorrowForecast = forecast
            .filter { weather in
                return calendar.isDateInTomorrow(weather.date)
            }
            .sorted { $0.date < $1.date }
        
        // Combine all forecasts in correct order
        var result: [CurrentWeather] = []
        if let current = currentForecast {
            result.append(current)
        }
        result.append(contentsOf: todayForecast)
        result.append(contentsOf: tomorrowForecast)
        
        return Array(result.prefix(24))
    }
    
    private func mapWeatherConditionToAsset(_ condition: String) -> String {
        // Map WeatherKit conditions to our custom asset names
        switch condition.lowercased() {
        case let c where c.contains("clear"):
            return "sunny"
        case let c where c.contains("cloudy") && c.contains("partly"):
            return "partly_cloudy_daytime"
        case let c where c.contains("cloudy"):
            return "cloudy"
        case let c where c.contains("rain") && c.contains("heavy"):
            return "heavy_rain"
        case let c where c.contains("rain") && c.contains("light"):
            return "light_rain"
        case let c where c.contains("rain"):
            return "moderate_rain"
        case let c where c.contains("snow") && c.contains("heavy"):
            return "heavy_snow"
        case let c where c.contains("snow") && c.contains("light"):
            return "light_snow"
        case let c where c.contains("snow"):
            return "moderate_snow"
        case let c where c.contains("thunderstorm"):
            return "thunderstorm"
        case let c where c.contains("fog") || c.contains("haze"):
            return "fog"
        case let c where c.contains("wind"):
            return "windy"
        default:
            return "NA" // Fallback icon
        }
    }
    
    var body: some View {
        ZStack {
            // Dark background with radius
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
            
            // Scrollable forecast items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(displayedForecast.enumerated()), id: \.1.date) { index, weather in
                        VStack(alignment: .center, spacing: 8) {
                            // Temperature at the top
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(height: 25) // Fixed height for alignment
                            
                            // Weather icon in the middle
                            Image(mapWeatherConditionToAsset(weather.condition))
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32) // Fixed height for alignment
                            
                            // Time at the bottom
                            Text(formatHour(weather.date))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(height: 20) // Fixed height for alignment
                        }
                        .frame(width: 70) // Fixed width for each item
                        .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 8)
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
