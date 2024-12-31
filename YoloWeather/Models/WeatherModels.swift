import Foundation

struct WeatherInfo: Equatable {
    let date: Date
    let temperature: Double
    let condition: String
    let symbolName: String
    let timezone: TimeZone
    
    static func mock(temp: Double, condition: String, symbol: String) -> WeatherInfo {
        WeatherInfo(
            date: Date(),
            temperature: temp,
            condition: condition,
            symbolName: symbol,
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
