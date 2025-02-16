//
//  WeatherWidget.swift
//  YoloWeatherWidget
//
//  Created by Jian Cheng on 2024/02/16.
//

import WidgetKit
import SwiftUI
import CoreLocation
import WeatherKit

// Define WeatherCondition enum here since it needs to be accessible in the widget
enum WeatherCondition: CustomStringConvertible {
    case clear
    case cloudy
    case mostlyClear
    case mostlyCloudy
    case partlyCloudy
    case drizzle
    case rain
    case heavyRain
    case snow
    case heavySnow
    case sleet
    case freezingDrizzle
    case strongStorms
    case windy
    case foggy
    case haze
    case hot
    case blizzard
    case blowingDust
    case tropicalStorm
    case hurricane
    
    var description: String {
        switch self {
        case .clear:
            return "晴"
        case .cloudy:
            return "多云"
        case .mostlyClear:
            return "晴间多云"
        case .mostlyCloudy, .partlyCloudy:
            return "多云转晴"
        case .drizzle:
            return "小雨"
        case .rain:
            return "中雨"
        case .heavyRain:
            return "大雨"
        case .snow:
            return "雪"
        case .heavySnow:
            return "大雪"
        case .sleet:
            return "雨夹雪"
        case .freezingDrizzle:
            return "冻雨"
        case .strongStorms:
            return "暴风雨"
        case .windy:
            return "大风"
        case .foggy:
            return "雾"
        case .haze:
            return "霾"
        case .hot:
            return "炎热"
        case .blizzard:
            return "暴风雪"
        case .blowingDust:
            return "浮尘"
        case .tropicalStorm:
            return "热带风暴"
        case .hurricane:
            return "台风"
        }
    }
}

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationHandler: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() async -> CLLocation? {
        return await withCheckedContinuation { continuation in
            locationHandler = { location in
                continuation.resume(returning: location)
            }
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationHandler?(locations.first)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationHandler?(nil)
    }
}

struct Provider: TimelineProvider {
    let weatherService = WeatherService.shared
    let locationManager = WidgetLocationManager()
    
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), temperature: 25.0, condition: .clear, location: "Loading...")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        Task {
            let entry = await makeEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        Task {
            let currentDate = Date()
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
            
            let entry = await makeEntry()
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    private func makeEntry() async -> WeatherEntry {
        if let location = await locationManager.requestLocation() {
            await weatherService.updateWeather(for: location)
            if let weather = await weatherService.currentWeather {
                return WeatherEntry(
                    date: Date(),
                    temperature: weather.temperature,
                    condition: weather.weatherCondition,
                    location: await weatherService.currentCityName ?? "Unknown"
                )
            }
        }
        return WeatherEntry(date: Date(), temperature: 0.0, condition: .clear, location: "Unavailable")
    }
}

struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Double
    let condition: WeatherCondition
    let location: String
}

struct WeatherWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.location)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Text(formatDate(entry.date))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .center) {
                Image(systemName: getWeatherSymbolName(condition: entry.condition, isNight: isNight(date: entry.date)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                Text("\(Int(round(entry.temperature)))°")
                    .font(.system(size: 36, weight: .bold))
            }
            
            if family != .systemSmall {
                Text(entry.condition.description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func isNight(date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 18 || hour < 6
    }
    
    private func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear:
            return isNight ? "moon.stars.fill" : "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .mostlyClear, .partlyCloudy, .mostlyCloudy:
            return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .rain, .heavyRain:
            return "cloud.rain.fill"
        case .snow, .heavySnow:
            return "cloud.snow.fill"
        case .sleet, .freezingDrizzle:
            return "cloud.sleet.fill"
        case .strongStorms:
            return "cloud.bolt.rain.fill"
        case .windy:
            return "wind"
        case .foggy:
            return "cloud.fog.fill"
        case .haze, .blowingDust:
            return "sun.haze.fill"
        case .hot:
            return "sun.max.fill"
        case .blizzard:
            return "wind.snow"
        case .tropicalStorm, .hurricane:
            return "hurricane"
        }
    }
}

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather Widget")
        .description("Shows current weather information")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
