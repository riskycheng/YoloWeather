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
            
            // Convert WeatherKit data to our models
            self.currentWeather = WeatherInfo(
                date: weather.currentWeather.date,
                temperature: weather.currentWeather.temperature.value,
                condition: weather.currentWeather.condition.description,
                symbolName: weather.currentWeather.symbolName
            )
            
            self.hourlyForecast = weather.hourlyForecast.prefix(24).map { hour in
                WeatherInfo(
                    date: hour.date,
                    temperature: hour.temperature.value,
                    condition: hour.condition.description,
                    symbolName: hour.symbolName
                )
            }
            
            self.dailyForecast = weather.dailyForecast.prefix(7).map { day in
                DayWeatherInfo(
                    date: day.date,
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
