import SwiftUI
import Foundation

extension WeatherTimeOfDay {
    var gradient: Gradient {
        switch self {
        case .day:
            return Gradient(colors: [
                Color(red: 0.4, green: 0.7, blue: 1.0),  // 浅蓝色
                Color(red: 0.2, green: 0.5, blue: 0.9)   // 深蓝色
            ])
        case .night:
            return Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),  // 深蓝色
                Color(red: 0.05, green: 0.05, blue: 0.2) // 暗蓝色
            ])
        }
    }
}

final class WeatherThemeManager {
    static let shared = WeatherThemeManager()
    
    private init() {}
    
    func determineTimeOfDay(for date: Date, in timezone: TimeZone) -> WeatherTimeOfDay {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        let hour = calendar.component(.hour, from: date)
        
        // 使用一般的日出日落时间：
        // 日出: 6:00
        // 日落: 18:00
        return hour >= 6 && hour < 18 ? .day : .night
    }
    
    // 获取主背景颜色
    func backgroundColor(for timeOfDay: WeatherTimeOfDay) -> Color {
        switch timeOfDay {
        case .day:
            return Color(red: 0.4, green: 0.6, blue: 1.0)  // 浅蓝色天空
        case .night:
            return Color(red: 0.05, green: 0.05, blue: 0.1)  // 深蓝色夜空
        }
    }
    
    // 获取卡片背景颜色
    func cardBackgroundColor(for timeOfDay: WeatherTimeOfDay) -> Color {
        switch timeOfDay {
        case .day:
            return .white.opacity(0.2)
        case .night:
            return .white.opacity(0.1)
        }
    }
    
    // 获取文本颜色
    func textColor(for timeOfDay: WeatherTimeOfDay) -> Color {
        switch timeOfDay {
        case .day:
            return .white
        case .night:
            return .white.opacity(0.95)
        }
    }
    
    // 获取卡片渐变色
    func cardGradient(for timeOfDay: WeatherTimeOfDay) -> [Color] {
        switch timeOfDay {
        case .day:
            return [
                .white.opacity(0.3),
                .white.opacity(0.1)
            ]
        case .night:
            return [
                .white.opacity(0.15),
                .white.opacity(0.05)
            ]
        }
    }
}

// SwiftUI Environment Key for WeatherTimeOfDay
private struct WeatherTimeOfDayKey: EnvironmentKey {
    static let defaultValue: WeatherTimeOfDay = .day
}

extension EnvironmentValues {
    var weatherTimeOfDay: WeatherTimeOfDay {
        get { self[WeatherTimeOfDayKey.self] }
        set { self[WeatherTimeOfDayKey.self] = newValue }
    }
}
