import SwiftUI

struct FloatingBubblesView: View {
    let weatherService: WeatherService
    let timeOfDay: WeatherTimeOfDay
    let geometry: GeometryProxy
    @StateObject private var settings = WeatherBubbleSettings.shared
    
    var body: some View {
        ZStack {
            // 只显示启用的气泡
            ForEach(Array(settings.enabledBubbles), id: \.rawValue) { type in
                bubbleView(for: type)
            }
        }
    }
    
    @ViewBuilder
    private func bubbleView(for type: WeatherBubbleSettings.BubbleType) -> some View {
        switch type {
        case .humidity:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "湿度",
                    value: String(format: "%.0f", (weatherService.currentWeather?.humidity ?? 0) * 100),
                    unit: "%"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.85, y: geometry.size.height * 0.45),
                timeOfDay: timeOfDay
            )
            
        case .windSpeed:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "风速",
                    value: String(format: "%.1f", weatherService.currentWeather?.windSpeed ?? 0),
                    unit: "km/h"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.35),
                timeOfDay: timeOfDay
            )
            
        case .precipitation:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "降水概率",
                    value: String(format: "%.0f", (weatherService.currentWeather?.precipitationChance ?? 0) * 100),
                    unit: "%"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.55),
                timeOfDay: timeOfDay
            )
            
        case .uvIndex:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "紫外线",
                    value: "\(weatherService.currentWeather?.uvIndex ?? 0)",
                    unit: ""
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2),
                timeOfDay: timeOfDay
            )
            
        case .pressure:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "气压",
                    value: String(format: "%.0f", weatherService.currentWeather?.pressure ?? 0),
                    unit: "hPa"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.35, y: geometry.size.height * 0.45),
                timeOfDay: timeOfDay
            )
            
        case .visibility:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "能见度",
                    value: String(format: "%.1f", (weatherService.currentWeather?.visibility ?? 0) / 1000),
                    unit: "km"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.25),
                timeOfDay: timeOfDay
            )
        }
    }
} 