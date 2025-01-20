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
        print("WeatherService - 开始获取天气数据")
        print("WeatherService - 请求位置: 纬度 \(location.coordinate.latitude), 经度 \(location.coordinate.longitude)")
        
        self.location = location
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 先获取时区
            let timezone = await calculateTimezone(for: location)
            print("WeatherService - 使用时区: \(timezone.identifier)")
            
            // 获取天气数据
            let weather = try await weatherService.weather(for: location)
            print("WeatherService - 成功获取天气数据")
            
            // 使用获取到的时区创建日历
            var calendar = Calendar.current
            calendar.timeZone = timezone
            
            // 获取当前时间在目标时区的小时数
            let now = Date()
            let currentHour = calendar.component(.hour, from: now)
            let isNightTime = isNight(for: now, in: timezone)
            
            print("WeatherService - 目标时区: \(timezone.identifier)")
            print("WeatherService - UTC时间: \(now)")
            print("WeatherService - 当地时间: \(currentHour)点")
            print("WeatherService - 是否夜晚: \(isNightTime)")
            
            let symbolName = getWeatherSymbolName(condition: weather.currentWeather.condition, isNight: isNightTime)
            let dailyForecast = weather.dailyForecast.forecast.first
            
            // 更新当前天气
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
                timezone: timezone,
                weatherCondition: weather.currentWeather.condition,
                highTemperature: dailyForecast?.highTemperature.value ?? weather.currentWeather.temperature.value + 3,
                lowTemperature: dailyForecast?.lowTemperature.value ?? weather.currentWeather.temperature.value - 3
            )
            
            // 更新小时预报
            var forecasts: [HourlyForecast] = []
            for hour in weather.hourlyForecast.filter({ $0.date.timeIntervalSince(Date()) >= 0 }).prefix(24) {
                let hourComponent = calendar.component(.hour, from: hour.date)
                let isHourNight = isNight(for: hour.date, in: timezone)
                
                print("WeatherService - 小时预报 - 时间: \(hour.date), 当地时间: \(hourComponent)点, 是否夜晚: \(isHourNight)")
                
                let forecast = HourlyForecast(
                    id: UUID(),
                    temperature: hour.temperature.value,
                    condition: hour.condition,
                    date: hour.date,
                    symbolName: getWeatherSymbolName(condition: hour.condition, isNight: isHourNight),
                    conditionText: getWeatherConditionText(hour.condition)
                )
                forecasts.append(forecast)
            }
            hourlyForecast = forecasts
            
            // 更新每日预报
            var dailyForecasts: [DayWeatherInfo] = []
            for day in weather.dailyForecast.forecast.prefix(7) {
                let daySymbolName = getWeatherSymbolName(condition: day.condition, isNight: false)
                
                let forecast = DayWeatherInfo(
                    date: day.date,
                    condition: getWeatherConditionText(day.condition),
                    symbolName: daySymbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value
                )
                dailyForecasts.append(forecast)
            }
            self.dailyForecast = dailyForecasts
            
            lastUpdateTime = Date()
            errorMessage = nil
            
            print("WeatherService - 天气数据更新完成")
        } catch {
            print("WeatherService - 获取天气数据失败: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // 将 WeatherKit 的天气状况转换为中文描述
    internal func getWeatherConditionText(_ condition: WeatherCondition) -> String {
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
    
    private func getDefaultTimezone(for location: CLLocation) -> TimeZone {
        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude
        
        // 基于经纬度范围判断时区
        switch (longitude, latitude) {
        // 北美洲
        case (-140...(-100), 30...60):
            if longitude <= -115 {
                return TimeZone(identifier: "America/Los_Angeles")! // 太平洋时区
            } else if longitude <= -100 {
                return TimeZone(identifier: "America/Denver")! // 山地时区
            } else {
                return TimeZone(identifier: "America/Chicago")! // 中部时区
            }
        
        // 欧洲
        case (-10...40, 35...70):
            if longitude <= 0 {
                return TimeZone(identifier: "Europe/London")!
            } else if longitude <= 15 {
                return TimeZone(identifier: "Europe/Paris")!
            } else {
                return TimeZone(identifier: "Europe/Moscow")!
            }
        
        // 亚洲
        case (100...145, 20...50):
            if longitude <= 120 {
                return TimeZone(identifier: "Asia/Shanghai")!
            } else if longitude <= 140 {
                return TimeZone(identifier: "Asia/Tokyo")!
            } else {
                return TimeZone(identifier: "Asia/Seoul")!
            }
            
        default:
            // 如果无法确定，使用基于经度的粗略计算
            let hourOffset = Int(round(longitude / 15.0))
            if let timezone = TimeZone(secondsFromGMT: hourOffset * 3600) {
                return timezone
            }
            return TimeZone(identifier: "UTC")!
        }
    }
    
    private func calculateTimezone(for location: CLLocation) async -> TimeZone {
        let geocoder = CLGeocoder()
        print("正在计算位置 (\(location.coordinate.latitude), \(location.coordinate.longitude)) 的时区")
        
        // 首先检查是否是已知的特定城市坐标
        let knownCities: [(name: String, coordinates: (lat: Double, lon: Double), timezone: String)] = [
            ("纽约", (40.7128, -74.006), "America/New_York"),
            ("洛杉矶", (34.0522, -118.2437), "America/Los_Angeles"),
            ("芝加哥", (41.8781, -87.6298), "America/Chicago"),
            ("上海", (31.2304, 121.4737), "Asia/Shanghai"),
            ("北京", (39.9042, 116.4074), "Asia/Shanghai"),
            ("天津", (39.0842, 117.2009), "Asia/Shanghai"),
            ("香港", (22.3193, 114.1694), "Asia/Hong_Kong"),
            ("东京", (35.6762, 139.6503), "Asia/Tokyo"),
            ("伦敦", (51.5074, -0.1278), "Europe/London"),
            ("巴黎", (48.8566, 2.3522), "Europe/Paris")
        ]
        
        // 检查是否匹配已知城市（允许0.1度的误差）
        for city in knownCities {
            let latDiff = abs(location.coordinate.latitude - city.coordinates.lat)
            let lonDiff = abs(location.coordinate.longitude - city.coordinates.lon)
            if latDiff < 0.1 && lonDiff < 0.1 {
                print("找到匹配的已知城市: \(city.name), 使用时区: \(city.timezone)")
                return TimeZone(identifier: city.timezone)!
            }
        }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                print("获取到位置信息: \(placemark.locality ?? "未知城市"), \(placemark.administrativeArea ?? "未知地区"), \(placemark.country ?? "未知国家")")
                
                if let placemarkTimezone = placemark.timeZone {
                    print("从位置信息获取到时区: \(placemarkTimezone.identifier)")
                    return placemarkTimezone
                }
                
                // 如果没有直接获取到时区，根据国家和经度来判断
                if let countryCode = placemark.isoCountryCode {
                    print("尝试根据国家代码确定时区: \(countryCode)")
                    
                    switch countryCode {
                    case "CN": // 中国
                        return TimeZone(identifier: "Asia/Shanghai")!
                    case "US": // 美国
                        let longitude = location.coordinate.longitude
                        if longitude <= -115 {
                            return TimeZone(identifier: "America/Los_Angeles")!
                        } else if longitude <= -100 {
                            return TimeZone(identifier: "America/Denver")!
                        } else if longitude <= -87 {
                            return TimeZone(identifier: "America/Chicago")!
                        } else {
                            return TimeZone(identifier: "America/New_York")!
                        }
                    case "JP": // 日本
                        return TimeZone(identifier: "Asia/Tokyo")!
                    case "KR": // 韩国
                        return TimeZone(identifier: "Asia/Seoul")!
                    case "GB": // 英国
                        return TimeZone(identifier: "Europe/London")!
                    case "DE": // 德国
                        return TimeZone(identifier: "Europe/Berlin")!
                    case "FR": // 法国
                        return TimeZone(identifier: "Europe/Paris")!
                    case "AU": // 澳大利亚
                        if location.coordinate.longitude >= 142 {
                            return TimeZone(identifier: "Australia/Sydney")!
                        } else {
                            return TimeZone(identifier: "Australia/Perth")!
                        }
                    default:
                        let defaultTZ = getDefaultTimezone(for: location)
                        print("未找到国家对应的时区，使用经纬度计算的时区: \(defaultTZ.identifier)")
                        return defaultTZ
                    }
                }
            }
            
            // 如果地理编码失败，使用经纬度范围判断
            let defaultTZ = getDefaultTimezone(for: location)
            print("未能获取位置信息，使用经纬度计算的时区: \(defaultTZ.identifier)")
            return defaultTZ
            
        } catch {
            print("反地理编码错误: \(error.localizedDescription)")
            
            // 对于美国城市的特殊处理
            let longitude = location.coordinate.longitude
            let latitude = location.coordinate.latitude
            
            // 检查是否在美国范围内
            if latitude >= 24.396308 && latitude <= 49.384358 && // 美国大致纬度范围
               longitude >= -125.000000 && longitude <= -66.934570 { // 美国大致经度范围
                if longitude <= -115 {
                    return TimeZone(identifier: "America/Los_Angeles")!
                } else if longitude <= -100 {
                    return TimeZone(identifier: "America/Denver")!
                } else if longitude <= -87 {
                    return TimeZone(identifier: "America/Chicago")!
                } else {
                    return TimeZone(identifier: "America/New_York")!
                }
            }
            
            let defaultTZ = getDefaultTimezone(for: location)
            print("使用经纬度计算的时区: \(defaultTZ.identifier)")
            return defaultTZ
        }
    }
    
    // 获取天气图标名称
    internal func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        // 首先判断是否为夜晚
        let timeBasedPrefix = isNight ? "night_" : "day_"
        
        // 根据天气状况选择基础图标名称
        let baseSymbol: String
        switch condition {
        case .clear, .mostlyClear, .hot:
            return isNight ? "full_moon" : "sunny"
        case .cloudy:
            return isNight ? "moon_cloudy" : "cloudy"
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
    internal func isNight(for date: Date, in timezone: TimeZone) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let hour = calendar.component(.hour, from: date)
        
        print("isNight 计算 - 时区: \(timezone.identifier)")
        print("isNight 计算 - UTC时间: \(date)")
        print("isNight 计算 - 当地时间: \(hour)点")
        print("isNight 计算 - 是否夜晚: \(hour < 6 || hour >= 18)")
        
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
        let highTemperature: Double
        let lowTemperature: Double
        
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
                weatherCondition: .clear,
                highTemperature: temp + 3,
                lowTemperature: temp - 3
            )
        }
    }
    
    struct DayWeatherInfo: Identifiable {
        let id = UUID()
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
            weatherCondition: .clear,
            highTemperature: 28,
            lowTemperature: 24
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
