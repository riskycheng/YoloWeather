import SwiftUI

struct WeatherIndicatorSettingsView: View {
    @ObservedObject private var settings = WeatherIndicatorSettings.shared
    
    private struct IndicatorItem: Identifiable {
        let id = UUID()
        let title: String
        let keyPath: ReferenceWritableKeyPath<WeatherIndicatorSettings, Bool>
    }
    
    private let indicators = [
        IndicatorItem(title: "湿度", keyPath: \WeatherIndicatorSettings.showHumidity),
        IndicatorItem(title: "风速", keyPath: \WeatherIndicatorSettings.showWindSpeed),
        IndicatorItem(title: "降水概率", keyPath: \WeatherIndicatorSettings.showPrecipitation),
        IndicatorItem(title: "紫外线", keyPath: \WeatherIndicatorSettings.showUVIndex),
        IndicatorItem(title: "气压", keyPath: \WeatherIndicatorSettings.showPressure),
        IndicatorItem(title: "能见度", keyPath: \WeatherIndicatorSettings.showVisibility)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("显示指标")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(indicators) { indicator in
                    Toggle(isOn: Binding(
                        get: { settings[keyPath: indicator.keyPath] },
                        set: { settings[keyPath: indicator.keyPath] = $0 }
                    )) {
                        Text(indicator.title)
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
    }
}

#Preview {
    ZStack {
        Color.gray
        WeatherIndicatorSettingsView()
            .padding()
    }
} 