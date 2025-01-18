import Foundation

public enum WeatherTimeOfDay: String {
    case day
    case night
    
    public var isDaytime: Bool {
        self == .day
    }
} 