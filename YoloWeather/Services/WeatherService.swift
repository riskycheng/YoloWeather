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
    @Published private(set) var isLoading: Bool = false
    
    private var location: CLLocation
    
    private init() {
        location = CLLocation(latitude: 31.230416, longitude: 121.473701) // 默认上海
    }
    
    func updateWeather(for location: CLLocation) async {
        self.location = location
        isLoading = true
        defer { isLoading = false }
        
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
            timezone: calculateTimezone(for: location),
            weatherCondition: weather.currentWeather.condition
        )
    }
    
    // 更新小时预报
    private func updateHourlyForecast(from weather: Weather) async {
        var forecasts: [HourlyForecast] = []
        
        for hour in weather.hourlyForecast.filter({ $0.date.timeIntervalSince(Date()) >= 0 }).prefix(24) {
            let forecast = HourlyForecast(
                id: UUID(),
                temperature: hour.temperature.value,
                condition: hour.condition,
                date: hour.date,
                symbolName: getWeatherSymbolName(condition: hour.condition, isNight: isNight(for: hour.date)),
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
    internal func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return isNight ? "full_moon" : "sunny"
        case .cloudy:
            return "cloudy"
        case .mostlyCloudy, .partlyCloudy:
            return isNight ? "partly_cloudy_night" : "partly_cloudy_daytime"
        case .drizzle:
            return "light_rain"
        case .rain:
            return "moderate_rain"
        case .heavyRain:
            return "heavy_rain"
        case .snow:
            return "light_snow"
        case .heavySnow, .blizzard:
            return "heavy_snow"
        case .sleet, .freezingDrizzle:
            return "wet"
        case .windy:
            return "windy"
        case .foggy:
            return "fog"
        case .haze:
            return "haze"
        case .blowingDust:
            return "blowing_sand"
        case .tropicalStorm:
            return "thunderstorm"
        case .hurricane:
            return "typhoon"
        default:
            return isNight ? "full_moon" : "sunny"
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
    
    struct CurrentWeather: Equatable {
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
        let weatherCondition: WeatherCondition
        
        static func mock(date: Date = Date(), temp: Double, condition: String, symbol: String) -> CurrentWeather {
            CurrentWeather(
                date: date,
                temperature: temp,
                feelsLike: temp + 2,
                condition: condition,
                symbolName: symbol,
                windSpeed: 3.4,
                precipitationChance: 0.2,
                uvIndex: 5,
                humidity: 0.65,
                airQualityIndex: 75,
                pressure: 1013,
                visibility: 10,
                timezone: TimeZone.current,
                weatherCondition: .clear
            )
        }
    }
    
    struct DayWeatherInfo {
        let date: Date
        let condition: String
        let symbolName: String
        let lowTemperature: Double
        let highTemperature: Double
        
        static func mock(low: Double, high: Double, condition: String, symbol: String, date: Date) -> DayWeatherInfo {
            DayWeatherInfo(
                date: date,
                condition: condition,
                symbolName: symbol,
                lowTemperature: low,
                highTemperature: high
            )
        }
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
            symbolName: "sunny",
            windSpeed: 3.4,
            precipitationChance: 0.2,
            uvIndex: 5,
            humidity: 0.65,
            airQualityIndex: 75,
            pressure: 1013,
            visibility: 10,
            timezone: timezone,
            weatherCondition: .clear
        )
        
        // 模拟24小时预报
        var hourlyForecast: [HourlyForecast] = []
        let condition = "晴"
        
        for i in 0..<24 {
            let futureDate = Calendar.current.date(byAdding: .hour, value: i, to: now)!
            let calendar = Calendar.current
            let hourComponent = calendar.component(.hour, from: futureDate)
            let isNight = hourComponent < 6 || hourComponent >= 18
            let symbol = isNight ? "full_moon" : "sunny"
            
            let forecast = HourlyForecast(
                id: UUID(),
                temperature: 25 + Double.random(in: -5...5),
                condition: .clear,
                date: futureDate,
                symbolName: symbol,
                conditionText: condition
            )
            hourlyForecast.append(forecast)
        }
        
        service.hourlyForecast = hourlyForecast
        
        // 模拟每日预报
        service.dailyForecast = [
            DayWeatherInfo.mock(low: 20, high: 30, condition: "晴", symbol: "sunny", date: now),
            DayWeatherInfo.mock(low: 19, high: 29, condition: "多云", symbol: "cloudy", date: Calendar.current.date(byAdding: .day, value: 1, to: now)!),
            DayWeatherInfo.mock(low: 18, high: 28, condition: "小雨", symbol: "rain", date: Calendar.current.date(byAdding: .day, value: 2, to: now)!)
        ]
        
        return service
    }
}
