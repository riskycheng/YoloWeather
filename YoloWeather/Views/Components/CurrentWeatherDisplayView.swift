import SwiftUI

struct CurrentWeatherDisplayView: View {
    let weather: WeatherService.CurrentWeather  // Use WeatherService.CurrentWeather type
    let timeOfDay: WeatherTimeOfDay
    let animationTrigger: UUID?  // Add trigger parameter
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            FlipNumberView(
                value: Int(round(weather.temperature)),
                unit: "°",
                color: WeatherThemeManager.shared.textColor(for: timeOfDay),
                trigger: animationTrigger
            )
            .font(.system(size: 96, weight: .medium, design: .rounded))
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            HStack(spacing: 12) {
                WeatherIconView(symbolName: weather.symbolName)
                    .frame(width: 44, height: 44)
                
                Text(weather.condition)
                    .font(.title3)
            }
            .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

struct WeatherIconView: View {
    let symbolName: String
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.title)
            .symbolRenderingMode(.multicolor)
            .symbolEffect(.bounce, options: .repeating)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    rotation = 10
                    scale = 1.1
                }
            }
    }
}
