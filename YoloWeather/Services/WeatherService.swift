import Foundation
import WeatherKit
import CoreLocation
import os.log

@MainActor
class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherInfo?
    @Published var hourlyForecast: [WeatherInfo] = []
    @Published var dailyForecast: [DayWeatherInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let weatherService = WeatherKit.WeatherService()
    private let logger = Logger(subsystem: "com.yoloweather.app", category: "WeatherService")
    private let geocoder = CLGeocoder()
    
    init() {
        logger.info("Initializing WeatherService")
    }
    
    private func getLocationInfo(for location: CLLocation) async throws -> (timezone: TimeZone, placemark: CLPlacemark?) {
        logger.info("Getting location info for: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // 首先根据经度计算时区，作为后备方案
        let hourOffset = Int(round(location.coordinate.longitude / 15.0))
        let secondsFromGMT = hourOffset * 3600
        var fallbackTimeZone = TimeZone.current
        if let calculatedTimeZone = TimeZone(secondsFromGMT: secondsFromGMT) {
            fallbackTimeZone = calculatedTimeZone
        }
        logger.info("Calculated fallback timezone: \(fallbackTimeZone.identifier) for location")
        
        // 尝试使用地理编码获取更准确的时区
        var attempts = 0
        let maxAttempts = 3
        var lastError: Error? = nil
        
        while attempts < maxAttempts {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    // 获取时区
                    var timezone = fallbackTimeZone
                    if let placemarkTimeZone = placemark.timeZone {
                        timezone = placemarkTimeZone
                        logger.info("Using placemark timezone: \(timezone.identifier)")
                    } else {
                        logger.info("Using fallback timezone: \(timezone.identifier)")
                    }
                    
                    // 记录更详细的位置信息
                    logger.info("""
                        Location details:
                        Name: \(placemark.name ?? "Unknown")
                        Locality: \(placemark.locality ?? "Unknown")
                        SubLocality: \(placemark.subLocality ?? "Unknown")
                        Administrative Area: \(placemark.administrativeArea ?? "Unknown")
                        Country: \(placemark.country ?? "Unknown")
                        Timezone: \(timezone.identifier)
                        Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)
                        """)
                    
                    return (timezone, placemark)
                }
                
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000))
                    logger.info("Retrying geocoding attempt \(attempts + 1) of \(maxAttempts)")
                }
            } catch {
                lastError = error
                logger.error("Geocoding error on attempt \(attempts + 1): \(error.localizedDescription)")
                attempts += 1
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(1_000_000_000))
                    logger.info("Retrying geocoding attempt \(attempts + 1) of \(maxAttempts)")
                }
            }
        }
        
        // 如果地理编码失败，使用后备时区并继续
        logger.warning("Geocoding failed, proceeding with fallback timezone: \(fallbackTimeZone.identifier)")
        return (fallbackTimeZone, nil)
    }
    
    func requestWeatherData(for location: CLLocation) async {
        logger.info("Requesting weather data for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. 获取位置信息和时区
            let (timezone, placemark) = try await getLocationInfo(for: location)
            
            // 2. 获取天气数据
            logger.info("Starting weather request...")
            let weather = try await weatherService.weather(for: location)
            logger.info("Weather request successful")
            
            // 设置时区转换所需的日历
            var localCalendar = Calendar(identifier: .gregorian)
            localCalendar.timeZone = timezone
            
            // 获取当前本地时间
            let currentDate = Date()
            let today = localCalendar.startOfDay(for: currentDate)
            
            // 记录时区和时间信息
            logger.info("""
                Time information:
                Timezone: \(timezone.identifier)
                Local time: \(localCalendar.date(from: localCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)) ?? currentDate)
                UTC offset: \(timezone.secondsFromGMT()/3600) hours
                """)
            
            // 3. 处理当前天气
            let currentTemp = weather.currentWeather.temperature.value
            logger.info("Current weather - Temperature: \(currentTemp)°, Condition: \(weather.currentWeather.condition.description)")
            
            self.currentWeather = WeatherInfo(
                date: currentDate,
                temperature: currentTemp,
                condition: weather.currentWeather.condition.description,
                symbolName: weather.currentWeather.symbolName,
                timezone: timezone
            )
            
            // 4. 处理小时预报
            logger.info("Processing hourly forecast...")
            self.hourlyForecast = weather.hourlyForecast.prefix(48).map { hour in
                let localDate = hour.date
                let hourNum = localCalendar.component(.hour, from: localDate)
                let isNextDay = !localCalendar.isDate(localDate, inSameDayAs: today)
                let temp = hour.temperature.value
                
                logger.info("Hour forecast - \(isNextDay ? "Tomorrow" : "Today") \(String(format: "%02d", hourNum)):00 - \(String(format: "%.1f", temp))° (\(hour.date))")
                
                return WeatherInfo(
                    date: localDate,
                    temperature: temp,
                    condition: hour.condition.description,
                    symbolName: hour.symbolName,
                    timezone: timezone
                )
            }.sorted { $0.date < $1.date }
            
            // 5. 处理每日预报
            logger.info("Processing daily forecast...")
            self.dailyForecast = weather.dailyForecast.prefix(7).map { day in
                let localDate = day.date
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                dateFormatter.timeZone = timezone
                
                logger.info("Day forecast - \(dateFormatter.string(from: localDate)): Low: \(String(format: "%.1f", day.lowTemperature.value))°, High: \(String(format: "%.1f", day.highTemperature.value))°")
                
                return DayWeatherInfo(
                    date: localDate,
                    condition: day.condition.description,
                    symbolName: day.symbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value
                )
            }
            
            logger.info("Weather data processing completed successfully")
            logger.info("Summary - Current: \(String(format: "%.1f", currentTemp))°, Hours: \(self.hourlyForecast.count), Days: \(self.dailyForecast.count)")
            
        } catch let error as CLError {
            logger.error("Location error: \(error.localizedDescription)")
            switch error.code {
            case .geocodeFoundNoResult:
                self.errorMessage = "无法找到该位置信息"
            case .geocodeFoundPartialResult:
                self.errorMessage = "位置信息不完整"
            case .network:
                self.errorMessage = "网络连接错误，请检查网络设置"
            default:
                self.errorMessage = "获取位置信息失败：\(error.localizedDescription)"
            }
        } catch {
            logger.error("Error type: \(type(of: error))")
            logger.error("Error description: \(error.localizedDescription)")
            
            if let weatherError = error as? WeatherError {
                logger.error("WeatherKit error: \(weatherError)")
                self.errorMessage = "获取天气数据失败：\(weatherError.localizedDescription)"
            } else {
                logger.error("Unknown error: \(error)")
                self.errorMessage = "获取天气数据失败，请稍后重试"
            }
        }
        
        isLoading = false
    }
}
