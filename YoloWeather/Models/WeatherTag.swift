import Foundation

enum WeatherTag: String, CaseIterable, Identifiable {
    case temperature
    case feelsLike
    case windSpeed
    case rainProbability
    case uvIndex
    case humidity
    case pressure
    case visibility
    case airQuality
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .temperature: return "温度"
        case .feelsLike: return "体感温度"
        case .windSpeed: return "风速"
        case .rainProbability: return "降水概率"
        case .uvIndex: return "紫外线"
        case .humidity: return "湿度"
        case .pressure: return "气压"
        case .visibility: return "能见度"
        case .airQuality: return "空气质量"
        }
    }
    
    var iconName: String {
        switch self {
        case .temperature: return "thermometer"
        case .feelsLike: return "thermometer.sun"
        case .windSpeed: return "wind"
        case .rainProbability: return "cloud.rain"
        case .uvIndex: return "sun.max"
        case .humidity: return "humidity"
        case .pressure: return "gauge"
        case .visibility: return "eye"
        case .airQuality: return "aqi.medium"
        }
    }
    
    var unit: String {
        switch self {
        case .temperature, .feelsLike: return "°"
        case .windSpeed: return "m/s"
        case .rainProbability, .humidity: return "%"
        case .uvIndex: return ""
        case .pressure: return "hPa"
        case .visibility: return "km"
        case .airQuality: return ""
        }
    }
}
