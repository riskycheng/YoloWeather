import Foundation
import WeatherKit

enum WeatherTag: String, CaseIterable, Identifiable, Codable {
    case temperature
    case feelsLike
    case windSpeed
    case humidity
    case uvIndex
    case pressure
    case visibility
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .temperature: return "温度"
        case .feelsLike: return "体感温度"
        case .windSpeed: return "风速"
        case .humidity: return "湿度"
        case .uvIndex: return "紫外线"
        case .pressure: return "气压"
        case .visibility: return "能见度"
        }
    }
    
    var iconName: String {
        switch self {
        case .temperature: return "thermometer"
        case .feelsLike: return "thermometer.sun"
        case .windSpeed: return "wind"
        case .humidity: return "humidity"
        case .uvIndex: return "sun.max"
        case .pressure: return "gauge"
        case .visibility: return "eye"
        }
    }
    
    var unit: String {
        switch self {
        case .temperature, .feelsLike: return "°C"
        case .windSpeed: return "km/h"
        case .humidity: return "%"
        case .uvIndex: return ""
        case .pressure: return "hPa"
        case .visibility: return "km"
        }
    }
    
    func getValue(from weather: CurrentWeather) -> String {
        switch self {
        case .temperature:
            return "\(Int(round(weather.temperature)))"
        case .feelsLike:
            return "\(Int(round(weather.feelsLike)))"
        case .windSpeed:
            return "\(Int(round(weather.windSpeed)))"
        case .humidity:
            return "\(Int(round(weather.humidity * 100)))"
        case .uvIndex:
            return "\(weather.uvIndex)"
        case .pressure:
            return "\(Int(round(weather.pressure)))"
        case .visibility:
            return String(format: "%.1f", weather.visibility)
        }
    }
}
