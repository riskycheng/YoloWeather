import Foundation
import SwiftUI

struct WeatherBubbleItem: Identifiable, Codable {
    let id: String
    let title: String
    var isEnabled: Bool
    
    static let allItems: [WeatherBubbleItem] = [
        .init(id: "humidity", title: "湿度", isEnabled: true),
        .init(id: "windSpeed", title: "风速", isEnabled: true),
        .init(id: "precipitation", title: "降水概率", isEnabled: true),
        .init(id: "uvIndex", title: "紫外线", isEnabled: false),
        .init(id: "pressure", title: "气压", isEnabled: false),
        .init(id: "visibility", title: "能见度", isEnabled: false)
    ]
}

@MainActor
class WeatherBubbleSettings: ObservableObject {
    static let shared = WeatherBubbleSettings()
    
    @Published var enabledBubbles: Set<BubbleType> {
        didSet {
            saveSettings()
        }
    }
    
    enum BubbleType: String, CaseIterable, Codable {
        case humidity = "湿度"
        case windSpeed = "风速"
        case precipitation = "降水概率"
        case uvIndex = "紫外线"
        case pressure = "气压"
        case visibility = "能见度"
    }
    
    private init() {
        // 从 UserDefaults 加载保存的设置
        if let savedData = UserDefaults.standard.data(forKey: "EnabledWeatherBubbles"),
           let savedBubbles = try? JSONDecoder().decode(Set<BubbleType>.self, from: savedData) {
            self.enabledBubbles = savedBubbles
        } else {
            // 默认启用的指标
            self.enabledBubbles = [.humidity, .windSpeed, .pressure]
        }
    }
    
    func isEnabled(_ type: BubbleType) -> Bool {
        enabledBubbles.contains(type)
    }
    
    func toggleBubble(_ type: BubbleType) {
        if enabledBubbles.contains(type) {
            enabledBubbles.remove(type)
        } else {
            enabledBubbles.insert(type)
        }
    }
    
    func updateBubbleSettings(_ items: [WeatherBubbleItem]) {
        // Implementation needed
    }
    
    private func saveSettings() {
        if let encodedData = try? JSONEncoder().encode(enabledBubbles) {
            UserDefaults.standard.set(encodedData, forKey: "EnabledWeatherBubbles")
        }
    }
} 