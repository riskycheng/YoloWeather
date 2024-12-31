import SwiftUI

struct TimeBasedBackground: View {
    private var isDaytime: Bool {
        let timezone = TimeZone.current
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let hour = calendar.component(.hour, from: currentDate)
        return hour >= 6 && hour < 18
    }
    
    private var backgroundColor: Color {
        isDaytime ?
            Color(red: 0.98, green: 0.95, blue: 0.92) :  // 白天的浅色背景
            Color(red: 0.08, green: 0.08, blue: 0.12)    // 夜间的深色背景
    }
    
    private var gradientColors: [Color] {
        isDaytime ?
            [.white.opacity(0.1), .black.opacity(0.05)] :
            [.white.opacity(0.05), .black.opacity(0.2)]
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // 添加微妙的渐变效果
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct TemperatureBar: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.secondary.opacity(0.15))
                .frame(height: 4)
                .clipShape(Capsule())
                .overlay(
                    Rectangle()
                        .fill(.secondary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .clipShape(Capsule()),
                    alignment: .leading
                )
        }
    }
}
