import SwiftUI

struct TimeBasedGradient: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let colors = getGradientColors()
        LinearGradient(gradient: Gradient(colors: colors),
                      startPoint: .top,
                      endPoint: .bottom)
            .ignoresSafeArea()
    }
    
    private func getGradientColors() -> [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<7: // 日出
            return [Color(hex: "#FF512F"), Color(hex: "#F09819")]
        case 7..<11: // 早晨
            return [Color(hex: "#2193b0"), Color(hex: "#6dd5ed")]
        case 11..<16: // 中午
            return [Color(hex: "#00B4DB"), Color(hex: "#0083B0")]
        case 16..<19: // 傍晚
            return [Color(hex: "#FF512F"), Color(hex: "#DD2476")]
        case 19..<22: // 晚上
            return [Color(hex: "#141E30"), Color(hex: "#243B55")]
        default: // 深夜
            return [Color(hex: "#0F2027"), Color(hex: "#203A43")]
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    TimeBasedGradient()
} 