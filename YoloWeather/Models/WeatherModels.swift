import Foundation

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
    let pressure: Double
    let visibility: Double
    let airQualityIndex: Int
    let timezone: TimeZone
    
    static func mock(temp: Double, condition: String, symbol: String) -> CurrentWeather {
        CurrentWeather(
            date: Date(),
            temperature: temp,
            feelsLike: temp + 2,
            condition: condition,
            symbolName: symbol,
            windSpeed: 3.4,
            precipitationChance: 0.2,
            uvIndex: 5,
            humidity: 0.65,
            pressure: 1013,
            visibility: 10,
            airQualityIndex: 75,
            timezone: TimeZone.current
        )
    }
}

struct DayWeatherInfo: Equatable {
    let date: Date
    let condition: String
    let symbolName: String
    let lowTemperature: Double
    let highTemperature: Double
    
    static func mock(low: Double, high: Double, condition: String, symbol: String) -> DayWeatherInfo {
        DayWeatherInfo(
            date: Date(),
            condition: condition,
            symbolName: symbol,
            lowTemperature: low,
            highTemperature: high
        )
    }
}
