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
            
            // 设置时区转换所需的日历
            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            
            var shanghaiCalendar = Calendar(identifier: .gregorian)
            shanghaiCalendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
            
            // 获取当前上海时间
            let currentDate = Date()
            let today = shanghaiCalendar.startOfDay(for: currentDate)
            
            // Convert WeatherKit data to our models with timezone conversion
            self.currentWeather = WeatherInfo(
                date: currentDate,
                temperature: weather.currentWeather.temperature.value,
                condition: weather.currentWeather.condition.description,
                symbolName: weather.currentWeather.symbolName
            )
            
            // 处理未来48小时的预报数据，确保时区转换
            self.hourlyForecast = weather.hourlyForecast.prefix(48).map { hour in
                // 将UTC时间转换为上海时间
                let shanghaiDate = hour.date.addingTimeInterval(8 * 3600) // UTC+8
                
                // 打印时间转换信息
                logger.info("Time conversion - UTC: \(hour.date) (\(utcCalendar.component(.hour, from: hour.date)):00), Shanghai: \(shanghaiDate) (\(shanghaiCalendar.component(.hour, from: shanghaiDate)):00), Temp: \(hour.temperature.value)°")
                
                return WeatherInfo(
                    date: shanghaiDate,
                    temperature: hour.temperature.value,
                    condition: hour.condition.description,
                    symbolName: hour.symbolName
                )
            }.sorted { $0.date < $1.date }
            
            // 打印处理后的数据
            for forecast in self.hourlyForecast {
                let hour = shanghaiCalendar.component(.hour, from: forecast.date)
                let isNextDay = !shanghaiCalendar.isDate(forecast.date, inSameDayAs: today)
                logger.info("Processed forecast - \(isNextDay ? "Tomorrow" : "Today") \(hour):00 - \(forecast.temperature)°")
            }
            
            self.dailyForecast = weather.dailyForecast.prefix(7).map { day in
                // 转换日期到上海时间
                let shanghaiDate = day.date.addingTimeInterval(8 * 3600)
                
                return DayWeatherInfo(
                    date: shanghaiDate,
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
