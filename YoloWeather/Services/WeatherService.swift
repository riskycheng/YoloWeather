import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared
    
    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var hourlyForecast: [HourlyForecast] = []
    @Published private(set) var dailyForecast: [DayWeatherInfo] = []
    @Published private(set) var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private var location: CLLocation
    
    private init() {
        location = CLLocation(latitude: 31.230416, longitude: 121.473701) // 默认上海
    }
    
    func updateWeather(for location: CLLocation) async {
        self.location = location
        do {
            let weather = try await weatherService.weather(for: location)
            
            await updateCurrentWeather(from: weather)
            await updateHourlyForecast(from: weather)
            await updateDailyForecast(from: weather)
            
            lastUpdateTime = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // 将 WeatherKit 的天气状况转换为中文描述
    private func getWeatherConditionText(_ condition: WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "晴"
        case .cloudy:
            return "多云"
        case .mostlyClear:
            return "晴间多云"
        case .mostlyCloudy, .partlyCloudy:
            return "多云转晴"
        case .drizzle:
            return "小雨"
        case .rain:
            return "中雨"
        case .heavyRain:
            return "大雨"
        case .snow:
            return "雪"
        case .heavySnow:
            return "大雪"
        case .sleet:
            return "雨夹雪"
        case .freezingDrizzle:
            return "冻雨"
        case .strongStorms:
            return "暴风雨"
        case .windy:
            return "大风"
        case .foggy:
            return "雾"
        case .haze:
            return "霾"
        case .hot:
            return "炎热"
        case .blizzard:
            return "暴风雪"
        case .blowingDust:
            return "浮尘"
        case .tropicalStorm:
            return "热带风暴"
        case .hurricane:
            return "台风"
        default:
            return "晴间多云"
        }
    }
    
    private func calculateTimezone(for location: CLLocation) -> TimeZone {
        // 根据经度计算时区
        let longitude = location.coordinate.longitude
        let secondsFromGMT = Int(longitude * 240) // 每经度4分钟，转换为秒
        return TimeZone(secondsFromGMT: secondsFromGMT) ?? TimeZone(identifier: "UTC")!
    }
    
    // 更新当前天气
    private func updateCurrentWeather(from weather: Weather) async {
        let isNightTime = isNight(for: weather.currentWeather.date)
        let symbolName = getWeatherSymbolName(condition: weather.currentWeather.condition, isNight: isNightTime)
        
        currentWeather = CurrentWeather(
            date: weather.currentWeather.date,
            temperature: weather.currentWeather.temperature.value,
            feelsLike: weather.currentWeather.apparentTemperature.value,
            condition: getWeatherConditionText(weather.currentWeather.condition),
            symbolName: symbolName,
            windSpeed: weather.currentWeather.wind.speed.value,
            precipitationChance: weather.hourlyForecast.first?.precipitationChance ?? 0,
            uvIndex: Int(weather.currentWeather.uvIndex.value),
            humidity: weather.currentWeather.humidity,
            airQualityIndex: 0,
            pressure: weather.currentWeather.pressure.value,
            visibility: weather.currentWeather.visibility.value,
            timezone: calculateTimezone(for: location)
        )
    }
    
    // 更新小时预报
    private func updateHourlyForecast(from weather: Weather) async {
        var forecasts: [HourlyForecast] = []
        
        for hour in weather.hourlyForecast.filter({ $0.date.timeIntervalSince(Date()) >= 0 }).prefix(24) {
            let isNightTime = isNight(for: hour.date)
            let symbolName = getWeatherSymbolName(condition: hour.condition, isNight: isNightTime)
            
            let forecast = HourlyForecast(
                id: UUID(),
                temperature: hour.temperature.value,
                condition: hour.condition,
                date: hour.date,
                symbolName: symbolName,
                conditionText: getWeatherConditionText(hour.condition)
            )
            forecasts.append(forecast)
        }
        
        hourlyForecast = forecasts
    }
    
    // 更新每日预报
    private func updateDailyForecast(from weather: Weather) async {
        dailyForecast = weather.dailyForecast.forecast.prefix(7).map { day in
            let isNightTime = isNight(for: day.date)
            let symbolName = getWeatherSymbolName(condition: day.condition, isNight: isNightTime)
            
            return DayWeatherInfo(
                date: day.date,
                condition: getWeatherConditionText(day.condition),
                symbolName: symbolName,
                lowTemperature: day.lowTemperature.value,
                highTemperature: day.highTemperature.value
            )
        }
    }
    
    // 获取天气图标名称
    private func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear:
            return isNight ? "moon_stars" : "sunny"
        case .cloudy:
            return "cloudy"
        case .mostlyClear, .mostlyCloudy, .partlyCloudy:
            return isNight ? "moon_cloudy" : "partly_cloudy_daytime"
        case .drizzle:
            return "light_rain"
        case .rain:
            return "moderate_rain"
        case .heavyRain:
            return "heavy_rain"
        case .snow:
            return "moderate_snow"
        case .heavySnow:
            return "heavy_snow"
        case .sleet:
            return "snow"  // 使用雪的图标代替雨夹雪
        case .freezingDrizzle:
            return "hail"
        case .strongStorms:
            return "thunderstorm"
        case .windy:
            return "windy"
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
            return "rainstorm"
        case .hurricane:
            return "typhoon"
        default:
            return isNight ? "moon_cloudy" : "partly_cloudy_daytime"
        }
    }
    
    // 判断是否为夜间
    private func isNight(for date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }
    
    // 小时预报结构体
    struct HourlyForecast: Identifiable {
        let id: UUID
        let temperature: Double
        let condition: WeatherCondition
        let date: Date
        let symbolName: String
        let conditionText: String
        
        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
    }
    
    struct CurrentWeather {
        let date: Date
        let temperature: Double
        let feelsLike: Double
        let condition: String
        let symbolName: String
        let windSpeed: Double
        let precipitationChance: Double
        let uvIndex: Int
        let humidity: Double
        let airQualityIndex: Int
        let pressure: Double
        let visibility: Double
        let timezone: TimeZone
    }
    
    struct DayWeatherInfo {
        let date: Date
        let condition: String
        let symbolName: String
        let lowTemperature: Double
        let highTemperature: Double
    }
    
    static func mock() -> WeatherService {
        let service = WeatherService()
        let timezone = TimeZone(identifier: "Asia/Shanghai") ?? TimeZone.current
        let now = Date()
        
        // 模拟当前天气
        service.currentWeather = CurrentWeather(
            date: now,
            temperature: 25,
            feelsLike: 27,
            condition: "晴",
            symbolName: "sunny",  // 使用静态图标名称
            windSpeed: 3.4,
            precipitationChance: 0.2,
            uvIndex: 5,
            humidity: 0.65,
            airQualityIndex: 75,
            pressure: 1013,
            visibility: 10,
            timezone: timezone
        )
        
        // 模拟24小时预报
        var hourlyForecast: [HourlyForecast] = []
        for hour in 0..<24 {
            let futureDate = Calendar.current.date(byAdding: .hour, value: hour, to: now) ?? now
            let temp = 25 - Double(hour) * 0.5 // 温度逐渐降低
            let condition = hour % 2 == 0 ? "晴" : "多云"
            
            // 根据小时判断使用的图标
            let calendar = Calendar.current
            let hourComponent = calendar.component(.hour, from: futureDate)
            let isNight = hourComponent < 6 || hourComponent >= 18
            let symbol = isNight ? "moon_stars" : "sunny"
            
            let forecast = HourlyForecast(
                id: UUID(),
                temperature: temp,
                condition: .clear,
                date: futureDate,
                symbolName: symbol,
                conditionText: condition
            )
            hourlyForecast.append(forecast)
        }
        service.hourlyForecast = hourlyForecast
        
        return service
    }
}
