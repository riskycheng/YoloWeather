import SwiftUI

struct WeatherBubbleSettingsView: View {
    @StateObject private var settings = WeatherBubbleSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("显示指标")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                WeatherIndicatorToggle(title: "湿度", isEnabled: true)
                WeatherIndicatorToggle(title: "风速", isEnabled: true)
                WeatherIndicatorToggle(title: "降水概率", isEnabled: false)
                WeatherIndicatorToggle(title: "紫外线", isEnabled: false)
                WeatherIndicatorToggle(title: "气压", isEnabled: true)
                WeatherIndicatorToggle(title: "能见度", isEnabled: false)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.2))
    }
}

struct WeatherIndicatorToggle: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
            Circle()
                .fill(isEnabled ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 16, height: 16)
                .overlay {
                    if isEnabled {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
} 