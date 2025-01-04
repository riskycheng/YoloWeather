import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared
    
    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var hourlyForecast: [CurrentWeather] = []
    @Published private(set) var dailyForecast: [DayWeatherInfo] = []
    @Published private(set) var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private init() {}
    
    func updateWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            
            // 获取时区信息
            let timezone = calculateTimezone(for: location)
            
            // 创建当前天气数据
            let current = CurrentWeather(
                date: Date(),  // 使用当前时间
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                condition: translateWeatherCondition(weather.currentWeather.condition),
                symbolName: weather.currentWeather.symbolName,
                windSpeed: weather.currentWeather.wind.speed.value,
                precipitationChance: weather.hourlyForecast.first?.precipitationChance ?? 0,
                uvIndex: Int(weather.currentWeather.uvIndex.value),
                humidity: weather.currentWeather.humidity,
                pressure: weather.currentWeather.pressure.value,
                visibility: weather.currentWeather.visibility.value,
                airQualityIndex: 0,
                timezone: timezone
            )
            
            // 更新当前天气
            currentWeather = current
            
            // 更新小时预报（24小时）
            var hourlyWeatherData = [CurrentWeather]()
            
            // 添加当前天气作为第一项
            hourlyWeatherData.append(current)
            
            // 添加未来23小时的预报
            let futureForecasts = weather.hourlyForecast.forecast
                .filter { $0.date > Date() }  // 只取未来的时间
                .prefix(23)  // 取23小时（加上当前时刻共24小时）
                .map { hour in
                    CurrentWeather(
                        date: hour.date,
                        temperature: hour.temperature.value,
                        feelsLike: hour.apparentTemperature.value,
                        condition: translateWeatherCondition(hour.condition),
                        symbolName: hour.symbolName,
                        windSpeed: hour.wind.speed.value,
                        precipitationChance: hour.precipitationChance,
                        uvIndex: Int(hour.uvIndex.value),
                        humidity: hour.humidity,
                        pressure: hour.pressure.value,
                        visibility: hour.visibility.value,
                        airQualityIndex: 0,
                        timezone: timezone
                    )
                }
            
            hourlyWeatherData.append(contentsOf: futureForecasts)
            hourlyForecast = hourlyWeatherData
            
            // 更新每日预报
            dailyForecast = weather.dailyForecast.forecast.prefix(7).map { day in
                DayWeatherInfo(
                    date: day.date,
                    condition: translateWeatherCondition(day.condition),
                    symbolName: day.symbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value
                )
            }
            
            lastUpdateTime = Date()
            errorMessage = nil
            
        } catch {
            print("Weather update error: \(error.localizedDescription)")
            errorMessage = "获取天气信息失败：\(error.localizedDescription)"
        }
    }
    
    // 将 WeatherKit 的天气状况转换为图标名称
    private func translateWeatherCondition(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sunny"
        case .cloudy:
            return "cloudy"
        case .mostlyClear:
            return "sunny_cloudy"
        case .mostlyCloudy, .partlyCloudy:
            return "partly_cloudy_daytime"
        case .drizzle:
            return "light_rain"
        case .rain:
            return "moderate_rain"
        case .heavyRain:
            return "heavy_rain"
        case .snow:
            return "snow"
        case .heavySnow:
            return "heavy_snow"
        case .sleet:
            return "snow"  // 雨夹雪使用 snow 图标
        case .freezingDrizzle:
            return "hail"
        case .strongStorms:
            return "thunderstorm"
        case .windy:
            return "typhoon"  // 大风使用台风图标
        case .foggy:
            return "fog"
        case .haze:
            return "haze"
        case .hot:
            return "high_temperature"
        case .blizzard:
            return "blizzard"
        case .blowingDust:
            return "blowing_sand"
        case .tropicalStorm:
            return "thunderstorm"
        case .hurricane:
            return "typhoon"
        default:
            return "partly_cloudy_daytime"  // 默认使用多云图标
        }
    }
    
    private func calculateTimezone(for location: CLLocation) -> TimeZone {
        // 根据经度计算时区
        let longitude = location.coordinate.longitude
        let hourOffset = Int(round(longitude / 15.0))
        let secondsFromGMT = hourOffset * 3600
        
        // 特殊时区处理
        if longitude >= -25 && longitude <= -10 && // 冰岛经度范围
           location.coordinate.latitude >= 63 && location.coordinate.latitude <= 67 { // 冰岛纬度范围
            return TimeZone(identifier: "Atlantic/Reykjavik") ?? TimeZone(secondsFromGMT: 0)!
        }
        
        // 尝试使用系统时区数据库
        let timeZones = TimeZone.knownTimeZoneIdentifiers
        for identifier in timeZones {
            if let tz = TimeZone(identifier: identifier) {
                let offset = Double(tz.secondsFromGMT()) / 3600.0
                if abs(offset - Double(hourOffset)) < 0.5 {
                    return tz
                }
            }
        }
        
        // 如果找不到匹配的时区，使用计算的偏移
        return TimeZone(secondsFromGMT: secondsFromGMT) ?? TimeZone(identifier: "UTC")!
    }
    
    static func mock() -> WeatherService {
        let service = WeatherService()
        let timezone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone.current
        let now = Date()
        
        // 当前天气
        service.currentWeather = CurrentWeather(
            date: now,
            temperature: 25,
            feelsLike: 27,
            condition: "晴",
            symbolName: "sun.max",
            windSpeed: 3.4,
            precipitationChance: 0.2,
            uvIndex: 5,
            humidity: 0.65,
            pressure: 1013,
            visibility: 10,
            airQualityIndex: 75,
            timezone: timezone
        )
        
        // 模拟24小时预报
        var hourlyForecast: [CurrentWeather] = []
        for hour in 0..<24 {
            let futureDate = Calendar.current.date(byAdding: .hour, value: hour, to: now) ?? now
            let temp = 25 - Double(hour) * 0.5 // 温度逐渐降低
            let condition = hour % 2 == 0 ? "晴" : "多云"
            let symbol = hour % 2 == 0 ? "sun.max" : "cloud.sun"
            
            let forecast = CurrentWeather(
                date: futureDate,
                temperature: temp,
                feelsLike: temp + 2,
                condition: condition,
                symbolName: symbol,
                windSpeed: 3.4,
                precipitationChance: 0.2,
                uvIndex: 5,
                humidity: 0.65,
                pressure: 1013,
                visibility: 10,
                airQualityIndex: 75,
                timezone: timezone
            )
            hourlyForecast.append(forecast)
        }
        service.hourlyForecast = hourlyForecast
        
        return service
    }
}
