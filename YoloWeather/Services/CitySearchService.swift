import Foundation
import CoreLocation
import MapKit

@MainActor
class CitySearchService: ObservableObject {
    static let shared = CitySearchService()
    
    @Published private(set) var recentSearches: [PresetLocation] = []
    private let maxRecentSearches = 5
    
    private init() {
        loadRecentSearches()
    }
    
    func searchCities(query: String) async -> [PresetLocation] {
        // 模拟网络延迟
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if cleanQuery.isEmpty {
            return []
        }
        
        print("搜索城市: \(cleanQuery)")
        
        let results = allCities.filter { city in
            let cityName = city.name.lowercased()
            return cityName.contains(cleanQuery)
        }
        
        print("找到 \(results.count) 个匹配城市")
        return results
    }
    
    func getHotCities() -> [PresetLocation] {
        Array(allCities.prefix(8))
    }
    
    func addToRecentSearches(_ location: PresetLocation) {
        // 如果已存在，先移除
        recentSearches.removeAll { $0.id == location.id }
        
        // 添加到最前面
        recentSearches.insert(location, at: 0)
        
        // 保持最大数量限制
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }
        
        saveRecentSearches()
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "RecentSearches"),
           let decoded = try? JSONDecoder().decode([PresetLocation].self, from: data) {
            recentSearches = decoded
        }
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: "RecentSearches")
        }
    }
    
    // 预设城市列表
    private let allCities: [PresetLocation] = [
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074)),
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "广州市", location: CLLocation(latitude: 23.1291, longitude: 113.2644)),
        PresetLocation(name: "深圳市", location: CLLocation(latitude: 22.5431, longitude: 114.0579)),
        PresetLocation(name: "成都市", location: CLLocation(latitude: 30.5728, longitude: 104.0668)),
        PresetLocation(name: "杭州市", location: CLLocation(latitude: 30.2741, longitude: 120.1551)),
        PresetLocation(name: "武汉市", location: CLLocation(latitude: 30.5928, longitude: 114.3055)),
        PresetLocation(name: "西安市", location: CLLocation(latitude: 34.3416, longitude: 108.9398)),
        PresetLocation(name: "重庆市", location: CLLocation(latitude: 29.4316, longitude: 106.9123)),
        PresetLocation(name: "南京市", location: CLLocation(latitude: 32.0603, longitude: 118.7969)),
        PresetLocation(name: "天津市", location: CLLocation(latitude: 39.0842, longitude: 117.2009)),
        PresetLocation(name: "苏州市", location: CLLocation(latitude: 31.2989, longitude: 120.5853)),
        PresetLocation(name: "厦门市", location: CLLocation(latitude: 24.4798, longitude: 118.0894)),
        PresetLocation(name: "青岛市", location: CLLocation(latitude: 36.0671, longitude: 120.3826)),
        PresetLocation(name: "大连市", location: CLLocation(latitude: 38.9140, longitude: 121.6147))
    ]
} 