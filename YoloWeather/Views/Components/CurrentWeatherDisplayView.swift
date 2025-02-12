import SwiftUI

struct CurrentWeatherDisplayView: View {
    let weather: WeatherService.CurrentWeather
    let timeOfDay: WeatherTimeOfDay
    let animationTrigger: UUID?
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // Main temperature
            FlipNumberView(
                value: Int(round(weather.temperature)),
                unit: "°",
                color: WeatherThemeManager.shared.textColor(for: timeOfDay),
                trigger: animationTrigger
            )
            .font(.system(size: 96, weight: .medium, design: .rounded))
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // High/Low temperature indicators
            VStack(alignment: .leading, spacing: 8) {
                // High temperature
                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 10))
                    Text("\(Int(round(weather.highTemperature)))°")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
                
                // Low temperature
                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                    Text("\(Int(round(weather.lowTemperature)))°")
                        .font(.system(size: 15))
                }
                .foregroundColor(.white)
            }
            .offset(y: -20)
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
