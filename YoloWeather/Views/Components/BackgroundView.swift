import SwiftUI

struct TimeBasedBackground: View {
    var body: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let backgroundColor: Color = {
            switch hour {
            case 5..<8:   // Dawn
                return Color(red: 0.98, green: 0.95, blue: 0.92)
            case 8..<17:  // Day
                return .white
            case 17..<20: // Dusk
                return Color(red: 0.98, green: 0.95, blue: 0.92)
            default:     // Night
                return Color(red: 0.12, green: 0.12, blue: 0.18)
            }
        }()
        
        backgroundColor
            .ignoresSafeArea()
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
