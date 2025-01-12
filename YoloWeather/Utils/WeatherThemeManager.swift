import SwiftUI

enum WeatherTimeOfDay {
    case day
    case night
    
    var isDaytime: Bool {
        self == .day
    }
}

final class WeatherThemeManager {
    static let shared = WeatherThemeManager()
    
    private init() {}
    
    func determineTimeOfDay(for date: Date, in timezone: TimeZone) -> WeatherTimeOfDay {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        // 获取月份和小时来判断季节和时间
        let month = calendar.component(.month, from: date)
        let hour = calendar.component(.hour, from: date)
        
        // 冰岛的大致日出日落时间（这里使用简化的判断）
        // 冬季: 日出 11:00, 日落 15:30
        // 夏季: 日出 3:00, 日落 23:00
        let isSummer = month >= 4 && month <= 9
        
        if isSummer {
            return hour >= 3 && hour < 23 ? .day : .night
        } else {
            return hour >= 11 && hour < 15 ? .day : .night
        }
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
