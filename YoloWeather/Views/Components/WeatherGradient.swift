import SwiftUI

struct WeatherGradient: View {
    let timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var gradientColors: [Color] {
        switch timeOfDay {
        case .day:
            return [
                Color(red: 0.4, green: 0.7, blue: 1.0),  // 浅蓝色
                Color(red: 0.6, green: 0.8, blue: 1.0)   // 更浅的蓝色
            ]
        case .night:
            return [
                Color(red: 0.1, green: 0.1, blue: 0.3),  // 深蓝色
                Color(red: 0.2, green: 0.2, blue: 0.5)   // 稍浅的深蓝色
            ]
        }
    }
} 