import Foundation
import SwiftUI

@MainActor
class WeatherTagManager: ObservableObject {
    static let shared = WeatherTagManager()
    
    @Published var activeTags: [WeatherTag] = [.temperature, .humidity, .windSpeed]
    @Published var isEditMode = false
    
    private let defaults = UserDefaults.standard
    private let activeTagsKey = "ActiveWeatherTags"
    
    private init() {
        if let savedTags = defaults.stringArray(forKey: activeTagsKey) {
            activeTags = savedTags.compactMap { WeatherTag(rawValue: $0) }
        }
    }
    
    func toggleTag(_ tag: WeatherTag) {
        if activeTags.contains(tag) {
            activeTags.removeAll { $0 == tag }
        } else {
            activeTags.append(tag)
        }
        saveTags()
    }
    
    private func saveTags() {
        let tagStrings = activeTags.map { $0.rawValue }
        defaults.set(tagStrings, forKey: activeTagsKey)
    }
    
    func resetToDefaults() {
        activeTags = [.temperature, .humidity, .windSpeed]
        saveTags()
    }
}
