import SwiftUI

struct TimeBasedBackground: View {
    var body: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let colors: [Color] = {
            switch hour {
            case 5..<8:   // Dawn
                return [Color(red: 0.3, green: 0.4, blue: 0.6),
                        Color(red: 0.6, green: 0.4, blue: 0.3)]
            case 8..<17:  // Day
                return [Color(red: 0.4, green: 0.6, blue: 0.9),
                        Color(red: 0.3, green: 0.5, blue: 0.8)]
            case 17..<20: // Dusk
                return [Color(red: 0.6, green: 0.4, blue: 0.5),
                        Color(red: 0.4, green: 0.3, blue: 0.6)]
            default:     // Night
                return [Color(red: 0.2, green: 0.3, blue: 0.4),
                        Color(red: 0.1, green: 0.2, blue: 0.3)]
            }
        }()
        
        LinearGradient(colors: colors,
                      startPoint: .top,
                      endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct TemperatureBar: View {
    let low: Double
    let high: Double
    
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [.blue.opacity(0.7), .orange.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing))
    }
}
