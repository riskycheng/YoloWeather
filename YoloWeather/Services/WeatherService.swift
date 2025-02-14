import Foundation
import WeatherKit
import CoreLocation

enum WeatherError: Error {
    case cityNameResolutionFailed
    case weatherDataFetchFailed
    case invalidLocation
}

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
    @Published private(set) var currentCityName: String?
    
    private var location: CLLocation
    private var cityWeatherCache: [String: CurrentWeather] = [:]
    
    // 添加历史天气数据存储
    private let userDefaults = UserDefaults.standard
    private let historicalWeatherKey = "historical_weather"
    private let hourlyWeatherKey = "hourly_weather"
    
    // 城市坐标映射
    private let cityCoordinates: [String: CLLocation] = [
        "上海市": CLLocation(latitude: 31.2304, longitude: 121.4737),
        "北京市": CLLocation(latitude: 39.9042, longitude: 116.4074),
        "香港": CLLocation(latitude: 22.3193, longitude: 114.1694),
        "东京": CLLocation(latitude: 35.6762, longitude: 139.6503),
        "新加坡": CLLocation(latitude: 1.3521, longitude: 103.8198),
        "旧金山": CLLocation(latitude: 37.7749, longitude: -122.4194),
        "冰岛": CLLocation(latitude: 64.9631, longitude: -19.0208)
    ]
    
    // 添加小时天气数据结构
    struct HourlyWeatherData: Codable {
        let date: Date
        let temperature: Double
        let condition: String
        let symbolName: String
    }
    
    // 添加新的数据结构用于存储历史天气数据
    private struct HistoricalWeatherData: Codable {
        let date: Date
        let condition: String
        let symbolName: String
        let lowTemperature: Double
        let highTemperature: Double
        let precipitationProbability: Double
    }
    
    private init() {
        location = CLLocation(latitude: 31.230416, longitude: 121.473701) // 默认上海
    }
    
    func clearCurrentWeather() {
        currentWeather = nil
        hourlyForecast = []
        dailyForecast = []
        lastUpdateTime = nil
        currentCityName = nil
        errorMessage = nil
    }
    
    // 清除当前城市名称
    func clearCurrentCityName() {
        currentCityName = nil
    }
    
    // 获取昨天的天气数据
    func getYesterdayWeather(for cityName: String) -> DayWeatherInfo? {
        guard let historicalData = UserDefaults.standard.dictionary(forKey: historicalWeatherKey) as? [String: [[String: Any]]],
              let cityHistory = historicalData[cityName] else {
            return nil
        }
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        
        // 查找昨天的数据
        for record in cityHistory {
            guard let dateString = record["date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString),
                  calendar.isDate(date, inSameDayAs: yesterdayStart),
                  let condition = record["condition"] as? String,
                  let symbolName = record["symbolName"] as? String,
                  let lowTemp = record["lowTemperature"] as? Double,
                  let highTemp = record["highTemperature"] as? Double else {
                continue
            }
            
            return DayWeatherInfo(
                date: date,
                condition: condition,
                symbolName: symbolName,
                lowTemperature: lowTemp,
                highTemperature: highTemp,
                precipitationProbability: record["precipitationProbability"] as? Double ?? 0
            )
        }
        
        return nil
    }
    
    // 存储今天的天气数据
    private func saveCurrentWeather(cityName: String, weather: DayWeatherInfo) {
        var historicalData = UserDefaults.standard.dictionary(forKey: historicalWeatherKey) as? [String: [[String: Any]]] ?? [:]
        
        // 获取当前城市的历史数据
        var cityHistory = historicalData[cityName] as? [[String: Any]] ?? []
        
        // 创建新的天气记录
        let newWeatherRecord: [String: Any] = [
            "date": ISO8601DateFormatter().string(from: weather.date),
            "condition": weather.condition,
            "symbolName": weather.symbolName,
            "lowTemperature": weather.lowTemperature,
            "highTemperature": weather.highTemperature,
            "precipitationProbability": weather.precipitationProbability ?? 0
        ]
        
        // 检查是否已经存在今天的数据
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 移除超过7天的数据
        cityHistory = cityHistory.filter { record in
            guard let dateString = record["date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString) else {
                return false
            }
            let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: today).day ?? 0
            return daysDifference <= 7
        }
        
        // 更新或添加今天的数据
        if let index = cityHistory.firstIndex(where: { record in
            guard let dateString = record["date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString) else {
                return false
            }
            return calendar.isDate(date, inSameDayAs: weather.date)
        }) {
            cityHistory[index] = newWeatherRecord
        } else {
            cityHistory.append(newWeatherRecord)
        }
        
        // 更新存储
        historicalData[cityName] = cityHistory
        UserDefaults.standard.set(historicalData, forKey: historicalWeatherKey)
    }
    
    // 保存小时天气数据
    private func saveHourlyWeather(cityName: String, hourlyData: [HourlyWeatherData]) {
        var allHourlyData = userDefaults.dictionary(forKey: hourlyWeatherKey) as? [String: [[String: Any]]] ?? [:]
        
        // 转换为可存储格式
        let storableData = hourlyData.map { hourData -> [String: Any] in
            return [
                "date": ISO8601DateFormatter().string(from: hourData.date),
                "temperature": hourData.temperature,
                "condition": hourData.condition,
                "symbolName": hourData.symbolName
            ]
        }
        
        allHourlyData[cityName] = storableData
        userDefaults.set(allHourlyData, forKey: hourlyWeatherKey)
    }
    
    // 获取过去24小时的天气数据
    func getPast24HourWeather(for cityName: String) -> [HourlyWeatherData] {
        guard let allHourlyData = userDefaults.dictionary(forKey: hourlyWeatherKey) as? [String: [[String: Any]]],
              let cityData = allHourlyData[cityName] else {
            return []
        }
        
        let now = Date()
        let past24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        
        return cityData.compactMap { hourData -> HourlyWeatherData? in
            guard let dateString = hourData["date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString),
                  let temperature = hourData["temperature"] as? Double,
                  let condition = hourData["condition"] as? String,
                  let symbolName = hourData["symbolName"] as? String,
                  date >= past24Hours && date <= now else {
                return nil
            }
            
            return HourlyWeatherData(
                date: date,
                temperature: temperature,
                condition: condition,
                symbolName: symbolName
            )
        }
    }
    
    // 更新指定城市的天气数据
    func updateWeather(for location: CLLocation, cityName: String? = nil) async {
        // 如果提供了城市名称，使用预设的城市坐标
        let weatherLocation: CLLocation
        if let cityName = cityName, let cityLocation = cityCoordinates[cityName] {
            weatherLocation = cityLocation
        } else {
            weatherLocation = location
        }
        
        // 清除之前的数据
        clearCurrentWeather()
        
        self.location = weatherLocation
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 如果没有提供城市名称，尝试进行反向地理编码
            let resolvedCityName: String
            if let providedCityName = cityName {
                resolvedCityName = providedCityName
            } else {
                if let geocodedCity = await reverseGeocode(location: weatherLocation) {
                    resolvedCityName = geocodedCity
                } else {
                    throw WeatherError.cityNameResolutionFailed
                }
            }
            
            // 更新当前选中的城市名称
            self.currentCityName = resolvedCityName
            
            // 获取时区信息
            let timezone = await calculateTimezone(for: weatherLocation, cityName: resolvedCityName)
            
            // 获取天气数据
            let weather = try await weatherService.weather(for: weatherLocation)
            
            // 更新当前天气
            let now = Date()
            let currentHour = Calendar.current.component(.hour, from: now)
            let isNightTime = currentHour >= 18 || currentHour < 6
            
            // 更新当前天气数据
            currentWeather = CurrentWeather(
                date: now,
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                condition: getWeatherConditionText(weather.currentWeather.condition),
                symbolName: getWeatherSymbolName(condition: weather.currentWeather.condition, isNight: isNightTime),
                windSpeed: weather.currentWeather.wind.speed.value,
                precipitationChance: weather.hourlyForecast.forecast.first?.precipitationChance ?? 0.0,
                uvIndex: Int(weather.currentWeather.uvIndex.value),
                humidity: weather.currentWeather.humidity,
                airQualityIndex: 75,
                pressure: weather.currentWeather.pressure.value,
                visibility: weather.currentWeather.visibility.value,
                timezone: timezone,
                weatherCondition: weather.currentWeather.condition,
                highTemperature: weather.dailyForecast.forecast.first?.highTemperature.value ?? weather.currentWeather.temperature.value + 2,
                lowTemperature: weather.dailyForecast.forecast.first?.lowTemperature.value ?? weather.currentWeather.temperature.value - 2
            )
            
            // 更新小时预报
            hourlyForecast = weather.hourlyForecast.forecast.prefix(24).map { hour in
                let hourComponent = Calendar.current.component(.hour, from: hour.date)
                let isHourNight = hourComponent >= 18 || hourComponent < 6
                
                return HourlyForecast(
                    temperature: hour.temperature.value,
                    condition: hour.condition,
                    date: hour.date,
                    symbolName: getWeatherSymbolName(condition: hour.condition, isNight: isHourNight),
                    conditionText: getWeatherConditionText(hour.condition)
                )
            }
            
            // 更新每日预报
            dailyForecast = weather.dailyForecast.forecast.prefix(10).map { day in
                DayWeatherInfo(
                    date: day.date,
                    condition: getWeatherConditionText(day.condition),
                    symbolName: getWeatherSymbolName(condition: day.condition, isNight: false),
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value,
                    precipitationProbability: day.precipitationChance
                )
            }
            
            // 更新最后更新时间
            lastUpdateTime = Date()
            
            // 保存当前天气数据到历史记录
            if let todayWeather = dailyForecast.first {
                saveCurrentWeather(cityName: resolvedCityName, weather: todayWeather)
            }
            
            // 保存小时天气数据
            let hourlyData = hourlyForecast.map { forecast in
                HourlyWeatherData(
                    date: forecast.date,
                    temperature: forecast.temperature,
                    condition: forecast.conditionText,
                    symbolName: forecast.symbolName
                )
            }
            saveHourlyWeather(cityName: resolvedCityName, hourlyData: hourlyData)
            
            // 更新城市天气缓存
            if let current = currentWeather {
                cityWeatherCache[resolvedCityName] = current
            }
            
            errorMessage = nil
        } catch {
            // 保留错误日志
            print("WeatherService - 更新天气数据失败: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            
            // 尝试使用缓存数据
            if let cityName = cityName ?? currentCityName,
               let cachedWeather = cityWeatherCache[cityName] {
                print("WeatherService - 使用缓存数据: \(cityName)")
                currentWeather = cachedWeather
            }
        }
    }
    
    // 获取缓存的城市天气数据
    func getCachedWeather(for cityName: String) -> CurrentWeather? {
        return cityWeatherCache[cityName]
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
    
    private func calculateTimezone(for location: CLLocation, cityName: String? = nil) async -> TimeZone {
        let geocoder = CLGeocoder()
        
        // 如果有城市名称，优先使用城市名称判断时区
        if let cityName = cityName {
            // 中国城市的特殊处理
            if cityName == "香港" {
                return TimeZone(identifier: "Asia/Hong_Kong")!
            } else if cityName == "澳门" {
                return TimeZone(identifier: "Asia/Macau")!
            } else if cityName.hasSuffix("市") || cityName.hasSuffix("省") || cityName == "台北" {
                return TimeZone(identifier: "Asia/Shanghai")!
            }
            
            // 检查是否匹配已知城市
            let knownCities: [(name: String, timezone: String)] = [
                ("纽约", "America/New_York"),
                ("洛杉矶", "America/Los_Angeles"),
                ("芝加哥", "America/Chicago"),
                ("上海", "Asia/Shanghai"),
                ("北京", "Asia/Shanghai"),
                ("天津", "Asia/Shanghai"),
                ("香港", "Asia/Hong_Kong"),
                ("东京", "Asia/Tokyo"),
                ("伦敦", "Europe/London"),
                ("巴黎", "Europe/Paris")
            ]
            
            if let knownCity = knownCities.first(where: { $0.name == cityName }) {
                return TimeZone(identifier: knownCity.timezone)!
            }
        }
        
        // 中国大陆经纬度范围判断
        if location.coordinate.longitude >= 73 && location.coordinate.longitude <= 135 &&
           location.coordinate.latitude >= 18 && location.coordinate.latitude <= 54 {
            // 香港特别行政区的经纬度范围
            if location.coordinate.longitude >= 113.8 && location.coordinate.longitude <= 114.4 &&
               location.coordinate.latitude >= 22.1 && location.coordinate.latitude <= 22.6 {
                return TimeZone(identifier: "Asia/Hong_Kong")!
            }
            // 澳门特别行政区的经纬度范围
            else if location.coordinate.longitude >= 113.5 && location.coordinate.longitude <= 113.6 &&
                    location.coordinate.latitude >= 22.1 && location.coordinate.latitude <= 22.2 {
                return TimeZone(identifier: "Asia/Macau")!
            }
            else {
                return TimeZone(identifier: "Asia/Shanghai")!
            }
        }
        
        // 其他情况使用地理编码
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                if let placemarkTimezone = placemark.timeZone {
                    return placemarkTimezone
                }
                
                // 如果没有直接获取到时区，根据国家和经度来判断
                if let countryCode = placemark.isoCountryCode {
                    switch countryCode {
                    case "CN": // 中国
                        return TimeZone(identifier: "Asia/Shanghai")!
                    case "HK": // 香港
                        return TimeZone(identifier: "Asia/Hong_Kong")!
                    case "MO": // 澳门
                        return TimeZone(identifier: "Asia/Macau")!
                    case "TW": // 台湾
                        return TimeZone(identifier: "Asia/Taipei")!
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
                        return defaultTZ
                    }
                }
            }
            
            // 如果地理编码失败，使用经纬度范围判断
            let defaultTZ = getDefaultTimezone(for: location)
            return defaultTZ
            
        } catch {
            let defaultTZ = getDefaultTimezone(for: location)
            return defaultTZ
        }
    }
    
    // 获取天气图标名称
    internal func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        let symbolName: String
        switch condition {
        case .clear:
            symbolName = isNight ? "full_moon" : "sunny"
        case .mostlyClear:
            symbolName = isNight ? "moon_stars" : "sunny"
        case .partlyCloudy, .mostlyCloudy:
            symbolName = isNight ? "partly_cloudy_night" : "partly_cloudy_daytime"
        case .cloudy:
            symbolName = isNight ? "moon_cloudy" : "cloudy"
        case .drizzle:
            symbolName = "light_rain"
        case .rain:
            symbolName = "moderate_rain"
        case .heavyRain:
            symbolName = "heavy_rain"
        case .snow:
            symbolName = "light_snow"
        case .heavySnow:
            symbolName = "heavy_snow"
        case .sleet:
            symbolName = "wet"
        case .freezingDrizzle:
            symbolName = "wet"
        case .strongStorms:
            symbolName = "thunderstorm"
        case .windy:
            symbolName = "windy"
        case .foggy:
            symbolName = "fog"
        case .haze:
            symbolName = "haze"
        case .hot:
            symbolName = "high_temperature"
        case .blizzard:
            symbolName = "blizzard"
        case .blowingDust:
            symbolName = "blowing_sand"
        case .tropicalStorm:
            symbolName = "rainstorm"
        case .hurricane:
            symbolName = "typhoon"
        default:
            symbolName = isNight ? "moon_stars" : "sunny"
        }
        
        return symbolName
    }
    
    // 判断是否为夜间
    internal func isNight(for date: Date, in timezone: TimeZone) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let hour = calendar.component(.hour, from: date)
        
        // 根据时间段判断是否为夜晚
        // 夜晚：晚上6点到早上6点
        return hour < 6 || hour >= 18
    }
    
    // 获取城市的预设坐标
    func getPresetLocation(for cityName: String) -> CLLocation? {
        return cityCoordinates[cityName]
    }
    
    // 小时预报结构体
    struct HourlyForecast: Identifiable {
        let id = UUID()
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
    
    struct DayWeatherInfo {
        let date: Date
        let condition: String
        let symbolName: String
        let lowTemperature: Double
        let highTemperature: Double
        let precipitationProbability: Double
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
        service.hourlyForecast = (0..<24).map { i -> HourlyForecast in
            let futureDate = Calendar.current.date(byAdding: .hour, value: i, to: now)!
            let calendar = Calendar.current
            let hourComponent = calendar.component(.hour, from: futureDate)
            let isNight = hourComponent < 6 || hourComponent >= 18
            let symbol = isNight ? "full_moon" : "sunny"
            
            return HourlyForecast(
                temperature: 25 + Double.random(in: -5...5),
                condition: .clear,
                date: futureDate,
                symbolName: symbol,
                conditionText: "晴"
            )
        }
        
        // 模拟每日预报
        service.dailyForecast = [
            DayWeatherInfo(date: now, condition: "晴", symbolName: "sunny", lowTemperature: 20, highTemperature: 30, precipitationProbability: 0.5),
            DayWeatherInfo(date: Calendar.current.date(byAdding: .day, value: 1, to: now)!, condition: "多云", symbolName: "cloudy", lowTemperature: 19, highTemperature: 29, precipitationProbability: 0.5),
            DayWeatherInfo(date: Calendar.current.date(byAdding: .day, value: 2, to: now)!, condition: "小雨", symbolName: "rain", lowTemperature: 18, highTemperature: 28, precipitationProbability: 0.5)
        ]
        
        return service
    }
    
    private func reverseGeocode(location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // 中国城市的特殊处理
                if placemark.isoCountryCode == "CN" {
                    if let city = placemark.locality {
                        return city.hasSuffix("市") ? city : "\(city)市"
                    } else if let adminArea = placemark.administrativeArea {
                        return adminArea
                    }
                } else {
                    // 非中国城市，使用locality或administrativeArea
                    return placemark.locality ?? placemark.administrativeArea
                }
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func handleError(_ error: Error) {
        if let weatherError = error as? WeatherError {
            switch weatherError {
            case .cityNameResolutionFailed:
                errorMessage = "无法获取城市名称"
            case .weatherDataFetchFailed:
                errorMessage = "获取天气数据失败"
            case .invalidLocation:
                errorMessage = "无效的位置信息"
            }
        } else {
            errorMessage = "发生未知错误: \(error.localizedDescription)"
        }
    }
    
    // 获取指定城市的所有历史天气数据
    func getHistoricalWeather(for cityName: String) -> [DayWeatherInfo] {
        guard let historicalData = UserDefaults.standard.dictionary(forKey: historicalWeatherKey) as? [String: [[String: Any]]],
              let cityHistory = historicalData[cityName] else {
            return []
        }
        
        return cityHistory.compactMap { record in
            guard let dateString = record["date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString),
                  let condition = record["condition"] as? String,
                  let symbolName = record["symbolName"] as? String,
                  let lowTemp = record["lowTemperature"] as? Double,
                  let highTemp = record["highTemperature"] as? Double else {
                return nil
            }
            
            return DayWeatherInfo(
                date: date,
                condition: condition,
                symbolName: symbolName,
                lowTemperature: lowTemp,
                highTemperature: highTemp,
                precipitationProbability: record["precipitationProbability"] as? Double ?? 0
            )
        }.sorted { $0.date > $1.date }
    }
}
