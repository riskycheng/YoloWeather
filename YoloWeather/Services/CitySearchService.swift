import Foundation
import CoreLocation
import MapKit

@MainActor
class CitySearchService: ObservableObject {
    static let shared = CitySearchService()
    
    @Published private(set) var recentSearches: [PresetLocation] = []
    private let maxRecentSearches = 5
    
    private var cityPinyinMap: [String: [String]] = [:]
    private var searchTask: Task<Void, Never>?
    
    private init() {
        loadRecentSearches()
        initializePinyinMap()
    }
    
    private func initializePinyinMap() {
        // 手动设置城市拼音映射，包括完整拼音和首字母
        cityPinyinMap = [
            "北京市": ["beijing", "bj"],
            "上海市": ["shanghai", "sh"],
            "广州市": ["guangzhou", "gz"],
            "深圳市": ["shenzhen", "sz"],
            "成都市": ["chengdu", "cd"],
            "杭州市": ["hangzhou", "hz"],
            "武汉市": ["wuhan", "wh"],
            "西安市": ["xian", "xa"],
            "重庆市": ["chongqing", "cq"],
            "南京市": ["nanjing", "nj"],
            "天津市": ["tianjin", "tj"],
            "苏州市": ["suzhou", "sz"],
            "郑州市": ["zhengzhou", "zz"],
            "长沙市": ["changsha", "cs"],
            "扬州市": ["yangzhou", "yz"],
            "厦门市": ["xiamen", "xm"],
            "青岛市": ["qingdao", "qd"],
            "大连市": ["dalian", "dl"],
            "宁波市": ["ningbo", "nb"],
            "济南市": ["jinan", "jn"],
            "无锡市": ["wuxi", "wx"],
            "常州市": ["changzhou", "cz"],
            "徐州市": ["xuzhou", "xz"],
            "南通市": ["nantong", "nt"],
            "深圳市南山区": ["shenzhennanshanqu", "szns"],
            "深圳市福田区": ["shenzhenfutianqu", "szft"],
            "深圳市罗湖区": ["shenzhenluohuqu", "szlh"],
            "深圳市宝安区": ["shenzhenbaoanqu", "szba"],
            "深圳市龙岗区": ["shenzhenlonggangqu", "szlg"],
            "深圳宝安国际机场": ["shenzhenbaoanguojijichang", "szba"],
            "深圳世界之窗": ["shenzhenshijiezhichuang", "szsjzc"],
            "香港": ["xianggang", "xg", "hongkong", "hk"],
            "澳门": ["aomen", "am", "macao"],
            "东京": ["dongjing", "dj", "tokyo"],
            "新加坡": ["xinjiapo", "xjp", "singapore"],
            "首尔": ["shouer", "se", "seoul"],
            "曼谷": ["mangu", "mg", "bangkok"],
            "纽约": ["niuyue", "ny", "newyork"],
            "伦敦": ["lundun", "ld", "london"],
            "巴黎": ["bali", "bl", "paris"],
            "悉尼": ["xini", "xn", "sydney"]
        ]
    }
    
    func searchCities(query: String) async -> [PresetLocation] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanQuery.isEmpty {
            return []
        }
        
        print("搜索城市: \(cleanQuery)")
        
        // 1. 先搜索预设城市
        let presetResults = searchPresetCities(query: cleanQuery.lowercased())
        
        // 2. 如果预设城市没有结果，使用 MKLocalSearch
        if presetResults.isEmpty {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = cleanQuery
                request.resultTypes = .address
                
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                
                let onlineResults = response.mapItems.compactMap { item -> PresetLocation? in
                    guard let location = item.placemark.location else {
                        return nil
                    }
                    
                    // 优先使用最小的行政单位名称
                    let name = item.placemark.locality ?? // 城市名
                              item.placemark.subLocality ?? // 区县名
                              item.placemark.name ?? // 地点名
                              item.name ?? // 备选名称
                              ""
                    
                    // 如果没有获取到有效名称，跳过
                    if name.isEmpty {
                        return nil
                    }
                    
                    // 对于中国城市，直接使用城市名
                    if item.placemark.country == "China" || item.placemark.country == "中国" {
                        return PresetLocation(name: name, location: location)
                    }
                    
                    // 对于国外城市，添加国家名称
                    if let country = item.placemark.country {
                        return PresetLocation(name: "\(name), \(country)", location: location)
                    }
                    
                    return PresetLocation(name: name, location: location)
                }
                
                // 去重并限制结果数量
                var uniqueResults: [PresetLocation] = []
                let maxResults = 20
                
                for result in onlineResults {
                    if !uniqueResults.contains(where: { $0.name == result.name }) {
                        uniqueResults.append(result)
                        if uniqueResults.count >= maxResults {
                            break
                        }
                    }
                }
                
                print("找到 \(uniqueResults.count) 个在线匹配城市")
                return uniqueResults
            } catch {
                print("在线城市搜索出错: \(error.localizedDescription)")
                return []
            }
        }
        
        print("找到 \(presetResults.count) 个预设匹配城市")
        return presetResults
    }
    
    private func searchPresetCities(query: String) -> [PresetLocation] {
        // 1. 完全匹配（中文名或拼音）
        let exactMatches = allCities.filter { city in
            city.name.lowercased() == query ||
            cityPinyinMap[city.name]?.contains(query) == true
        }
        
        // 2. 前缀匹配（中文名或拼音）
        let prefixMatches = allCities.filter { city in
            if exactMatches.contains(where: { $0.id == city.id }) {
                return false
            }
            
            let pinyinMatches = cityPinyinMap[city.name]?.contains { pinyin in
                pinyin.hasPrefix(query)
            } ?? false
            
            return city.name.lowercased().hasPrefix(query) || pinyinMatches
        }
        
        // 3. 包含匹配（中文名或拼音）
        let containsMatches = allCities.filter { city in
            if exactMatches.contains(where: { $0.id == city.id }) ||
               prefixMatches.contains(where: { $0.id == city.id }) {
                return false
            }
            
            let pinyinMatches = cityPinyinMap[city.name]?.contains { pinyin in
                pinyin.contains(query)
            } ?? false
            
            return city.name.lowercased().contains(query) || pinyinMatches
        }
        
        // 组合结果
        return exactMatches + prefixMatches + containsMatches
    }
    
    func getHotCities() -> [PresetLocation] {
        Array(allCities.prefix(8))
    }
    
    func addToRecentSearches(_ location: PresetLocation) {
        recentSearches.removeAll { $0.id == location.id }
        recentSearches.insert(location, at: 0)
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
        // 一线城市
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074)),
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "广州市", location: CLLocation(latitude: 23.1291, longitude: 113.2644)),
        PresetLocation(name: "深圳市", location: CLLocation(latitude: 22.5431, longitude: 114.0579)),
        
        // 新一线城市
        PresetLocation(name: "成都市", location: CLLocation(latitude: 30.5728, longitude: 104.0668)),
        PresetLocation(name: "杭州市", location: CLLocation(latitude: 30.2741, longitude: 120.1551)),
        PresetLocation(name: "武汉市", location: CLLocation(latitude: 30.5928, longitude: 114.3055)),
        PresetLocation(name: "西安市", location: CLLocation(latitude: 34.3416, longitude: 108.9398)),
        PresetLocation(name: "重庆市", location: CLLocation(latitude: 29.4316, longitude: 106.9123)),
        PresetLocation(name: "南京市", location: CLLocation(latitude: 32.0603, longitude: 118.7969)),
        PresetLocation(name: "天津市", location: CLLocation(latitude: 39.0842, longitude: 117.2009)),
        PresetLocation(name: "苏州市", location: CLLocation(latitude: 31.2989, longitude: 120.5853)),
        PresetLocation(name: "郑州市", location: CLLocation(latitude: 34.7472, longitude: 113.6249)),
        PresetLocation(name: "长沙市", location: CLLocation(latitude: 28.2278, longitude: 112.9388)),
        
        // 二线城市
        PresetLocation(name: "厦门市", location: CLLocation(latitude: 24.4798, longitude: 118.0894)),
        PresetLocation(name: "青岛市", location: CLLocation(latitude: 36.0671, longitude: 120.3826)),
        PresetLocation(name: "大连市", location: CLLocation(latitude: 38.9140, longitude: 121.6147)),
        PresetLocation(name: "宁波市", location: CLLocation(latitude: 29.8683, longitude: 121.5440)),
        PresetLocation(name: "济南市", location: CLLocation(latitude: 36.6512, longitude: 117.1201)),
        
        // 深圳各区
        PresetLocation(name: "深圳市南山区", location: CLLocation(latitude: 22.5329, longitude: 113.9305)),
        PresetLocation(name: "深圳市福田区", location: CLLocation(latitude: 22.5410, longitude: 114.0530)),
        PresetLocation(name: "深圳市罗湖区", location: CLLocation(latitude: 22.5554, longitude: 114.1317)),
        PresetLocation(name: "深圳市宝安区", location: CLLocation(latitude: 22.5551, longitude: 113.8843)),
        PresetLocation(name: "深圳市龙岗区", location: CLLocation(latitude: 22.7204, longitude: 114.2466)),
        
        // 地标建筑
        PresetLocation(name: "深圳宝安国际机场", location: CLLocation(latitude: 22.6395, longitude: 113.8145)),
        PresetLocation(name: "深圳世界之窗", location: CLLocation(latitude: 22.5348, longitude: 113.9742)),
        
        // 国际城市
        PresetLocation(name: "香港", location: CLLocation(latitude: 22.3193, longitude: 114.1694)),
        PresetLocation(name: "澳门", location: CLLocation(latitude: 22.1987, longitude: 113.5439)),
        PresetLocation(name: "东京", location: CLLocation(latitude: 35.6762, longitude: 139.6503)),
        PresetLocation(name: "新加坡", location: CLLocation(latitude: 1.3521, longitude: 103.8198)),
        PresetLocation(name: "首尔", location: CLLocation(latitude: 37.5665, longitude: 126.9780)),
        PresetLocation(name: "曼谷", location: CLLocation(latitude: 13.7563, longitude: 100.5018)),
        PresetLocation(name: "纽约", location: CLLocation(latitude: 40.7128, longitude: -74.0060)),
        PresetLocation(name: "伦敦", location: CLLocation(latitude: 51.5074, longitude: -0.1278)),
        PresetLocation(name: "巴黎", location: CLLocation(latitude: 48.8566, longitude: 2.3522)),
        PresetLocation(name: "悉尼", location: CLLocation(latitude: -33.8688, longitude: 151.2093))
    ]
} 