import Foundation
import CoreLocation

class CitySearchService: ObservableObject {
    static let shared = CitySearchService()
    
    private init() {}
    
    // 模拟的城市数据库
    private let allCities: [PresetLocation] = [
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074)),
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
    
    func searchCities(query: String) -> [PresetLocation] {
        guard !query.isEmpty else { return [] }
        
        // 移除空格和特殊字符
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanQuery.isEmpty {
            return []
        }
        
        print("搜索城市: \(cleanQuery)")
        
        // 使用拼音和汉字进行模糊匹配
        let results = allCities.filter { city in
            let cityName = city.name
            return cityName.localizedStandardContains(cleanQuery)
        }
        
        print("找到 \(results.count) 个匹配城市: \(results.map { $0.name }.joined(separator: ", "))")
        return results
    }
    
    // 获取热门城市
    func getHotCities() -> [PresetLocation] {
        // 返回前8个城市作为热门城市
        return Array(allCities.prefix(8))
    }
    
    // 获取所有城市
    func getAllCities() -> [PresetLocation] {
        return allCities
    }
} 