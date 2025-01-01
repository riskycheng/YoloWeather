import Foundation
import SwiftUI

class WeatherTagManager: ObservableObject {
    static let shared = WeatherTagManager()
    
    @AppStorage("activeTags") private var activeTagsData: Data = Data()
    @Published private(set) var activeTags: Set<WeatherTag> = []
    @Published var isEditMode = false
    
    private init() {
        loadActiveTags()
    }
    
    private func loadActiveTags() {
        if let tags = try? JSONDecoder().decode(Set<WeatherTag>.self, from: activeTagsData) {
            activeTags = tags
        } else {
            // 默认显示的标签
            activeTags = [.feelsLike, .humidity, .windSpeed]
            saveActiveTags()
        }
    }
    
    private func saveActiveTags() {
        if let data = try? JSONEncoder().encode(activeTags) {
            activeTagsData = data
        }
    }
    
    func toggleTag(_ tag: WeatherTag) {
        if activeTags.contains(tag) {
            activeTags.remove(tag)
        } else {
            activeTags.insert(tag)
        }
        saveActiveTags()
    }
}
