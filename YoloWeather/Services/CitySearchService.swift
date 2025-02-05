import Foundation
import CoreLocation
import MapKit

@MainActor
class CitySearchService: ObservableObject {
    static let shared = CitySearchService()
    
    @Published var recentSearches: [PresetLocation] = []
    // Maximum number of cities that can be saved in the favorites list
    // Increased from 5 to 20 to allow for more recent searches to be stored
    private let maxRecentSearches = 20
    
    private var cityPinyinMap: [String: [String]] = [:]
    private var searchTask: Task<Void, Never>?
    
    @Published private(set) var searchResults: [PresetLocation] = []
    
    private init() {
        loadRecentSearches()
        initializePinyinMap()
    }
    
    private func initializePinyinMap() {
        // 手动设置城市拼音映射，包括完整拼音、首字母、行政区划、方言和别名
        cityPinyinMap = [
            // 华北地区
            "北京市": ["beijing", "bj", "bei", "jing", "帝都", "首都"],
            "天津市": ["tianjin", "tj", "tian", "jin", "津门", "津沽"],
            "石家庄市": ["shijiazhuang", "sjz", "shi", "jia", "zhuang", "河北石家庄"],
            "太原市": ["taiyuan", "ty", "tai", "yuan", "山西太原"],
            "呼和浩特市": ["huhehaote", "hhht", "hu", "he", "hao", "te", "内蒙古呼和浩特"],
            
            // 东北地区
            "沈阳市": ["shenyang", "sy", "shen", "yang", "辽宁沈阳", "盛京"],
            "长春市": ["changchun", "cc", "chang", "chun", "吉林长春"],
            "哈尔滨市": ["haerbin", "heb", "ha", "er", "bin", "黑龙江哈尔滨", "冰城"],
            "大连市": ["dalian", "dl", "da", "lian", "辽宁大连", "滨城"],
            
            // 华东地区
            "上海市": ["shanghai", "sh", "shang", "hai", "魔都", "申城"],
            "南京市": ["nanjing", "nj", "nan", "jing", "江苏南京", "金陵"],
            "杭州市": ["hangzhou", "hz", "hang", "zhou", "浙江杭州", "杭城"],
            "济南市": ["jinan", "jn", "ji", "nan", "山东济南", "泉城"],
            "青岛市": ["qingdao", "qd", "qing", "dao", "山东青岛", "琴岛"],
            "厦门市": ["xiamen", "xm", "xia", "men", "福建厦门", "鹭岛"],
            "福州市": ["fuzhou", "fz", "fu", "zhou", "福建福州", "榕城"],
            "合肥市": ["hefei", "hf", "he", "fei", "安徽合肥"],
            "南昌市": ["nanchang", "nc", "nan", "chang", "江西南昌"],
            "苏州市": ["suzhou", "sz", "su", "zhou", "江苏苏州", "姑苏"],
            "宁波市": ["ningbo", "nb", "ning", "bo", "浙江宁波"],
            "无锡市": ["wuxi", "wx", "wu", "xi", "江苏无锡"],
            
            // 中南地区
            "广州市": ["guangzhou", "gz", "guang", "zhou", "广东广州", "羊城"],
            "深圳市": ["shenzhen", "sz", "shen", "zhen", "广东深圳", "鹏城"],
            "武汉市": ["wuhan", "wh", "wu", "han", "湖北武汉", "江城"],
            "长沙市": ["changsha", "cs", "chang", "sha", "湖南长沙", "星城"],
            "南宁市": ["nanning", "nn", "nan", "ning", "广西南宁", "绿城"],
            "海口市": ["haikou", "hk", "hai", "kou", "海南海口", "椰城"],
            "郑州市": ["zhengzhou", "zz", "zheng", "zhou", "河南郑州", "商都"],
            
            // 西南地区
            "重庆市": ["chongqing", "cq", "chong", "qing", "山城", "渝都"],
            "成都市": ["chengdu", "cd", "cheng", "du", "四川成都", "蓉城"],
            "贵阳市": ["guiyang", "gy", "gui", "yang", "贵州贵阳", "林城"],
            "昆明市": ["kunming", "km", "kun", "ming", "云南昆明", "春城"],
            "拉萨市": ["lasa", "ls", "la", "sa", "西藏拉萨"],
            
            // 西北地区
            "西安市": ["xian", "xa", "xi", "an", "陕西西安", "古都"],
            "兰州市": ["lanzhou", "lz", "lan", "zhou", "甘肃兰州"],
            "西宁市": ["xining", "xn", "xi", "ning", "青海西宁"],
            "银川市": ["yinchuan", "yc", "yin", "chuan", "宁夏银川"],
            "乌鲁木齐市": ["wulumuqi", "wlmq", "wu", "lu", "mu", "qi", "新疆乌鲁木齐"],
            "阿勒泰地区": ["aletai", "alt", "a", "le", "tai", "新疆阿勒泰"],
            "喀什地区": ["kashi", "ks", "ka", "shi", "新疆喀什"],
            "伊犁哈萨克自治州": ["yili", "yl", "yi", "li", "新疆伊犁"],
            "吐鲁番市": ["tulufan", "tlf", "tu", "lu", "fan", "新疆吐鲁番"],
            "克拉玛依市": ["kelamayi", "klmy", "ke", "la", "ma", "yi", "新疆克拉玛依"],
            "哈密市": ["hami", "hm", "ha", "mi", "新疆哈密"],
            
            // 特别行政区
            "香港": ["xianggang", "xg", "hongkong", "hk", "xiang", "gang"],
            "澳门": ["aomen", "am", "macao", "mo", "ao", "men"],
            
            // 国际城市
            "东京": ["dongjing", "dj", "tokyo", "dong", "jing"],
            "首尔": ["shouer", "se", "seoul", "shou", "er"],
            "新加坡": ["xinjiapo", "xjp", "singapore", "xin", "jia", "po"],
            "曼谷": ["mangu", "mg", "bangkok", "man", "gu"],
            "吉隆坡": ["jilongpo", "jlp", "kualalumpur", "ji", "long", "po"],
            "纽约": ["niuyue", "ny", "newyork", "niu", "yue"],
            "伦敦": ["lundun", "ld", "london", "lun", "dun"],
            "巴黎": ["bali", "bl", "paris", "ba", "li"],
            "柏林": ["bolin", "bl", "berlin", "bo", "lin"],
            "莫斯科": ["mosike", "msk", "moscow", "mo", "si", "ke"],
            "悉尼": ["xini", "xn", "sydney", "xi", "ni"],
            "墨尔本": ["moerben", "meb", "melbourne", "mo", "er", "ben"],
            "迪拜": ["dibai", "db", "dubai", "di", "bai"],
            "温哥华": ["wengehua", "wgh", "vancouver", "wen", "ge", "hua"],
            "多伦多": ["duolunduo", "dld", "toronto", "duo", "lun", "duo"]
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
        print("CitySearchService - 添加城市到最近搜索: \(location.name)")
        print("CitySearchService - 传入的坐标: 纬度 \(location.location.coordinate.latitude), 经度 \(location.location.coordinate.longitude)")
        
        // 如果是预设城市，使用预设的坐标
        if let presetLocation = allCities.first(where: { $0.name == location.name }) {
            print("CitySearchService - 找到预设城市，使用预设坐标")
            let updatedLocation = PresetLocation(
                name: location.name,
                location: presetLocation.location,
                currentTemperature: location.currentTemperature
            )
            
            // 如果已经存在，先移除
            recentSearches.removeAll { $0.name == location.name }
            
            // 添加到最前面
            recentSearches.insert(updatedLocation, at: 0)
            
            // 限制数量
            if recentSearches.count > maxRecentSearches {
                recentSearches.removeLast()
            }
            
            // 保存到本地
            saveRecentSearches()
            
            print("CitySearchService - 更新后的坐标: 纬度 \(updatedLocation.location.coordinate.latitude), 经度 \(updatedLocation.location.coordinate.longitude)")
        } else {
            print("CitySearchService - 非预设城市，使用传入的坐标")
            // 如果已经存在，先移除
            recentSearches.removeAll { $0.name == location.name }
            
            // 添加到最前面
            recentSearches.insert(location, at: 0)
            
            // 限制数量
            if recentSearches.count > maxRecentSearches {
                recentSearches.removeLast()
            }
            
            // 保存到本地
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
    let allCities: [PresetLocation] = [
        // 华北地区
        PresetLocation(name: "北京市", location: CLLocation(latitude: 39.9042, longitude: 116.4074)),
        PresetLocation(name: "天津市", location: CLLocation(latitude: 39.0842, longitude: 117.2009)),
        PresetLocation(name: "石家庄市", location: CLLocation(latitude: 38.0428, longitude: 114.5149)),
        PresetLocation(name: "太原市", location: CLLocation(latitude: 37.8706, longitude: 112.5489)),
        PresetLocation(name: "呼和浩特市", location: CLLocation(latitude: 40.8427, longitude: 111.7498)),

        // 东北地区
        PresetLocation(name: "沈阳市", location: CLLocation(latitude: 41.8057, longitude: 123.4315)),
        PresetLocation(name: "长春市", location: CLLocation(latitude: 43.8168, longitude: 125.3240)),
        PresetLocation(name: "哈尔滨市", location: CLLocation(latitude: 45.8038, longitude: 126.5340)),
        PresetLocation(name: "大连市", location: CLLocation(latitude: 38.9140, longitude: 121.6147)),

        // 华东地区
        PresetLocation(name: "上海市", location: CLLocation(latitude: 31.2304, longitude: 121.4737)),
        PresetLocation(name: "南京市", location: CLLocation(latitude: 32.0603, longitude: 118.7969)),
        PresetLocation(name: "杭州市", location: CLLocation(latitude: 30.2741, longitude: 120.1551)),
        PresetLocation(name: "济南市", location: CLLocation(latitude: 36.6512, longitude: 117.1201)),
        PresetLocation(name: "青岛市", location: CLLocation(latitude: 36.0671, longitude: 120.3826)),
        PresetLocation(name: "厦门市", location: CLLocation(latitude: 24.4798, longitude: 118.0894)),
        PresetLocation(name: "福州市", location: CLLocation(latitude: 26.0745, longitude: 119.2965)),
        PresetLocation(name: "合肥市", location: CLLocation(latitude: 31.8206, longitude: 117.2272)),
        PresetLocation(name: "南昌市", location: CLLocation(latitude: 28.6820, longitude: 115.8579)),
        PresetLocation(name: "苏州市", location: CLLocation(latitude: 31.2989, longitude: 120.5853)),
        PresetLocation(name: "宁波市", location: CLLocation(latitude: 29.8683, longitude: 121.5440)),
        PresetLocation(name: "无锡市", location: CLLocation(latitude: 31.4900, longitude: 120.3117)),

        // 中南地区
        PresetLocation(name: "广州市", location: CLLocation(latitude: 23.1291, longitude: 113.2644)),
        PresetLocation(name: "深圳市", location: CLLocation(latitude: 22.5431, longitude: 114.0579)),
        PresetLocation(name: "武汉市", location: CLLocation(latitude: 30.5928, longitude: 114.3055)),
        PresetLocation(name: "长沙市", location: CLLocation(latitude: 28.2278, longitude: 112.9388)),
        PresetLocation(name: "南宁市", location: CLLocation(latitude: 22.8170, longitude: 108.3665)),
        PresetLocation(name: "海口市", location: CLLocation(latitude: 20.0440, longitude: 110.1920)),
        PresetLocation(name: "郑州市", location: CLLocation(latitude: 34.7472, longitude: 113.6249)),

        // 西南地区
        PresetLocation(name: "重庆市", location: CLLocation(latitude: 29.4316, longitude: 106.9123)),
        PresetLocation(name: "成都市", location: CLLocation(latitude: 30.5728, longitude: 104.0668)),
        PresetLocation(name: "贵阳市", location: CLLocation(latitude: 26.6470, longitude: 106.6302)),
        PresetLocation(name: "昆明市", location: CLLocation(latitude: 24.8801, longitude: 102.8329)),
        PresetLocation(name: "拉萨市", location: CLLocation(latitude: 29.6500, longitude: 91.1409)),

        // 西北地区
        PresetLocation(name: "西安市", location: CLLocation(latitude: 34.3416, longitude: 108.9398)),
        PresetLocation(name: "兰州市", location: CLLocation(latitude: 36.0611, longitude: 103.8343)),
        PresetLocation(name: "西宁市", location: CLLocation(latitude: 36.6232, longitude: 101.7804)),
        PresetLocation(name: "银川市", location: CLLocation(latitude: 38.4872, longitude: 106.2309)),
        PresetLocation(name: "乌鲁木齐市", location: CLLocation(latitude: 43.8256, longitude: 87.6168)),
        PresetLocation(name: "阿勒泰地区", location: CLLocation(latitude: 47.8, longitude: 88.1)),
        PresetLocation(name: "喀什地区", location: CLLocation(latitude: 39.4707, longitude: 75.9897)),
        PresetLocation(name: "伊犁哈萨克自治州", location: CLLocation(latitude: 43.9219, longitude: 81.3179)),
        PresetLocation(name: "吐鲁番市", location: CLLocation(latitude: 42.9513, longitude: 89.1895)),
        PresetLocation(name: "克拉玛依市", location: CLLocation(latitude: 45.5809, longitude: 84.8891)),
        PresetLocation(name: "哈密市", location: CLLocation(latitude: 42.8330, longitude: 93.5151)),

        // 特别行政区
        PresetLocation(name: "香港", location: CLLocation(latitude: 22.3193, longitude: 114.1694)),
        PresetLocation(name: "澳门", location: CLLocation(latitude: 22.1987, longitude: 113.5439)),

        // 国际城市
        PresetLocation(name: "东京", location: CLLocation(latitude: 35.6762, longitude: 139.6503)),
        PresetLocation(name: "首尔", location: CLLocation(latitude: 37.5665, longitude: 126.9780)),
        PresetLocation(name: "新加坡", location: CLLocation(latitude: 1.3521, longitude: 103.8198)),
        PresetLocation(name: "曼谷", location: CLLocation(latitude: 13.7563, longitude: 100.5018)),
        PresetLocation(name: "吉隆坡", location: CLLocation(latitude: 3.1390, longitude: 101.6869)),
        PresetLocation(name: "纽约", location: CLLocation(latitude: 40.7128, longitude: -74.0060)),
        PresetLocation(name: "伦敦", location: CLLocation(latitude: 51.5074, longitude: -0.1278)),
        PresetLocation(name: "巴黎", location: CLLocation(latitude: 48.8566, longitude: 2.3522)),
        PresetLocation(name: "柏林", location: CLLocation(latitude: 52.5200, longitude: 13.4050)),
        PresetLocation(name: "莫斯科", location: CLLocation(latitude: 55.7558, longitude: 37.6173)),
        PresetLocation(name: "悉尼", location: CLLocation(latitude: -33.8688, longitude: 151.2093)),
        PresetLocation(name: "墨尔本", location: CLLocation(latitude: -37.8136, longitude: 144.9631)),
        PresetLocation(name: "迪拜", location: CLLocation(latitude: 25.2048, longitude: 55.2708)),
        PresetLocation(name: "温哥华", location: CLLocation(latitude: 49.2827, longitude: -123.1207)),
        PresetLocation(name: "多伦多", location: CLLocation(latitude: 43.6532, longitude: -79.3832))
    ]
} 