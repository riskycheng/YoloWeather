import SwiftUI
import WeatherKit

struct WeatherMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isEnabled: Bool = true
}

struct WeatherMetricsView: View {
    let weather: CurrentWeather
    let timeOfDay: WeatherTimeOfDay
    
    // 使用字符串存储启用的指标列表
    @AppStorage("enabledMetrics") private var enabledMetricsString: String = "wind,uv,humidity"
    
    private var enabledMetrics: Set<String> {
        Set(enabledMetricsString.split(separator: ",").map(String.init))
    }
    
    private var metrics: [WeatherMetric] {
        [
            WeatherMetric(
                title: "风速",
                value: "\(Int(round(weather.windSpeed)))km/h",
                icon: "wind",
                color: .blue,
                isEnabled: enabledMetrics.contains("wind")
            ),
            WeatherMetric(
                title: "紫外线",
                value: uvIndexDescription(weather.uvIndex),
                icon: "sun.max.fill",
                color: .orange,
                isEnabled: enabledMetrics.contains("uv")
            ),
            WeatherMetric(
                title: "湿度",
                value: "\(Int(round(weather.humidity * 100)))%",
                icon: "humidity",
                color: .blue,
                isEnabled: enabledMetrics.contains("humidity")
            )
        ].filter { $0.isEnabled }
    }
    
    private func uvIndexDescription(_ index: Int) -> String {
        switch index {
        case 0...2: return "低"
        case 3...5: return "中等"
        case 6...7: return "高"
        case 8...: return "极高"
        default: return "未知"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(metrics) { metric in
                VStack(spacing: 8) {
                    Text(metric.title)
                        .font(.system(.headline, design: .rounded))
                    
                    Image(systemName: metric.icon)
                        .font(.title2)
                        .foregroundStyle(metric.color)
                    
                    Text(metric.value)
                        .font(.system(.title3, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
            }
        }
        .padding(.horizontal)
    }
}

// 添加一个扩展来管理指标设置
extension WeatherMetricsView {
    static func updateEnabledMetrics(_ metrics: Set<String>) {
        let metricsString = metrics.joined(separator: ",")
        UserDefaults.standard.set(metricsString, forKey: "enabledMetrics")
    }
}
