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
    private var isBatchUpdating: Bool = false
    private var totalCities: Int = 0
    private var currentCityIndex: Int = 0
    private var batchUpdateStartTime: Date?
    
    // 添加历史天气数据存储
    private let userDefaults = UserDefaults.standard
    private let historicalWeatherKey = "historical_weather"
    private let hourlyWeatherKey = "hourly_weather"
    
    // 城市坐标映射
    private let cityCoordinates: [String: CLLocation] = [
        // 华北地区
        "北京市": CLLocation(latitude: 39.9042, longitude: 116.4074),
        "天津市": CLLocation(latitude: 39.0842, longitude: 117.2009),
        "石家庄市": CLLocation(latitude: 38.0428, longitude: 114.5149),
        "太原市": CLLocation(latitude: 37.8706, longitude: 112.5489),
        "呼和浩特市": CLLocation(latitude: 40.8427, longitude: 111.7498),

        // 东北地区
        "沈阳市": CLLocation(latitude: 41.8057, longitude: 123.4315),
        "长春市": CLLocation(latitude: 43.8168, longitude: 125.3240),
        "哈尔滨市": CLLocation(latitude: 45.8038, longitude: 126.5340),
        "大连市": CLLocation(latitude: 38.9140, longitude: 121.6147),

        // 华东地区
        "上海市": CLLocation(latitude: 31.2304, longitude: 121.4737),
        "南京市": CLLocation(latitude: 32.0603, longitude: 118.7969),
        "杭州市": CLLocation(latitude: 30.2741, longitude: 120.1551),
        "济南市": CLLocation(latitude: 36.6512, longitude: 117.1201),
        "青岛市": CLLocation(latitude: 36.0671, longitude: 120.3826),
        "厦门市": CLLocation(latitude: 24.4798, longitude: 118.0894),
        "福州市": CLLocation(latitude: 26.0745, longitude: 119.2965),
        "合肥市": CLLocation(latitude: 31.8206, longitude: 117.2272),
        "南昌市": CLLocation(latitude: 28.6820, longitude: 115.8579),
        "苏州市": CLLocation(latitude: 31.2989, longitude: 120.5853),
        "宁波市": CLLocation(latitude: 29.8683, longitude: 121.5440),
        "无锡市": CLLocation(latitude: 31.4900, longitude: 120.3117),
        "高邮市": CLLocation(latitude: 32.7811, longitude: 119.4461),

        // 中南地区
        "广州市": CLLocation(latitude: 23.1291, longitude: 113.2644),
        "深圳市": CLLocation(latitude: 22.5431, longitude: 114.0579),
        "武汉市": CLLocation(latitude: 30.5928, longitude: 114.3055),
        "长沙市": CLLocation(latitude: 28.2278, longitude: 112.9388),
        "南宁市": CLLocation(latitude: 22.8170, longitude: 108.3665),
        "海口市": CLLocation(latitude: 20.0440, longitude: 110.1920),
        "郑州市": CLLocation(latitude: 34.7472, longitude: 113.6249),

        // 西南地区
        "重庆市": CLLocation(latitude: 29.4316, longitude: 106.9123),
        "成都市": CLLocation(latitude: 30.5728, longitude: 104.0668),
        "贵阳市": CLLocation(latitude: 26.6470, longitude: 106.6302),
        "昆明市": CLLocation(latitude: 24.8801, longitude: 102.8329),
        "拉萨市": CLLocation(latitude: 29.6500, longitude: 91.1409),

        // 西北地区
        "西安市": CLLocation(latitude: 34.3416, longitude: 108.9398),
        "兰州市": CLLocation(latitude: 36.0611, longitude: 103.8343),
        "西宁市": CLLocation(latitude: 36.6232, longitude: 101.7804),
        "银川市": CLLocation(latitude: 38.4872, longitude: 106.2309),
        "乌鲁木齐市": CLLocation(latitude: 43.8256, longitude: 87.6168),

        // 特别行政区
        "香港": CLLocation(latitude: 22.3193, longitude: 114.1694),
        "澳门": CLLocation(latitude: 22.1987, longitude: 113.5439),

        // 国际城市
        "东京": CLLocation(latitude: 35.6762, longitude: 139.6503),
        "首尔": CLLocation(latitude: 37.5665, longitude: 126.9780),
        "新加坡": CLLocation(latitude: 1.3521, longitude: 103.8198),
        "曼谷": CLLocation(latitude: 13.7563, longitude: 100.5018),
        "吉隆坡": CLLocation(latitude: 3.1390, longitude: 101.6869),
        "纽约": CLLocation(latitude: 40.7128, longitude: -74.0060),
        "伦敦": CLLocation(latitude: 51.5074, longitude: -0.1278),
        "巴黎": CLLocation(latitude: 48.8566, longitude: 2.3522),
        "柏林": CLLocation(latitude: 52.5200, longitude: 13.4050),
        "莫斯科": CLLocation(latitude: 55.7558, longitude: 37.6173),
        "悉尼": CLLocation(latitude: -33.8688, longitude: 151.2093),
        "墨尔本": CLLocation(latitude: -37.8136, longitude: 144.9631),
        "迪拜": CLLocation(latitude: 25.2048, longitude: 55.2708),
        "温哥华": CLLocation(latitude: 49.2827, longitude: -123.1207),
        "多伦多": CLLocation(latitude: 43.6532, longitude: -79.3832)
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
    
    // 添加批量更新方法
    func batchUpdateWeather(for cities: [String]) async {
        self.totalCities = cities.count
        self.currentCityIndex = 0
        self.batchUpdateStartTime = Date()
        
        for city in cities {
            if let location = cityCoordinates[city] {
                await updateWeather(for: location, cityName: city, isBatchUpdate: true, totalCities: cities.count)
            }
        }
        
        // 批量更新完成后显示汇总信息
        showBatchUpdateSummary()
    }
    
    // 更新指定城市的天气数据
    func updateWeather(for location: CLLocation, cityName: String? = nil, isBatchUpdate: Bool = false, totalCities: Int = 0) async {
        // 如果提供了城市名称，直接使用它
        let weatherLocation: CLLocation
        if let cityName = cityName {
            self.currentCityName = cityName
            // 使用提供的位置，而不是从cityCoordinates获取
            weatherLocation = location
        } else {
            weatherLocation = location
            // 如果没有提供城市名称，尝试通过坐标反向查找
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let city = placemarks.first?.locality {
                    self.currentCityName = city
                }
            } catch {
                print("无法获取城市名称: \(error.localizedDescription)")
            }
        }
        
        isLoading = true
        defer { isLoading = false }
        
        if isBatchUpdate {
            currentCityIndex += 1
        }
        
        do {
            // 获取时区信息
            let timezone = await calculateTimezone(for: weatherLocation, cityName: self.currentCityName)
            
            // 获取天气数据
            let weather = try await weatherService.weather(for: weatherLocation)
            
            // 设置日历和当前时间
            var calendar = Calendar.current
            calendar.timeZone = timezone
            let now = Date()
            let currentHour = calendar.component(.hour, from: now)
            let isNightTime = currentHour >= 18 || currentHour < 6
            let currentHourDate = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now)) ?? now
            
            // Convert WeatherKit condition to our custom WeatherCondition
            let newCondition = convertWeatherKitCondition(weather.currentWeather.condition)
            
            // 更新当前天气数据
            let newCurrentWeather = CurrentWeather(
                date: now,
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                condition: newCondition.description,
                symbolName: getWeatherSymbolName(condition: newCondition, isNight: isNightTime),
                windSpeed: weather.currentWeather.wind.speed.value,
                precipitationChance: weather.hourlyForecast.forecast.first?.precipitationChance ?? 0.0,
                uvIndex: Int(weather.currentWeather.uvIndex.value),
                humidity: weather.currentWeather.humidity,
                airQualityIndex: 75,
                pressure: weather.currentWeather.pressure.value,
                visibility: weather.currentWeather.visibility.value,
                timezone: timezone,
                weatherCondition: newCondition,
                highTemperature: weather.dailyForecast.forecast.first?.highTemperature.value ?? weather.currentWeather.temperature.value + 2,
                lowTemperature: weather.dailyForecast.forecast.first?.lowTemperature.value ?? weather.currentWeather.temperature.value - 2
            )
            
            // 更新当前天气和缓存
            currentWeather = newCurrentWeather
            if let cityName = self.currentCityName {
                cityWeatherCache[cityName] = newCurrentWeather
            }
            
            // 更新小时预报
            hourlyForecast = weather.hourlyForecast.forecast
                .filter { hour in
                    hour.date >= currentHourDate
                }
                .prefix(24)
                .map { hour in
                    let hourComponent = calendar.component(.hour, from: hour.date)
                    let isHourNight = hourComponent >= 18 || hourComponent < 6
                    let condition = convertWeatherKitCondition(hour.condition)
                    
                    return HourlyForecast(
                        temperature: hour.temperature.value,
                        condition: condition,
                        date: hour.date,
                        symbolName: getWeatherSymbolName(condition: condition, isNight: isHourNight),
                        conditionText: condition.description
                    )
                }
            
            // 更新每日预报
            dailyForecast = weather.dailyForecast.forecast.prefix(10).map { day in
                let condition = convertWeatherKitCondition(day.condition)
                return DayWeatherInfo(
                    date: day.date,
                    condition: condition.description,
                    symbolName: getWeatherSymbolName(condition: condition, isNight: false),
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value,
                    precipitationProbability: day.precipitationChance
                )
            }
            
            // 更新最后更新时间
            lastUpdateTime = Date()
            
            // 保存当前天气数据到历史记录
            if let todayWeather = dailyForecast.first {
                saveCurrentWeather(cityName: self.currentCityName ?? "", weather: todayWeather)
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
            saveHourlyWeather(cityName: self.currentCityName ?? "", hourlyData: hourlyData)
            
            errorMessage = nil
            
        } catch {
            errorMessage = error.localizedDescription
            
            if let cityName = cityName ?? currentCityName,
               let cachedWeather = cityWeatherCache[cityName] {
                currentWeather = cachedWeather
            }
        }
        
        if isBatchUpdate && currentCityIndex == totalCities {
            self.batchUpdateStartTime = nil
            self.totalCities = 0
            self.currentCityIndex = 0
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
    
    // Convert WeatherKit condition to our custom WeatherCondition
    private func convertWeatherKitCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear:
            return .clear
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .mostlyClear, .partlyCloudy:
            return .partlyCloudy
        case .drizzle:
            return .drizzle
        case .rain, .heavyRain:
            return .rain
        case .snow, .heavySnow, .flurries, .wintryMix:
            return .snow
        case .sleet:
            return .sleet
        case .freezingDrizzle:
            return .freezingDrizzle
        case .strongStorms, .thunderstorms:
            return .strongStorms
        case .windy:
            return .windy
        case .foggy:
            return .foggy
        case .haze:
            return .haze
        case .hot:
            return .hot
        case .blizzard:
            return .blizzard
        case .blowingDust:
            return .blowingDust
        case .tropicalStorm:
            return .tropicalStorm
        case .hurricane:
            return .hurricane
        default:
            return .clear
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
    
    // 修改批量更新完成后的汇总显示方法
    func showBatchUpdateSummary() {
        var output = ""
        
        // 当前城市天气
        if let currentWeather = currentWeather {
            output += "\n当前城市: \(currentCityName ?? "未知")"
            output += String(format: "\n🌡️ %.0f° | %@ | %.0f° - %.0f°",
                           currentWeather.temperature,
                           currentWeather.weatherCondition.description,
                           currentWeather.lowTemperature,
                           currentWeather.highTemperature)
        }
        
        // 收藏城市天气
        if !cityWeatherCache.isEmpty {
            // 找出温度范围
            let temperatures = cityWeatherCache.values.map { $0.temperature }
            if let maxTemp = temperatures.max(),
               let minTemp = temperatures.min() {
                output += String(format: "\n\n收藏城市天气 (温度范围: %.0f° - %.0f°)", maxTemp, minTemp)
            }
            
            output += "\n\n城市          温度      天气       温度范围"
            output += "\n----------------------------------------"
            
            // 按温度从高到低排序
            let sortedCities = cityWeatherCache.sorted { $0.value.temperature > $1.value.temperature }
            
            for (cityName, weather) in sortedCities {
                let temp = String(format: "%.0f°", weather.temperature)
                let condition = weather.weatherCondition.description
                let range = String(format: "%.0f° - %.0f°", weather.lowTemperature, weather.highTemperature)
                
                // 使用UTF-8安全的格式化方式
                let formattedCity = cityName.padding(toLength: 12, withPad: " ", startingAt: 0)
                let formattedTemp = temp.padding(toLength: 8, withPad: " ", startingAt: 0)
                let formattedCondition = condition.padding(toLength: 10, withPad: " ", startingAt: 0)
                
                output += "\n\(formattedCity)\(formattedTemp)\(formattedCondition)\(range)"
            }
        }
        
        print(output)
    }
    
    // 修改格式化城市列表显示的方法
    func formatCityWeatherList() -> String {
        // 获取所有缓存的城市天气数据并按温度排序
        let cities = cityWeatherCache.keys.sorted { city1, city2 in
            guard let weather1 = cityWeatherCache[city1],
                  let weather2 = cityWeatherCache[city2] else {
                return false
            }
            return weather1.temperature > weather2.temperature
        }
        
        var output = ""
        
        // 计算温度范围
        if let maxTemp = cities.compactMap({ cityWeatherCache[$0]?.temperature }).max(),
           let minTemp = cities.compactMap({ cityWeatherCache[$0]?.temperature }).min() {
            output += String(format: "收藏城市天气:温度范围: %.0f° - %.0f°", maxTemp, minTemp)
        }
        
        // 创建表格头部
        output += "\n\n城市          温度      天气       温度范围"
        output += "\n----------------------------------------"
        
        // 填充表格内容
        for city in cities {
            if let weather = cityWeatherCache[city] {
                let cityPadded = city.padding(toLength: 12, withPad: " ", startingAt: 0)
                let tempStr = String(format: "%2d°", Int(round(weather.temperature))).padding(toLength: 10, withPad: " ", startingAt: 0)
                let weatherStr = weather.weatherCondition.description.padding(toLength: 10, withPad: " ", startingAt: 0)
                let rangeStr = String(format: "%2d° - %2d°", 
                                    Int(round(weather.lowTemperature)),
                                    Int(round(weather.highTemperature)))
                
                output += String(format: "\n%@%@%@%@",
                               cityPadded,
                               tempStr,
                               weatherStr,
                               rangeStr)
            }
        }
        
        return output
    }
}
