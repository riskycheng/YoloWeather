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
    
    init() {
        logger.info("Initializing WeatherService")
    }
    
    func requestWeatherData(for location: CLLocation) async {
        logger.info("Requesting weather data for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        isLoading = true
        errorMessage = nil
        
        do {
            logger.info("Starting weather request...")
            let weather = try await weatherService.weather(for: location)
            logger.info("Weather request successful")
            
            // 获取位置对应的时区
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let timezone = placemarks.first?.timeZone else {
                throw NSError(domain: "WeatherService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get timezone for location"])
            }
            
            logger.info("Location timezone: \(timezone.identifier)")
            
            // 设置时区转换所需的日历
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            var localCalendar = Calendar(identifier: .gregorian)
            localCalendar.timeZone = timezone
            
            // 获取当前本地时间
            let currentDate = Date()
            let today = localCalendar.startOfDay(for: currentDate)
            
            // Convert WeatherKit data to our models with timezone conversion
            self.currentWeather = WeatherInfo(
                date: currentDate,
                temperature: weather.currentWeather.temperature.value,
                condition: weather.currentWeather.condition.description,
                symbolName: weather.currentWeather.symbolName
            )
            
            // 处理未来48小时的预报数据，确保时区转换
            self.hourlyForecast = weather.hourlyForecast.prefix(48).map { hour in
                // 将UTC时间转换为本地时间
                let utcDate = hour.date
                let localDate = utcDate.addingTimeInterval(TimeInterval(timezone.secondsFromGMT()))
                
                // 打印时间转换信息
                logger.info("Time conversion - UTC: \(utcDate) (\(utcCalendar.component(.hour, from: utcDate)):00), Local(\(timezone.identifier)): \(localDate) (\(localCalendar.component(.hour, from: localDate)):00), Temp: \(hour.temperature.value)°")
                
                return WeatherInfo(
                    date: localDate,
                    temperature: hour.temperature.value,
                    condition: hour.condition.description,
                    symbolName: hour.symbolName
                )
            }.sorted { $0.date < $1.date }
            
            // 打印处理后的数据
            for forecast in self.hourlyForecast {
                let hour = localCalendar.component(.hour, from: forecast.date)
                let isNextDay = !localCalendar.isDate(forecast.date, inSameDayAs: today)
                logger.info("Processed forecast - \(isNextDay ? "Tomorrow" : "Today") \(hour):00 - \(forecast.temperature)°")
            }
            
            self.dailyForecast = weather.dailyForecast.prefix(7).map { day in
                // 转换日期到本地时间
                let localDate = day.date.addingTimeInterval(TimeInterval(timezone.secondsFromGMT()))
                
                return DayWeatherInfo(
                    date: localDate,
                    condition: day.condition.description,
                    symbolName: day.symbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value
                )
            }
            
            logger.info("Current temperature: \(self.currentWeather?.temperature ?? 0)°")
            logger.info("Retrieved \(self.hourlyForecast.count) hourly forecasts")
            logger.info("Retrieved \(self.dailyForecast.count) daily forecasts")
            
        } catch {
            logger.error("Weather error: \(error.localizedDescription)")
            self.errorMessage = "获取天气数据失败: \(error.localizedDescription)"
        }
        
        isLoading = false
        logger.info("Weather request completed. Success: \(self.errorMessage == nil)")
    }
}
