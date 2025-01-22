import Foundation

@MainActor
class SettingsService: ObservableObject {
    static let shared = SettingsService()
    
    @Published var showWeeklyForecast: Bool {
        didSet {
            UserDefaults.standard.set(showWeeklyForecast, forKey: "showWeeklyForecast")
        }
    }
    
    private init() {
        // 从 UserDefaults 加载设置，默认显示周预报
        self.showWeeklyForecast = UserDefaults.standard.bool(forKey: "showWeeklyForecast", defaultValue: true)
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
            return defaultValue
        }
        return bool(forKey: key)
    }
} 