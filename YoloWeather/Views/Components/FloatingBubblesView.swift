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
                initialPosition: CGPoint(x: geometry.size.width * 0.72, y: geometry.size.height * 0.42),
                timeOfDay: timeOfDay
            )
            
        case .windSpeed:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "风速",
                    value: String(format: "%.1f", weatherService.currentWeather?.windSpeed ?? 0),
                    unit: "km/h"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.22, y: geometry.size.height * 0.32),
                timeOfDay: timeOfDay
            )
            
        case .precipitation:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "降水概率",
                    value: String(format: "%.0f", (weatherService.currentWeather?.precipitationChance ?? 0) * 100),
                    unit: "%"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.32, y: geometry.size.height * 0.52),
                timeOfDay: timeOfDay
            )
            
        case .uvIndex:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "紫外线",
                    value: "\(weatherService.currentWeather?.uvIndex ?? 0)",
                    unit: ""
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.62, y: geometry.size.height * 0.22),
                timeOfDay: timeOfDay
            )
            
        case .pressure:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "气压",
                    value: String(format: "%.0f", weatherService.currentWeather?.pressure ?? 0),
                    unit: "hPa"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.42, y: geometry.size.height * 0.62),
                timeOfDay: timeOfDay
            )
            
        case .visibility:
            GlassBubbleView(
                info: WeatherInfo(
                    title: "能见度",
                    value: String(format: "%.1f", (weatherService.currentWeather?.visibility ?? 0) / 1000),
                    unit: "km"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.82, y: geometry.size.height * 0.32),
                timeOfDay: timeOfDay
            )
        }
    }
} 