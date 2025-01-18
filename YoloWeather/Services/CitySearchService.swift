import Foundation
import CoreLocation
import MapKit

@MainActor
class CitySearchService: ObservableObject {
    static let shared = CitySearchService()
    
    @Published var recentSearches: [PresetLocation] = []
    private let maxRecentSearches = 5
    
    private var cityPinyinMap: [String: [String]] = [:]
    private var searchTask: Task<Void, Never>?
    
    @Published private(set) var searchResults: [PresetLocation] = []
    
    private init() {
        loadRecentSearches()
        initializePinyinMap()
    }
    
    private func initializePinyinMap() {
        // 手动设置城市拼音映射，包括完整拼音、首字母和常见的模糊搜索词
        cityPinyinMap = [
            "北京市": ["beijing", "bj", "bei", "jing"],
            "上海市": ["shanghai", "sh", "shang", "hai"],
            "广州市": ["guangzhou", "gz", "guang", "zhou"],
            "深圳市": ["shenzhen", "sz", "shen", "zhen"],
            "成都市": ["chengdu", "cd", "cheng", "du"],
            "杭州市": ["hangzhou", "hz", "hang", "zhou"],
            "武汉市": ["wuhan", "wh", "wu", "han"],
            "西安市": ["xian", "xa", "xi", "an"],
            "重庆市": ["chongqing", "cq", "chong", "qing"],
            "南京市": ["nanjing", "nj", "nan", "jing"],
            "天津市": ["tianjin", "tj", "tian", "jin"],
            "苏州市": ["suzhou", "sz", "su", "zhou"],
            "郑州市": ["zhengzhou", "zz", "zheng", "zhou"],
            "长沙市": ["changsha", "cs", "chang", "sha"],
            "扬州市": ["yangzhou", "yz", "yang", "zhou"],
            "厦门市": ["xiamen", "xm", "xia", "men"],
            "青岛市": ["qingdao", "qd", "qing", "dao"],
            "大连市": ["dalian", "dl", "da", "lian"],
            "宁波市": ["ningbo", "nb", "ning", "bo"],
            "济南市": ["jinan", "jn", "ji", "nan"],
            "临沂市": ["linyi", "ly", "lin", "yi"],
            "临汾市": ["linfen", "lf", "lin", "fen"],
            "临海市": ["linhai", "lh", "lin", "hai"],
            "香港": ["xianggang", "xg", "hongkong", "hk", "xiang", "gang"],
            "澳门": ["aomen", "am", "macao", "ao", "men"],
            "台北": ["taipei", "tb", "tai", "bei"],
            "高雄": ["gaoxiong", "gx", "gao", "xiong"],
            "东京": ["dongjing", "dj", "tokyo", "dong", "jing"],
            "大阪": ["daban", "db", "osaka", "da", "ban"],
            "首尔": ["shouer", "se", "seoul", "shou", "er"],
            "新加坡": ["xinjiapo", "xjp", "singapore", "xin", "jia", "po"],
            "纽约": ["niuyue", "ny", "newyork", "niu", "yue"],
            "伦敦": ["lundun", "ld", "london", "lun", "dun"],
            "巴黎": ["bali", "bl", "paris", "ba", "li"],
            "柏林": ["bolin", "bl", "berlin", "bo", "lin"],
            "悉尼": ["xini", "xn", "sydney", "xi", "ni"],
            "墨尔本": ["moerben", "meb", "melbourne", "mo", "er", "ben"]
        ]
    }
    
    func searchCities(query: String) async -> [PresetLocation] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("搜索城市: \(cleanQuery)")
        
        if cleanQuery.isEmpty {
            return getHotCities()
        }
        
        var results = Set<PresetLocation>()
        
        // 1. 搜索预设城市
        let presetResults = searchPresetCities(query: cleanQuery)
        results.formUnion(presetResults)
        print("预设城市搜索结果数量: \(presetResults.count)")
        
        // 2. 使用在线搜索补充结果
        do {
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            searchRequest.resultTypes = .address
            
            let search = MKLocalSearch(request: searchRequest)
            let response = try await search.start()
            
            let onlineResults = response.mapItems.compactMap { item -> PresetLocation? in
                // 获取最精确的地名
                let placemark = item.placemark
                
                // 优先使用最具体的地名
                let name: String? = {
                    // 1. 如果有具体的地点名称，优先使用
                    if let specificName = placemark.name {
                        return specificName
                    }
                    
                    // 2. 其次使用区县级名称
                    if let subLocality = placemark.subLocality {
                        return subLocality
                    }
                    
                    // 3. 最后使用城市名称
                    return placemark.locality
                }()
                
                guard let locationName = name,
                      let location = placemark.location else {
                    return nil
                }
                
                // 对于中国城市，直接使用地名
                if placemark.countryCode == "CN" {
                    // 如果地名不包含"市"、"区"、"县"等后缀，添加适当的后缀
                    let suffixes = ["市", "区", "县", "自治州", "自治区"]
                    if !suffixes.contains(where: { locationName.hasSuffix($0) }) {
                        if locationName.count >= 2 {
                            return PresetLocation(name: locationName + "市", location: location)
                        }
                    }
                    return PresetLocation(name: locationName, location: location)
                }
                
                // 对于国外城市，添加国家名称
                if let country = placemark.country {
                    return PresetLocation(name: "\(locationName), \(country)", location: location)
                }
                
                return PresetLocation(name: locationName, location: location)
            }
            
            results.formUnion(onlineResults)
            print("在线搜索结果数量: \(onlineResults.count)")
        } catch {
            print("在线城市搜索出错: \(error.localizedDescription)")
        }
        
        // 排序并限制结果数量
        let finalResults = Array(results)
            .sorted { lhs, rhs in
                // 1. 优先显示以搜索词开头的结果
                let lhsStartsWith = lhs.name.lowercased().hasPrefix(cleanQuery)
                let rhsStartsWith = rhs.name.lowercased().hasPrefix(cleanQuery)
                if lhsStartsWith != rhsStartsWith {
                    return lhsStartsWith
                }
                
                // 2. 其次按名称长度排序
                return lhs.name.count < rhs.name.count
            }
            .prefix(20)
        
        print("最终结果数量: \(finalResults.count)")
        return Array(finalResults)
    }
    
    private func searchPresetCities(query: String) -> [PresetLocation] {
        let cleanQuery = query.lowercased()
        var matchedCities = Set<PresetLocation>()
        
        // 1. 在线搜索补充的城市
        let onlineCities = [
            PresetLocation(name: "临沂市", location: CLLocation(latitude: 35.1045, longitude: 118.3564)),
            PresetLocation(name: "临汾市", location: CLLocation(latitude: 36.0880, longitude: 111.5190)),
            PresetLocation(name: "临海市", location: CLLocation(latitude: 28.8584, longitude: 121.1447)),
            PresetLocation(name: "临安区", location: CLLocation(latitude: 30.2345, longitude: 119.7245)),
            PresetLocation(name: "临平区", location: CLLocation(latitude: 30.4191, longitude: 120.3012)),
            PresetLocation(name: "临沧市", location: CLLocation(latitude: 23.8864, longitude: 100.0927))
        ]
        
        let searchCities = allCities + onlineCities
        
        for location in searchCities {
            let cityName = location.name.lowercased()
            let pinyinList = cityPinyinMap[location.name] ?? []
            
            // 1. 精确匹配（中文或拼音）
            if cityName == cleanQuery || pinyinList.contains(cleanQuery) {
                matchedCities.insert(location)
                continue
            }
            
            // 2. 前缀匹配（中文或拼音）
            if cityName.hasPrefix(cleanQuery) || pinyinList.contains(where: { $0.hasPrefix(cleanQuery) }) {
                matchedCities.insert(location)
                continue
            }
            
            // 3. 模糊匹配（中文或拼音）
            if cityName.contains(cleanQuery) || pinyinList.contains(where: { $0.contains(cleanQuery) }) {
                matchedCities.insert(location)
                continue
            }
            
            // 4. 分词匹配（支持多音字和常见变体）
            let queryParts = cleanQuery.split(separator: " ")
            if queryParts.count > 1 {
                let allMatch = queryParts.allSatisfy { part in
                    let partString = String(part)
                    return cityName.contains(partString) ||
                           pinyinList.contains(where: { $0.contains(partString) })
                }
                if allMatch {
                    matchedCities.insert(location)
                }
            }
            
            // 5. 单字符匹配（对于输入单个汉字的情况）
            if cleanQuery.count == 1 && cityName.contains(cleanQuery) {
                matchedCities.insert(location)
            }
        }
        
        return Array(matchedCities)
    }
    
    func getHotCities() -> [PresetLocation] {
        return Array(allCities.prefix(8))  // 使用 allCities 而不是 presets
    }
    
    func addToRecentSearches(_ location: PresetLocation) {
        if !recentSearches.contains(where: { $0.name == location.name }) {
            recentSearches.insert(location, at: 0)
            saveRecentSearches()
        }
    }
    
    func removeFromRecentSearches(_ location: PresetLocation) {
        recentSearches.removeAll(where: { $0.name == location.name })
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(encoded, forKey: "recentSearches")
        }
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: "recentSearches"),
           let decoded = try? JSONDecoder().decode([PresetLocation].self, from: data) {
            recentSearches = decoded
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