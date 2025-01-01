import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    static let shared = WeatherService()
    private let weatherService = WeatherKit.WeatherService.shared
    private let locationManager = LocationManager()
    
    @Published private(set) var currentWeather: CurrentWeather?
    @Published private(set) var hourlyForecast: [CurrentWeather] = []
    @Published private(set) var dailyForecast: [DayWeatherInfo] = []
    @Published private(set) var lastUpdateTime: Date?
    @Published var errorMessage: String?
    
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 300 // 5 minutes
    
    init() {
        setupUpdateTimer()
    }
    
    private func setupUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateWeather()
            }
        }
    }
    
    func updateWeather() async {
        do {
            guard let location = locationManager.location else {
                errorMessage = "无法获取位置信息"
                return
            }
            
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
            .mock(temp: 28, condition: "多云", symbol: "cloud"),
            .mock(temp: 26, condition: "多云", symbol: "cloud"),
            .mock(temp: 24, condition: "阴", symbol: "cloud.fill")
        ]
        service.dailyForecast = [
            .mock(low: 20, high: 28, condition: "晴", symbol: "sun.max"),
            .mock(low: 21, high: 29, condition: "多云", symbol: "cloud"),
            .mock(low: 19, high: 27, condition: "阴", symbol: "cloud.fill"),
            .mock(low: 18, high: 25, condition: "小雨", symbol: "cloud.rain"),
            .mock(low: 17, high: 24, condition: "中雨", symbol: "cloud.heavyrain"),
            .mock(low: 19, high: 26, condition: "多云", symbol: "cloud"),
            .mock(low: 20, high: 28, condition: "晴", symbol: "sun.max")
        ]
        service.lastUpdateTime = Date()
        return service
    }
}
