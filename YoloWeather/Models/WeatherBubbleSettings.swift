import Foundation

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
    
    @Published private(set) var bubbleItems: [WeatherBubbleItem]
    
    private init() {
        // 首先初始化属性
        self.bubbleItems = []
        
        // 然后加载保存的设置
        if let data = UserDefaults.standard.data(forKey: "WeatherBubbleSettings"),
           let savedItems = try? JSONDecoder().decode([WeatherBubbleItem].self, from: data) {
            self.bubbleItems = savedItems
        } else {
            self.bubbleItems = WeatherBubbleItem.allItems
        }
    }
    
    private func saveBubbleSettings() {
        if let encoded = try? JSONEncoder().encode(bubbleItems) {
            UserDefaults.standard.set(encoded, forKey: "WeatherBubbleSettings")
        }
    }
    
    func isEnabled(for id: String) -> Bool {
        bubbleItems.first(where: { $0.id == id })?.isEnabled ?? false
    }
    
    func toggleBubble(id: String) {
        if let index = bubbleItems.firstIndex(where: { $0.id == id }) {
            bubbleItems[index].isEnabled.toggle()
            saveBubbleSettings()
        }
    }
    
    func updateBubbleSettings(_ items: [WeatherBubbleItem]) {
        bubbleItems = items
        saveBubbleSettings()
    }
} 