import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared
    
    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var hourlyForecast: [CurrentWeather] = []
    @Published private(set) var dailyForecast: [DayWeatherInfo] = []
    @Published private(set) var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private init() {}
    
    func updateWeather(for location: CLLocation) async {
        do {
            let weather = try await weatherService.weather(for: location)
            
            // 更新当前天气
            currentWeather = CurrentWeather(
                date: weather.currentWeather.date,
                temperature: weather.currentWeather.temperature.value,
                feelsLike: weather.currentWeather.apparentTemperature.value,
                condition: weather.currentWeather.condition.description,
                symbolName: weather.currentWeather.symbolName,
                windSpeed: weather.currentWeather.wind.speed.value,
                precipitationChance: weather.hourlyForecast.first?.precipitationChance ?? 0,
                uvIndex: Int(weather.currentWeather.uvIndex.value),
                humidity: weather.currentWeather.humidity,
                pressure: weather.currentWeather.pressure.value,
                visibility: weather.currentWeather.visibility.value,
                airQualityIndex: 0,
                timezone: TimeZone.current
            )
            
            // 更新小时预报
            hourlyForecast = weather.hourlyForecast.forecast.prefix(24).map { hour in
                CurrentWeather(
                    date: hour.date,
                    temperature: hour.temperature.value,
                    feelsLike: hour.apparentTemperature.value,
                    condition: hour.condition.description,
                    symbolName: hour.symbolName,
                    windSpeed: hour.wind.speed.value,
                    precipitationChance: hour.precipitationChance,
                    uvIndex: Int(hour.uvIndex.value),
                    humidity: hour.humidity,
                    pressure: hour.pressure.value,
                    visibility: hour.visibility.value,
                    airQualityIndex: 0,
                    timezone: TimeZone.current
                )
            }
            
            // 更新每日预报
            dailyForecast = weather.dailyForecast.forecast.prefix(7).map { day in
                DayWeatherInfo(
                    date: day.date,
                    condition: day.condition.description,
                    symbolName: day.symbolName,
                    lowTemperature: day.lowTemperature.value,
                    highTemperature: day.highTemperature.value
                )
            }
            
            lastUpdateTime = Date()
            errorMessage = nil
            
        } catch {
            errorMessage = "获取天气信息失败：\(error.localizedDescription)"
        }
    }
    
    static func mock() -> WeatherService {
        let service = WeatherService()
        service.currentWeather = .mock(temp: 25, condition: "晴", symbol: "sun.max")
        service.hourlyForecast = [
            .mock(temp: 25, condition: "晴", symbol: "sun.max"),
            .mock(temp: 27, condition: "晴", symbol: "sun.max"),
            .mock(temp: 29, condition: "多云", symbol: "cloud.sun"),
            .mock(temp: 28, condition: "多云", symbol: "cloud.sun"),
            .mock(temp: 26, condition: "晴", symbol: "sun.max"),
        ]
        service.dailyForecast = [
            DayWeatherInfo(date: Date(), condition: "晴", symbolName: "sun.max", lowTemperature: 20, highTemperature: 28),
            DayWeatherInfo(date: Date().addingTimeInterval(86400), condition: "晴", symbolName: "sun.max", lowTemperature: 19, highTemperature: 27),
            DayWeatherInfo(date: Date().addingTimeInterval(86400 * 2), condition: "多云", symbolName: "cloud.sun", lowTemperature: 21, highTemperature: 29),
            DayWeatherInfo(date: Date().addingTimeInterval(86400 * 3), condition: "多云", symbolName: "cloud.sun", lowTemperature: 20, highTemperature: 28),
            DayWeatherInfo(date: Date().addingTimeInterval(86400 * 4), condition: "晴", symbolName: "sun.max", lowTemperature: 18, highTemperature: 26),
        ]
        return service
    }
}
