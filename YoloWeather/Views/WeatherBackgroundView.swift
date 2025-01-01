import SwiftUI

struct WeatherBackgroundView: View {
    let timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: colors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 半透明遮罩
            Color.black.opacity(0.2)
                .ignoresSafeArea()
        }
    }
    
    private var colors: [Color] {
        switch timeOfDay {
        case .day:
            return [
                Color(red: 0.4, green: 0.7, blue: 0.9),
                Color(red: 0.6, green: 0.8, blue: 0.95)
            ]
        case .night:
            return [
                Color(red: 0.1, green: 0.15, blue: 0.3),
                Color(red: 0.15, green: 0.2, blue: 0.35)
            ]
        }
    }
}

struct WeatherBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherBackgroundView(timeOfDay: .day)
                .previewDisplayName("Day")
            
            WeatherBackgroundView(timeOfDay: .night)
                .previewDisplayName("Night")
        }
    }
}
