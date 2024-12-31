import SwiftUI

struct TimeBasedBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDaytime: Bool {
        let timezone = TimeZone.current
        let currentDate = Date()
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let hour = calendar.component(.hour, from: currentDate)
        return hour >= 6 && hour < 18
    }
    
    private var backgroundColor: Color {
        if isDaytime {
            return colorScheme == .light ?
                Color(red: 0.99, green: 0.99, blue: 0.99) :  // 日间亮色模式，更亮的白色
                Color(red: 0.15, green: 0.15, blue: 0.17)    // 日间暗色模式
        } else {
            return Color(red: 0.08, green: 0.08, blue: 0.12) // 夜间模式统一深色
        }
    }
    
    private var gradientColors: [Color] {
        if isDaytime {
            return colorScheme == .light ?
                [.white.opacity(0.2), .black.opacity(0.03)] :  // 日间亮色模式渐变，更柔和
                [.white.opacity(0.05), .black.opacity(0.2)]    // 日间暗色模式渐变
        } else {
            return [.white.opacity(0.05), .black.opacity(0.2)] // 夜间模式渐变
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
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
