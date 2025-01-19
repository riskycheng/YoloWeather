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
                ForEach(WeatherBubbleSettings.BubbleType.allCases, id: \.rawValue) { type in
                    WeatherIndicatorToggle(
                        title: type.rawValue,
                        isEnabled: settings.isEnabled(type)
                    ) {
                        settings.toggleBubble(type)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.white.opacity(0.08))
    }
}

struct WeatherIndicatorToggle: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(isEnabled ? Color.green : Color.white.opacity(0.15))
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
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
        }
    }
} 