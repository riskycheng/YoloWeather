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
    
    // 更新指定城市的天气数据
    func updateWeather(for location: CLLocation, cityName: String? = nil) async {
        print("WeatherService - 开始获取天气数据")
        
        // 如果提供了城市名称，使用预设的城市坐标
        let weatherLocation: CLLocation
        if let cityName = cityName, let cityLocation = cityCoordinates[cityName] {
            weatherLocation = cityLocation
            print("WeatherService - 使用预设城市坐标: \(cityName) (\(weatherLocation.coordinate.latitude), \(weatherLocation.coordinate.longitude))")
        } else {
            weatherLocation = location
            print("WeatherService - 使用提供的坐标: \(location.coordinate.latitude), \(location.coordinate.longitude)")
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
                print("WeatherService - 使用提供的城市名称: \(resolvedCityName)")
            } else {
                if let geocodedCity = await reverseGeocode(location: weatherLocation) {
                    resolvedCityName = geocodedCity
                    print("WeatherService - 通过地理编码获取到城市名称: \(resolvedCityName)")
                } else {
                    throw WeatherError.cityNameResolutionFailed
                }
            }
            
            // 更新当前选中的城市名称
            self.currentCityName = resolvedCityName
            print("WeatherService - 已更新当前选中城市为: \(resolvedCityName)")
            
            // 获取时区
            let timezone = await calculateTimezone(for: weatherLocation, cityName: resolvedCityName)
            print("WeatherService - 使用时区: \(timezone.identifier)")
            
            // 获取天气数据
            let weather = try await weatherService.weather(for: weatherLocation)
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
            let currentWeatherData = CurrentWeather(
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
            
            // 更新每日预报
            var dailyForecasts: [DayWeatherInfo] = []
            for day in weather.dailyForecast.forecast.prefix(7) {
                let daySymbolName = getWeatherSymbolName(condition: day.condition, isNight: false)
                
                let forecast = DayWeatherInfo(
                    date: day.date,
                    condition: getWeatherConditionText(day.condition),
                    symbolName: daySymbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value,
                    precipitationProbability: day.precipitationChance
                )
                dailyForecasts.append(forecast)
            }
            
            // 更新数据
            if let cityName = cityName {
                // 更新缓存
                cityWeatherCache[cityName] = currentWeatherData
                print("WeatherService - 已更新城市天气缓存: \(cityName)")
                
                // 直接更新显示数据，因为这是用户选择的城市
                print("WeatherService - 更新显示数据为城市: \(cityName)")
                self.currentWeather = currentWeatherData
                self.hourlyForecast = forecasts
                self.dailyForecast = dailyForecasts
            } else {
                // 如果没有城市名称，直接更新所有数据
                print("WeatherService - 无城市名称，更新所有数据")
                self.currentWeather = currentWeatherData
                self.hourlyForecast = forecasts
                self.dailyForecast = dailyForecasts
            }
            
            lastUpdateTime = Date()
            errorMessage = nil
            
            print("WeatherService - 天气数据更新完成")
            
        } catch {
            print("WeatherService - 更新天气数据失败: \(error.localizedDescription)")
            handleError(error)
            
            // 如果缓存中有数据，使用缓存数据
            if let cityName = self.currentCityName,
               let cachedWeather = cityWeatherCache[cityName] {
                self.currentWeather = cachedWeather
                print("WeatherService - 使用缓存数据: \(cityName)")
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
        print("正在计算位置 (\(location.coordinate.latitude), \(location.coordinate.longitude)) 的时区")
        
        // 如果有城市名称，优先使用城市名称判断时区
        if let cityName = cityName {
            print("使用城市名称判断时区: \(cityName)")
            
            // 中国城市的特殊处理
            if cityName == "香港" {
                print("检测到香港，使用Asia/Hong_Kong时区")
                return TimeZone(identifier: "Asia/Hong_Kong")!
            } else if cityName == "澳门" {
                print("检测到澳门，使用Asia/Macau时区")
                return TimeZone(identifier: "Asia/Macau")!
            } else if cityName.hasSuffix("市") || cityName.hasSuffix("省") || cityName == "台北" {
                print("检测到中国大陆/台湾城市，使用Asia/Shanghai时区")
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
                print("找到匹配的已知城市: \(cityName), 使用时区: \(knownCity.timezone)")
                return TimeZone(identifier: knownCity.timezone)!
            }
        }
        
        // 中国大陆经纬度范围判断
        if location.coordinate.longitude >= 73 && location.coordinate.longitude <= 135 &&
           location.coordinate.latitude >= 18 && location.coordinate.latitude <= 54 {
            // 香港特别行政区的经纬度范围
            if location.coordinate.longitude >= 113.8 && location.coordinate.longitude <= 114.4 &&
               location.coordinate.latitude >= 22.1 && location.coordinate.latitude <= 22.6 {
                print("根据经纬度判断为香港地区，使用Asia/Hong_Kong时区")
                return TimeZone(identifier: "Asia/Hong_Kong")!
            }
            // 澳门特别行政区的经纬度范围
            else if location.coordinate.longitude >= 113.5 && location.coordinate.longitude <= 113.6 &&
                    location.coordinate.latitude >= 22.1 && location.coordinate.latitude <= 22.2 {
                print("根据经纬度判断为澳门地区，使用Asia/Macau时区")
                return TimeZone(identifier: "Asia/Macau")!
            }
            else {
                print("根据经纬度判断为中国大陆地区，使用Asia/Shanghai时区")
                return TimeZone(identifier: "Asia/Shanghai")!
            }
        }
        
        // 其他情况使用地理编码
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
            let defaultTZ = getDefaultTimezone(for: location)
            print("使用经纬度计算的时区: \(defaultTZ.identifier)")
            return defaultTZ
        }
    }
    
    // 获取天气图标名称
    internal func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        print("天气图标计算 - 天气状况: \(condition)")
        print("天气图标计算 - 是否夜晚: \(isNight)")
        
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
        
        print("天气图标计算 - 选择的图标: \(symbolName)")
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
                print("反向地理编码结果 - 国家: \(placemark.country ?? "未知"), 行政区: \(placemark.administrativeArea ?? "未知"), 城市: \(placemark.locality ?? "未知")")
                
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
            print("反向地理编码未能解析出城市名称")
            return nil
        } catch {
            print("反向地理编码失败: \(error.localizedDescription)")
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
}
